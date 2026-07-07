import { Injectable } from '@nestjs/common';
import { User } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface UserProfile {
  id: string;
  nickname: string;
  reportCount: number;
  confirmsReceived: number;
  fixedReportCount: number;
  confirmsGiven: number;
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async profile(user: User): Promise<UserProfile> {
    const [stats, fixedReportCount, confirmsGiven] = await Promise.all([
      this.prisma.report.aggregate({
        where: { userId: user.id, status: { not: 'deleted' } },
        _count: true,
        _sum: { confirmCount: true },
      }),
      this.prisma.report.count({
        where: { userId: user.id, status: 'fixed' },
      }),
      this.prisma.vote.count({
        where: { userId: user.id, type: 'confirm' },
      }),
    ]);
    return {
      id: user.id,
      nickname: user.nickname,
      reportCount: stats._count,
      confirmsReceived: stats._sum.confirmCount ?? 0,
      fixedReportCount,
      confirmsGiven,
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
