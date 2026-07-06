import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ReportStatus, User } from '@prisma/client';
import { CreateReportDto } from './dto/create-report.dto';
import { CreateVoteDto } from './dto/create-vote.dto';
import { QueryReportsDto } from './dto/query-reports.dto';
import { PhotoPipelineService } from './photo-pipeline.service';
import {
  ReportDetail,
  ReportMarker,
  ReportsRepository,
} from './reports.repository';

const DEFAULT_FIXED_THRESHOLD = 5;
const DEFAULT_HIDE_THRESHOLD = 3;

export interface ReportDetailResponse {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  category: string;
  description: string | null;
  photoUrl: string | null;
  status: ReportStatus;
  confirmCount: number;
  fixedCount: number;
  stillThereCount: number;
  complaintCount: number;
  createdAt: Date;
  province: { name: string; slug: string } | null;
}

@Injectable()
export class ReportsService {
  constructor(
    private readonly repository: ReportsRepository,
    private readonly photoPipeline: PhotoPipelineService,
    private readonly config: ConfigService,
  ) {}

  async create(
    user: User,
    dto: CreateReportDto,
    photo: Express.Multer.File | undefined,
  ): Promise<ReportDetailResponse> {
    const nearbyReportId = await this.repository.findNearbyDuplicate(
      dto.lat,
      dto.lng,
    );
    if (nearbyReportId) {
      throw new ConflictException({
        message: 'Bu konuma 24 saat içinde zaten bir bildirim yapılmış',
        nearbyReportId,
      });
    }

    const photoPath = photo
      ? await this.photoPipeline.process(photo.buffer)
      : undefined;

    const report = await this.repository.create({
      userId: user.id,
      lat: dto.lat,
      lng: dto.lng,
      severity: dto.severity,
      category: dto.category,
      description: dto.description,
      photoPath,
    });
    return toResponse(report);
  }

  async findMarkers(query: QueryReportsDto): Promise<ReportMarker[]> {
    const [minLng, minLat, maxLng, maxLat] = query.bbox.split(',').map(Number);
    return this.repository.listByBbox({
      minLng,
      minLat,
      maxLng,
      maxLat,
      severity: query.severity,
      status: query.status,
      since: query.since ? new Date(query.since) : undefined,
    });
  }

  async findById(id: string): Promise<ReportDetailResponse> {
    const report = await this.repository.findById(id);
    if (!report) {
      throw new NotFoundException('Bildirim bulunamadı');
    }
    return toResponse(report);
  }

  async vote(
    reportId: string,
    user: User,
    dto: CreateVoteDto,
  ): Promise<ReportDetailResponse> {
    const status = await this.repository.findStatusById(reportId);
    if (!status) {
      throw new NotFoundException('Bildirim bulunamadı');
    }
    const { report } = await this.repository.vote(reportId, user.id, dto.type, {
      fixed: Number(
        this.config.get('FIXED_THRESHOLD') ?? DEFAULT_FIXED_THRESHOLD,
      ),
      hide: Number(this.config.get('HIDE_THRESHOLD') ?? DEFAULT_HIDE_THRESHOLD),
    });
    return toResponse(report);
  }
}

function toResponse(report: ReportDetail): ReportDetailResponse {
  return {
    id: report.id,
    lat: report.lat,
    lng: report.lng,
    severity: report.severity,
    category: report.category,
    description: report.description,
    photoUrl: report.photoPath ? `/uploads/${report.photoPath}` : null,
    status: report.status,
    confirmCount: report.confirmCount,
    fixedCount: report.fixedCount,
    stillThereCount: report.stillThereCount,
    complaintCount: report.complaintCount,
    createdAt: report.createdAt,
    province:
      report.provinceName && report.provinceSlug
        ? { name: report.provinceName, slug: report.provinceSlug }
        : null,
  };
}
