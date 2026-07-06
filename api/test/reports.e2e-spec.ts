import { randomUUID } from 'node:crypto';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import sharp from 'sharp';
import { AppModule } from './../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { UPLOADS_DIR } from '../src/reports/photo-pipeline.service';

interface AuthResponse {
  token: string;
  user: { id: string; nickname: string };
}

interface ReportResponse {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  category: string;
  description: string | null;
  photoUrl: string | null;
  status: string;
  confirmCount: number;
  fixedCount: number;
  stillThereCount: number;
  complaintCount: number;
  province: { name: string; slug: string } | null;
}

// Kızılay, Ankara — falls inside province #6 per seed sanity check
const ANKARA = { lat: 39.9208, lng: 32.8541 };
// Sultanahmet, İstanbul — a different province, far from ANKARA
const ISTANBUL = { lat: 41.0055, lng: 28.9769 };

describe('Reports (e2e)', () => {
  let app: NestExpressApplication;
  // Both POST /auth/anonymous (10/min by IP) and POST /reports (5/min per
  // device) are intentionally rate-limited anti-abuse throttles. A handful
  // of pre-minted devices are reused across tests, spreading POST /reports
  // calls so no single device exceeds 5, while keeping total registrations
  // well under 10.
  let userA: string;
  let userB: string;
  let userC: string;
  let userD: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication<NestExpressApplication>();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useStaticAssets(UPLOADS_DIR, { prefix: '/uploads' });
    await app.init();

    // This suite asserts on the 50m/24h duplicate check, so leftover rows
    // from a previous run at the same fixed coordinates would false-positive.
    const prisma = moduleFixture.get(PrismaService);
    await prisma.$executeRawUnsafe('TRUNCATE TABLE votes, reports CASCADE');

    userA = (await authAs()).token;
    userB = (await authAs()).token;
    userC = (await authAs()).token;
    userD = (await authAs()).token;
  });

  afterAll(async () => {
    await app.close();
  });

  async function authAs(): Promise<{ token: string; userId: string }> {
    const res = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId: randomUUID() })
      .expect(200);
    const body = res.body as AuthResponse;
    return { token: body.token, userId: body.user.id };
  }

  it('POST /reports requires auth', () =>
    request(app.getHttpServer())
      .post('/reports')
      .field('lat', ANKARA.lat)
      .field('lng', ANKARA.lng)
      .field('severity', 2)
      .expect(401));

  it('creates a report without a photo and resolves its province', async () => {
    const res = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userA}`)
      .field('lat', ANKARA.lat)
      .field('lng', ANKARA.lng)
      .field('severity', 3)
      .field('category', 'cukur')
      .field('description', 'Test çukuru')
      .expect(201);
    const body = res.body as ReportResponse;
    expect(body.id).toBeDefined();
    expect(body.status).toBe('active');
    expect(body.photoUrl).toBeNull();
    expect(body.province?.slug).toBe('ankara');
  });

  it('rejects invalid severity and malformed coordinates', async () => {
    await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userA}`)
      .field('lat', ANKARA.lat)
      .field('lng', ANKARA.lng)
      .field('severity', 9)
      .expect(400);
    await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userA}`)
      .field('lat', 999)
      .field('lng', ANKARA.lng)
      .field('severity', 1)
      .expect(400);
  });

  it('rejects a duplicate report within 50m/24h with 409 + nearbyReportId', async () => {
    const first = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userB}`)
      .field('lat', ISTANBUL.lat)
      .field('lng', ISTANBUL.lng)
      .field('severity', 1)
      .expect(201);
    const firstId = (first.body as ReportResponse).id;

    // Duplicate check is purely spatial/temporal, not per-user, so a
    // different device attempting a nearby report is still rejected.
    const dup = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userC}`)
      .field('lat', ISTANBUL.lat + 0.0001)
      .field('lng', ISTANBUL.lng + 0.0001)
      .field('severity', 2)
      .expect(409);
    expect((dup.body as { nearbyReportId: string }).nearbyReportId).toBe(
      firstId,
    );
  });

  it('processes a valid photo: strips EXIF, converts to WebP, serves it', async () => {
    const jpeg = await sharp({
      create: {
        width: 40,
        height: 30,
        channels: 3,
        background: { r: 200, g: 50, b: 50 },
      },
    })
      .withExif({ IFD0: { Make: 'PhoneCo' } })
      .jpeg()
      .toBuffer();

    const res = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userB}`)
      .field('lat', 37.0)
      .field('lng', 35.3)
      .field('severity', 4)
      .attach('photo', jpeg, 'pothole.jpg')
      .expect(201);
    const body = res.body as ReportResponse;
    expect(body.photoUrl).toMatch(/^\/uploads\/[\w-]+\.webp$/);

    const image = await request(app.getHttpServer())
      .get(body.photoUrl!)
      .expect(200);
    expect(image.headers['content-type']).toBe('image/webp');
    const metadata = await sharp(image.body as Buffer).metadata();
    expect(metadata.format).toBe('webp');
    expect(metadata.exif).toBeUndefined();
  });

  it('rejects a non-image buffer sent as a photo', async () => {
    await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userC}`)
      .field('lat', 38.4)
      .field('lng', 27.1)
      .field('severity', 1)
      .attach('photo', Buffer.from('not an image'), 'fake.jpg')
      .expect(400);
  });

  it('GET /reports filters markers by bbox', async () => {
    await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userC}`)
      .field('lat', 40.0)
      .field('lng', 30.0)
      .field('severity', 2)
      .expect(201);

    const inside = await request(app.getHttpServer())
      .get('/reports')
      .set('Authorization', `Bearer ${userC}`)
      .query({ bbox: '29.9,39.9,30.1,40.1' })
      .expect(200);
    const insideBody = inside.body as ReportResponse[];
    expect(insideBody.some((r) => Math.abs(r.lat - 40.0) < 0.01)).toBe(true);

    const outside = await request(app.getHttpServer())
      .get('/reports')
      .set('Authorization', `Bearer ${userC}`)
      .query({ bbox: '-10,-10,-9,-9' })
      .expect(200);
    expect(outside.body as ReportResponse[]).toEqual([]);
  });

  it('GET /reports/:id returns detail, 404 for unknown id', async () => {
    const created = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userD}`)
      .field('lat', 36.5)
      .field('lng', 33.0)
      .field('severity', 1)
      .expect(201);
    const id = (created.body as ReportResponse).id;

    const detail = await request(app.getHttpServer())
      .get(`/reports/${id}`)
      .set('Authorization', `Bearer ${userD}`)
      .expect(200);
    expect((detail.body as ReportResponse).id).toBe(id);

    await request(app.getHttpServer())
      .get(`/reports/${randomUUID()}`)
      .set('Authorization', `Bearer ${userD}`)
      .expect(404);
  });

  it('votes are idempotent per user and trigger threshold status transitions', async () => {
    // userD's 2nd POST /reports of this suite — well under its 5/min cap.
    const created = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${userD}`)
      .field('lat', 39.0)
      .field('lng', 34.0)
      .field('severity', 2)
      .expect(201);
    const id = (created.body as ReportResponse).id;

    // POST /reports/:id/votes has no strict per-route override, so it falls
    // back to the generous global default throttle — safe to reuse devices.
    const firstVote = await request(app.getHttpServer())
      .post(`/reports/${id}/votes`)
      .set('Authorization', `Bearer ${userD}`)
      .send({ type: 'confirm' })
      .expect(201);
    expect((firstVote.body as ReportResponse).confirmCount).toBe(1);

    const repeatVote = await request(app.getHttpServer())
      .post(`/reports/${id}/votes`)
      .set('Authorization', `Bearer ${userD}`)
      .send({ type: 'confirm' })
      .expect(201);
    expect((repeatVote.body as ReportResponse).confirmCount).toBe(1);

    // HIDE_THRESHOLD=3: three distinct users complaining flips status to
    // hidden. Reuse the existing pool instead of minting new devices.
    let last: ReportResponse | undefined;
    for (const complainerToken of [userA, userB, userC]) {
      const res = await request(app.getHttpServer())
        .post(`/reports/${id}/votes`)
        .set('Authorization', `Bearer ${complainerToken}`)
        .send({ type: 'complaint' })
        .expect(201);
      last = res.body as ReportResponse;
    }
    expect(last?.complaintCount).toBe(3);
    expect(last?.status).toBe('hidden');
  });

  it('POST /reports/:id/votes 404 for unknown report', async () => {
    await request(app.getHttpServer())
      .post(`/reports/${randomUUID()}/votes`)
      .set('Authorization', `Bearer ${userA}`)
      .send({ type: 'confirm' })
      .expect(404);
  });
});
