import { Injectable } from '@nestjs/common';
import { CityLeagueEntry, StatsRepository } from './stats.repository';
import { QueryStatsCitiesDto } from './dto/query-stats-cities.dto';

@Injectable()
export class StatsService {
  constructor(private readonly repository: StatsRepository) {}

  getCityLeague(query: QueryStatsCitiesDto): Promise<CityLeagueEntry[]> {
    return this.repository.getCityLeague(query.sort ?? 'total');
  }
}
