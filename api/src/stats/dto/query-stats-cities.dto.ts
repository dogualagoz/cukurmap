import { IsIn, IsOptional } from 'class-validator';

export type CityLeagueSort = 'total' | 'per_capita';

export class QueryStatsCitiesDto {
  @IsOptional()
  @IsIn(['total', 'per_capita'])
  sort?: CityLeagueSort;
}
