import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import type { User } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateReportDto } from './dto/create-report.dto';
import { CreateVoteDto } from './dto/create-vote.dto';
import { QueryReportsDto } from './dto/query-reports.dto';
import { ReportsService } from './reports.service';

const MAX_PHOTO_BYTES = 10 * 1024 * 1024;

@Controller('reports')
@UseGuards(JwtAuthGuard)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @UseInterceptors(
    FileInterceptor('photo', { limits: { fileSize: MAX_PHOTO_BYTES } }),
  )
  create(
    @CurrentUser() user: User,
    @Body() dto: CreateReportDto,
    @UploadedFile() photo?: Express.Multer.File,
  ) {
    return this.reportsService.create(user, dto, photo);
  }

  @Get()
  list(@Query() query: QueryReportsDto) {
    return this.reportsService.findMarkers(query);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.reportsService.findById(id);
  }

  @Post(':id/votes')
  vote(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: User,
    @Body() dto: CreateVoteDto,
  ) {
    return this.reportsService.vote(id, user, dto);
  }
}
