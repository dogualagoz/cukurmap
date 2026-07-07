import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { QueryStatsCitiesDto } from './dto/query-stats-cities.dto';
import { StatsService } from './stats.service';

@Controller('stats')
@UseGuards(JwtAuthGuard)
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get('cities')
  cities(@Query() query: QueryStatsCitiesDto) {
    return this.statsService.getCityLeague(query);
  }
}
