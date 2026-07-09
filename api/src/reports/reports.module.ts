import { Module } from '@nestjs/common';
import { PhotoPipelineService } from './photo-pipeline.service';
import { ReportsController } from './reports.controller';
import { ReportsRepository } from './reports.repository';
import { ReportsService } from './reports.service';

@Module({
  controllers: [ReportsController],
  providers: [ReportsService, ReportsRepository, PhotoPipelineService],
  exports: [ReportsService],
})
export class ReportsModule {}
