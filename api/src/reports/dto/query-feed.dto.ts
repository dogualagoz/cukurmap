import { Type } from 'class-transformer';
import {
  IsIn,
  IsISO8601,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class QueryFeedDto {
  @IsOptional()
  @IsIn(['recent', 'score'])
  sort?: 'recent' | 'score' = 'recent';

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;

  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  lat?: number;

  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  lng?: number;

  @IsOptional()
  @IsISO8601()
  cursorCreatedAt?: string;

  @IsOptional()
  @IsUUID()
  cursorId?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  cursorScore?: number;
}
