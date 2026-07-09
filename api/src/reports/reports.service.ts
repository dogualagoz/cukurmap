import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ReportStatus, User } from '@prisma/client';
import { CreateReportDto } from './dto/create-report.dto';
import { CreateVoteDto } from './dto/create-vote.dto';
import { QueryFeedDto } from './dto/query-feed.dto';
import { QueryReportsDto } from './dto/query-reports.dto';
import { PhotoPipelineService } from './photo-pipeline.service';
import { ReportDetail, ReportsRepository } from './reports.repository';

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
  upvoteCount: number;
  downvoteCount: number;
  createdAt: Date;
  province: { name: string; slug: string } | null;
}

export interface ReportMarkerResponse {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  status: ReportStatus;
  photoUrl: string | null;
}

export interface FeedItemResponse extends ReportDetailResponse {
  distanceMeters: number | null;
}

export interface FeedCursor {
  createdAt: string;
  id: string;
  score: number;
}

export interface FeedPageResponse {
  items: FeedItemResponse[];
  nextCursor: FeedCursor | null;
}

export interface MyReportsCursor {
  createdAt: string;
  id: string;
}

export interface MyReportsPageResponse {
  items: ReportDetailResponse[];
  nextCursor: MyReportsCursor | null;
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

  async findMarkers(query: QueryReportsDto): Promise<ReportMarkerResponse[]> {
    const [minLng, minLat, maxLng, maxLat] = query.bbox.split(',').map(Number);
    const markers = await this.repository.listByBbox({
      minLng,
      minLat,
      maxLng,
      maxLat,
      severity: query.severity,
      status: query.status,
      since: query.since ? new Date(query.since) : undefined,
    });
    return markers.map((marker) => ({
      id: marker.id,
      lat: marker.lat,
      lng: marker.lng,
      severity: marker.severity,
      status: marker.status,
      photoUrl: photoPathToUrl(marker.photoPath),
    }));
  }

  async findById(id: string): Promise<ReportDetailResponse> {
    const report = await this.repository.findById(id);
    if (!report) {
      throw new NotFoundException('Bildirim bulunamadı');
    }
    return toResponse(report);
  }

  async findFeed(query: QueryFeedDto): Promise<FeedPageResponse> {
    const sort = query.sort ?? 'recent';
    const limit = query.limit ?? 20;
    const items = await this.repository.listFeed({
      sort,
      limit,
      lat: query.lat,
      lng: query.lng,
      cursorCreatedAt: query.cursorCreatedAt
        ? new Date(query.cursorCreatedAt)
        : undefined,
      cursorId: query.cursorId,
      cursorScore: query.cursorScore,
    });
    const last = items.at(-1);
    const nextCursor: FeedCursor | null =
      items.length === limit && last
        ? {
            createdAt: last.createdAt.toISOString(),
            id: last.id,
            score: last.upvoteCount - last.downvoteCount,
          }
        : null;
    return {
      items: items.map((item) => ({
        ...toResponse(item),
        distanceMeters: item.distanceMeters,
      })),
      nextCursor,
    };
  }

  async findMyReports(
    userId: string,
    query: { limit?: number; cursorCreatedAt?: string; cursorId?: string },
  ): Promise<MyReportsPageResponse> {
    const limit = query.limit ?? 20;
    const items = await this.repository.listByUser({
      userId,
      limit,
      cursorCreatedAt: query.cursorCreatedAt
        ? new Date(query.cursorCreatedAt)
        : undefined,
      cursorId: query.cursorId,
    });
    const last = items.at(-1);
    const nextCursor: MyReportsCursor | null =
      items.length === limit && last
        ? { createdAt: last.createdAt.toISOString(), id: last.id }
        : null;
    return { items: items.map(toResponse), nextCursor };
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

function photoPathToUrl(photoPath: string | null): string | null {
  return photoPath ? `/uploads/${photoPath}` : null;
}

function toResponse(report: ReportDetail): ReportDetailResponse {
  return {
    id: report.id,
    lat: report.lat,
    lng: report.lng,
    severity: report.severity,
    category: report.category,
    description: report.description,
    photoUrl: photoPathToUrl(report.photoPath),
    status: report.status,
    confirmCount: report.confirmCount,
    fixedCount: report.fixedCount,
    stillThereCount: report.stillThereCount,
    complaintCount: report.complaintCount,
    upvoteCount: report.upvoteCount,
    downvoteCount: report.downvoteCount,
    createdAt: report.createdAt,
    province:
      report.provinceName && report.provinceSlug
        ? { name: report.provinceName, slug: report.provinceSlug }
        : null,
  };
}
