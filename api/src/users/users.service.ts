import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface UserProfile {
  id: string;
  nickname: string;
  reportCount: number;
  confirmsReceived: number;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async profile(user: User): Promise<UserProfile> {
    const stats = await this.prisma.report.aggregate({
      where: { userId: user.id, status: { not: 'deleted' } },
      _count: true,
      _sum: { confirmCount: true },
    });
    return {
      id: user.id,
      nickname: user.nickname,
      reportCount: stats._count,
      confirmsReceived: stats._sum.confirmCount ?? 0,
    };
  }

  async updateNickname(user: User, nickname: string): Promise<UserProfile> {
    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { nickname },
    });
    return this.profile(updated);
  }
}
