import { createHmac } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/** Rumuzlar mizahi ama kimseyi hedef göstermez */
const NICKNAME_PREFIXES = [
  'Çukur Avcısı',
  'Krater Kaşifi',
  'Asfalt Dedektifi',
  'Jant Şehidi',
  'Amortisör Emeklisi',
  'Yol Yorgunu',
  'Tümsek Ustası',
  'Rot Balans Gurusu',
];

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  private hashDeviceId(deviceId: string): string {
    const pepper = this.config.getOrThrow<string>('DEVICE_PEPPER');
    return createHmac('sha256', pepper).update(deviceId).digest('hex');
  }

  private randomNickname(): string {
    const prefix =
      NICKNAME_PREFIXES[Math.floor(Math.random() * NICKNAME_PREFIXES.length)];
    const number = Math.floor(1000 + Math.random() * 9000);
    return `${prefix} #${number}`;
  }

  /** Kayıt-veya-giriş: aynı cihaz her zaman aynı kullanıcıya döner. */
  async anonymous(deviceId: string): Promise<{ token: string; user: User }> {
    const deviceHash = this.hashDeviceId(deviceId);
    const user = await this.prisma.user.upsert({
      where: { deviceHash },
      update: { lastSeenAt: new Date() },
      create: { deviceHash, nickname: this.randomNickname() },
    });
    const token = await this.jwt.signAsync({ sub: user.id });
    return { token, user };
  }
}
