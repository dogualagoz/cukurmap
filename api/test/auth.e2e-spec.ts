import { randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

interface AuthResponse {
  token: string;
  user: { id: string; nickname: string };
}

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  const deviceId = randomUUID();

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /auth/anonymous returns token and same user for same device', async () => {
    const first = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId })
      .expect(200);
    const firstBody = first.body as AuthResponse;
    expect(firstBody.token).toBeDefined();
    expect(firstBody.user.nickname).toMatch(/#\d{4}$/);

    const second = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId })
      .expect(200);
    expect((second.body as AuthResponse).user.id).toBe(firstBody.user.id);
  });

  it('rejects malformed deviceId', () =>
    request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId: 'short' })
      .expect(400));

  it('GET /users/me requires auth', () =>
    request(app.getHttpServer()).get('/users/me').expect(401));

  it('GET /users/me returns profile, PATCH updates nickname', async () => {
    const auth = await request(app.getHttpServer())
      .post('/auth/anonymous')
      .send({ deviceId })
      .expect(200);
    const token = (auth.body as AuthResponse).token;

    const me = await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect((me.body as { reportCount: number }).reportCount).toBe(0);

    const updated = await request(app.getHttpServer())
      .patch('/users/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ nickname: 'Krater Lordu #1' })
      .expect(200);
    expect((updated.body as { nickname: string }).nickname).toBe(
      'Krater Lordu #1',
    );

    await request(app.getHttpServer())
      .patch('/users/me')
      .set('Authorization', `Bearer ${token}`)
      .send({ nickname: 'x' })
      .expect(400);
  });

  it('rejects garbage tokens', () =>
    request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', 'Bearer not-a-jwt')
      .expect(401));
});
