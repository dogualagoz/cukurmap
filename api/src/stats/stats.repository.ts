import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CityLeagueSort } from './dto/query-stats-cities.dto';

const LEAGUE_WINDOW_DAYS = 7;
const LEAGUE_LIMIT = 20;

export interface CityLeagueEntry {
  name: string;
  slug: string;
  reportCount: number;
  resolvedPct: number;
  verifications: number;
}

@Injectable()
export class StatsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getCityLeague(sort: CityLeagueSort): Promise<CityLeagueEntry[]> {
    const since = new Date(
      Date.now() - LEAGUE_WINDOW_DAYS * 24 * 60 * 60 * 1000,
    );

    const [totals, fixed] = await Promise.all([
      this.prisma.report.groupBy({
        by: ['provinceId'],
        where: {
          status: { not: 'deleted' },
          createdAt: { gte: since },
          provinceId: { not: null },
        },
        _count: { _all: true },
        _sum: { confirmCount: true },
      }),
      this.prisma.report.groupBy({
        by: ['provinceId'],
        where: {
          status: 'fixed',
          createdAt: { gte: since },
          provinceId: { not: null },
        },
        _count: { _all: true },
      }),
    ]);

    const fixedByProvince = new Map(
      fixed.map((row) => [row.provinceId, row._count._all]),
    );
    const provinceIds = totals.map((row) => row.provinceId as number);
    const provinces = await this.prisma.province.findMany({
      where: { id: { in: provinceIds } },
    });
    const provinceById = new Map(provinces.map((p) => [p.id, p]));

    const rows = totals.map((row) => {
      const province = provinceById.get(row.provinceId as number)!;
      const reportCount = row._count._all;
      const fixedCount = fixedByProvince.get(row.provinceId) ?? 0;
      return {
        name: province.name,
        slug: province.slug,
        reportCount,
        resolvedPct: Math.round((fixedCount * 100) / reportCount),
        verifications: row._sum.confirmCount ?? 0,
        population: province.population,
      };
    });

    rows.sort(
      sort === 'per_capita'
        ? (a, b) => b.reportCount / b.population - a.reportCount / a.population
        : (a, b) => b.reportCount - a.reportCount,
    );

    return rows.slice(0, LEAGUE_LIMIT).map((row) => ({
      name: row.name,
      slug: row.slug,
      reportCount: row.reportCount,
      resolvedPct: row.resolvedPct,
      verifications: row.verifications,
    }));
  }
}
