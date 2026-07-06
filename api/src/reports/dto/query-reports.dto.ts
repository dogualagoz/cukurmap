import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';
import { ReportStatus } from '@prisma/client';

const BBOX_PATTERN =
  /^-?\d+(\.\d+)?,-?\d+(\.\d+)?,-?\d+(\.\d+)?,-?\d+(\.\d+)?$/;

export class QueryReportsDto {
  @IsString()
  @Matches(BBOX_PATTERN, {
    message: 'bbox must be "minLng,minLat,maxLng,maxLat"',
  })
  bbox: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(4)
  severity?: number;

  @IsOptional()
  @IsEnum(ReportStatus)
  status?: ReportStatus;

  @IsOptional()
  @IsISO8601()
  since?: string;
}
