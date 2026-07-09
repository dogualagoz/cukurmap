import { randomUUID } from 'node:crypto';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { UPLOADS_DIR } from '../src/reports/photo-pipeline.service';

interface AuthResponse {
  token: string;
  user: { id: string; nickname: string };
}

interface ReportResponse {
  id: string;
}

interface MyReportsPage {
  items: { id: string; createdAt: string }[];
  nextCursor: { createdAt: string; id: string } | null;
}

// Kızılay, Ankara — inside province #6 per seed sanity check
const ANKARA = { lat: 39.9208, lng: 32.8541 };

describe('Users (e2e)', () => {
  let app: NestExpressApplication;
  let prisma: PrismaService;

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

    // Deterministic baseline; run with --runInBand (see test:e2e script).
    prisma = moduleFixture.get(PrismaService);
    await prisma.$executeRawUnsafe('TRUNCATE TABLE votes, reports CASCADE');
  });

  afterAll(async () => {
    await app.close();
  });

  async function authAs(): Promise<AuthResponse> {
    const res = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId: randomUUID() })
      .expect(200);
    return res.body as AuthResponse;
  }

  async function createReport(
    token: string,
    coords: { lat: number; lng: number },
  ): Promise<string> {
    const res = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${token}`)
      .field('lat', coords.lat)
      .field('lng', coords.lng)
      .field('severity', 2)
      .expect(201);
    return (res.body as ReportResponse).id;
  }

  it('GET /users/me/reports requires auth', () =>
    request(app.getHttpServer()).get('/users/me/reports').expect(401));

  it('lists only own reports, newest first, with keyset pagination', async () => {
    const userA = await authAs();
    const userB = await authAs();

    // Offset each report by >50m to dodge the spatial duplicate check.
    const a1 = await createReport(userA.token, ANKARA);
    const a2 = await createReport(userA.token, {
      lat: ANKARA.lat + 0.002,
      lng: ANKARA.lng,
    });
    const a3 = await createReport(userA.token, {
      lat: ANKARA.lat + 0.004,
      lng: ANKARA.lng,
    });
    await createReport(userB.token, {
      lat: ANKARA.lat + 0.006,
      lng: ANKARA.lng,
    });

    const page1res = await request(app.getHttpServer())
      .get('/users/me/reports')
      .query({ limit: 2 })
      .set('Authorization', `Bearer ${userA.token}`)
      .expect(200);
    const page1 = page1res.body as MyReportsPage;
    expect(page1.items).toHaveLength(2);
    expect(page1.items.map((r) => r.id)).toEqual([a3, a2]);
    expect(page1.nextCursor).not.toBeNull();

    const page2res = await request(app.getHttpServer())
      .get('/users/me/reports')
      .query({
        limit: 2,
        cursorCreatedAt: page1.nextCursor!.createdAt,
        cursorId: page1.nextCursor!.id,
      })
      .set('Authorization', `Bearer ${userA.token}`)
      .expect(200);
    const page2 = page2res.body as MyReportsPage;
    expect(page2.items.map((r) => r.id)).toEqual([a1]);
    expect(page2.nextCursor).toBeNull();
  });

  it('rejects an invalid cursor', async () => {
    const user = await authAs();
    await request(app.getHttpServer())
      .get('/users/me/reports')
      .query({ cursorId: 'not-a-uuid' })
      .set('Authorization', `Bearer ${user.token}`)
      .expect(400);
  });

  it('DELETE /users/me anonymizes reports, cascades votes, invalidates token', async () => {
    const doomed = await authAs();
    const other = await authAs();

    const doomedReport = await createReport(doomed.token, {
      lat: ANKARA.lat + 0.008,
      lng: ANKARA.lng,
    });
    const otherReport = await createReport(other.token, {
      lat: ANKARA.lat + 0.01,
      lng: ANKARA.lng,
    });

    // The doomed user votes on someone else's report → must cascade away.
    await request(app.getHttpServer())
      .post(`/reports/${otherReport}/votes`)
      .set('Authorization', `Bearer ${doomed.token}`)
      .send({ type: 'confirm' })
      .expect(201);

    await request(app.getHttpServer())
      .delete('/users/me')
      .set('Authorization', `Bearer ${doomed.token}`)
      .expect(204);

    // Old token is dead (guard's findUnique misses).
    await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', `Bearer ${doomed.token}`)
      .expect(401);

    // Report survives, anonymized.
    await request(app.getHttpServer())
      .get(`/reports/${doomedReport}`)
      .set('Authorization', `Bearer ${other.token}`)
      .expect(200);
    const orphan = await prisma.report.findUnique({
      where: { id: doomedReport },
    });
    expect(orphan?.userId).toBeNull();

    // Votes are gone.
    const voteCount = await prisma.vote.count({
      where: { userId: doomed.user.id },
    });
    expect(voteCount).toBe(0);
  });
});
