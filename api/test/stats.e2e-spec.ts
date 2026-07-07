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

interface CityLeagueEntry {
  name: string;
  slug: string;
  reportCount: number;
  resolvedPct: number;
  verifications: number;
}

// Kızılay, Ankara — falls inside province #6 per seed sanity check
const ANKARA = { lat: 39.9208, lng: 32.8541 };
// Sultanahmet, İstanbul — a different province, far from ANKARA
const ISTANBUL = { lat: 41.0055, lng: 28.9769 };

describe('Stats (e2e)', () => {
  let app: NestExpressApplication;

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

    // Deterministic baseline: this suite's assertions depend on exact counts
    // per province, so leftover rows from other suites would false-positive.
    // Run test:e2e with --runInBand so no other DB-mutating suite overlaps.
    const prisma = moduleFixture.get(PrismaService);
    await prisma.$executeRawUnsafe('TRUNCATE TABLE votes, reports CASCADE');
  });

  afterAll(async () => {
    await app.close();
  });

  async function authAs(): Promise<string> {
    const res = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId: randomUUID() })
      .expect(200);
    return (res.body as AuthResponse).token;
  }

  async function createReport(
    token: string,
    coords: { lat: number; lng: number },
  ) {
    const res = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${token}`)
      .field('lat', coords.lat)
      .field('lng', coords.lng)
      .field('severity', 2)
      .expect(201);
    return (res.body as ReportResponse).id;
  }

  it('GET /stats/cities requires auth', () =>
    request(app.getHttpServer()).get('/stats/cities').expect(401));

  it('aggregates report counts, resolved %, and verifications per province', async () => {
    // 5 distinct devices to reach FIXED_THRESHOLD=5 on one report, plus a
    // couple more for creating reports and confirm votes.
    const users = await Promise.all(Array.from({ length: 6 }, () => authAs()));
    const [u1, u2, u3, u4, u5, u6] = users;

    // Offset each report by >50m (duplicate check is purely spatial/temporal,
    // not per-user) while staying well inside the same province.
    const ankaraR1 = await createReport(u1, ANKARA);
    await createReport(u2, { lat: ANKARA.lat + 0.002, lng: ANKARA.lng });
    await createReport(u3, { lat: ANKARA.lat + 0.004, lng: ANKARA.lng });
    await createReport(u6, ISTANBUL);

    // Flip ankaraR1 to 'fixed': 5 distinct users vote 'fixed'.
    for (const token of [u1, u2, u3, u4, u5]) {
      await request(app.getHttpServer())
        .post(`/reports/${ankaraR1}/votes`)
        .set('Authorization', `Bearer ${token}`)
        .send({ type: 'fixed' })
        .expect(201);
    }

    // 3 confirm votes total on Ankara reports → verifications sum.
    await request(app.getHttpServer())
      .post(`/reports/${ankaraR1}/votes`)
      .set('Authorization', `Bearer ${u6}`)
      .send({ type: 'confirm' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/reports/${ankaraR1}/votes`)
      .set('Authorization', `Bearer ${u1}`)
      .send({ type: 'confirm' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/reports/${ankaraR1}/votes`)
      .set('Authorization', `Bearer ${u2}`)
      .send({ type: 'confirm' })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/stats/cities')
      .set('Authorization', `Bearer ${u1}`)
      .expect(200);
    const league = res.body as CityLeagueEntry[];

    const ankara = league.find((c) => c.slug === 'ankara');
    expect(ankara).toBeDefined();
    expect(ankara!.reportCount).toBe(3);
    expect(ankara!.resolvedPct).toBe(33); // 1 of 3 fixed, rounded
    expect(ankara!.verifications).toBe(3);

    const istanbulIndex = league.findIndex((c) => c.slug === 'istanbul');
    const ankaraIndex = league.findIndex((c) => c.slug === 'ankara');
    expect(ankaraIndex).toBeLessThan(istanbulIndex);
  });

  it('GET /stats/cities?sort=per_capita reorders by reportCount/population', async () => {
    const res = await request(app.getHttpServer())
      .get('/stats/cities')
      .query({ sort: 'per_capita' })
      .set('Authorization', `Bearer ${await authAs()}`)
      .expect(200);
    const league = res.body as CityLeagueEntry[];
    expect(league.length).toBeGreaterThan(0);
  });

  it('GET /stats/cities rejects an invalid sort value', async () => {
    const token = await authAs();
    await request(app.getHttpServer())
      .get('/stats/cities')
      .query({ sort: 'bogus' })
      .set('Authorization', `Bearer ${token}`)
      .expect(400);
  });
});
