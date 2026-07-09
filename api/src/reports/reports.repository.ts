import { Injectable } from '@nestjs/common';
import { Prisma, ReportCategory, ReportStatus, VoteType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const DUPLICATE_RADIUS_METERS = 50;

export interface ReportMarker {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  status: ReportStatus;
  photoPath: string | null;
}

export interface ReportDetail {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  category: ReportCategory;
  description: string | null;
  photoPath: string | null;
  status: ReportStatus;
  confirmCount: number;
  fixedCount: number;
  stillThereCount: number;
  complaintCount: number;
  upvoteCount: number;
  downvoteCount: number;
  createdAt: Date;
  provinceName: string | null;
  provinceSlug: string | null;
}

export interface FeedItem extends ReportDetail {
  distanceMeters: number | null;
}

export interface CreateReportInput {
  userId: string;
  lat: number;
  lng: number;
  severity: number;
  category?: ReportCategory;
  description?: string;
  photoPath?: string;
}

const VOTE_COUNT_COLUMN: Record<VoteType, string> = {
  confirm: 'confirm_count',
  fixed: 'fixed_count',
  still_there: 'still_there_count',
  complaint: 'complaint_count',
  upvote: 'upvote_count',
  downvote: 'downvote_count',
};

@Injectable()
export class ReportsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findNearbyDuplicate(lat: number, lng: number): Promise<string | null> {
    const rows = await this.prisma.$queryRaw<{ id: string }[]>`
      SELECT id FROM reports
      WHERE status != 'deleted'
        AND created_at > now() - interval '24 hours'
        AND ST_DWithin(
          location::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${DUPLICATE_RADIUS_METERS}
        )
      LIMIT 1
    `;
    return rows[0]?.id ?? null;
  }

  async create(input: CreateReportInput): Promise<ReportDetail> {
    const rows = await this.prisma.$queryRaw<ReportDetailRow[]>`
      WITH inserted AS (
        INSERT INTO reports (
          id, user_id, location, province_id, severity, category, description, photo_path, updated_at
        ) VALUES (
          gen_random_uuid(),
          ${input.userId}::uuid,
          ST_SetSRID(ST_MakePoint(${input.lng}, ${input.lat}), 4326),
          (SELECT id FROM provinces
            WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(${input.lng}, ${input.lat}), 4326))
            LIMIT 1),
          ${input.severity},
          ${input.category ?? 'cukur'}::report_category,
          ${input.description ?? null},
          ${input.photoPath ?? null},
          now()
        )
        RETURNING *
      )
      SELECT
        inserted.id,
        ST_Y(inserted.location) AS lat,
        ST_X(inserted.location) AS lng,
        inserted.severity,
        inserted.category,
        inserted.description,
        inserted.photo_path AS "photoPath",
        inserted.status,
        inserted.confirm_count AS "confirmCount",
        inserted.fixed_count AS "fixedCount",
        inserted.still_there_count AS "stillThereCount",
        inserted.complaint_count AS "complaintCount",
        inserted.upvote_count AS "upvoteCount",
        inserted.downvote_count AS "downvoteCount",
        inserted.created_at AS "createdAt",
        provinces.name AS "provinceName",
        provinces.slug AS "provinceSlug"
      FROM inserted
      LEFT JOIN provinces ON provinces.id = inserted.province_id
    `;
    return mapDetailRow(rows[0]);
  }

  async listByBbox(filter: {
    minLng: number;
    minLat: number;
    maxLng: number;
    maxLat: number;
    severity?: number;
    status?: ReportStatus;
    since?: Date;
  }): Promise<ReportMarker[]> {
    const statusFilter = filter.status
      ? Prisma.sql`AND status = ${filter.status}::report_status`
      : Prisma.sql`AND status != 'deleted'`;
    const severityFilter = filter.severity
      ? Prisma.sql`AND severity = ${filter.severity}`
      : Prisma.empty;
    const sinceFilter = filter.since
      ? Prisma.sql`AND created_at >= ${filter.since}`
      : Prisma.empty;

    const rows = await this.prisma.$queryRaw<
      {
        id: string;
        lat: number;
        lng: number;
        severity: number;
        status: ReportStatus;
        photoPath: string | null;
      }[]
    >`
      SELECT
        id,
        ST_Y(location) AS lat,
        ST_X(location) AS lng,
        severity,
        status,
        photo_path AS "photoPath"
      FROM reports
      WHERE location && ST_MakeEnvelope(
        ${filter.minLng}, ${filter.minLat}, ${filter.maxLng}, ${filter.maxLat}, 4326
      )
      ${statusFilter}
      ${severityFilter}
      ${sinceFilter}
      ORDER BY created_at DESC
      LIMIT 500
    `;
    return rows;
  }

  async findById(id: string): Promise<ReportDetail | null> {
    const rows = await this.prisma.$queryRaw<ReportDetailRow[]>`
      SELECT
        reports.id,
        ST_Y(reports.location) AS lat,
        ST_X(reports.location) AS lng,
        reports.severity,
        reports.category,
        reports.description,
        reports.photo_path AS "photoPath",
        reports.status,
        reports.confirm_count AS "confirmCount",
        reports.fixed_count AS "fixedCount",
        reports.still_there_count AS "stillThereCount",
        reports.complaint_count AS "complaintCount",
        reports.upvote_count AS "upvoteCount",
        reports.downvote_count AS "downvoteCount",
        reports.created_at AS "createdAt",
        provinces.name AS "provinceName",
        provinces.slug AS "provinceSlug"
      FROM reports
      LEFT JOIN provinces ON provinces.id = reports.province_id
      WHERE reports.id = ${id}::uuid
      LIMIT 1
    `;
    return rows[0] ? mapDetailRow(rows[0]) : null;
  }

  /** Twitter-vari feed: en yeni veya en yüksek net oylu (upvote-downvote) bildirimler, keyset sayfalama ile. */
  async listFeed(filter: {
    sort: 'recent' | 'score';
    limit: number;
    lat?: number;
    lng?: number;
    cursorCreatedAt?: Date;
    cursorId?: string;
    cursorScore?: number;
  }): Promise<FeedItem[]> {
    const hasLocation = filter.lat !== undefined && filter.lng !== undefined;
    const distanceExpr = hasLocation
      ? Prisma.sql`ST_Distance(
          reports.location::geography,
          ST_SetSRID(ST_MakePoint(${filter.lng}, ${filter.lat}), 4326)::geography
        )`
      : Prisma.sql`NULL`;

    const cursorFilter =
      filter.sort === 'score'
        ? filter.cursorScore !== undefined &&
          filter.cursorCreatedAt &&
          filter.cursorId
          ? Prisma.sql`AND (reports.upvote_count - reports.downvote_count, reports.created_at, reports.id)
              < (${filter.cursorScore}, ${filter.cursorCreatedAt}, ${filter.cursorId}::uuid)`
          : Prisma.empty
        : filter.cursorCreatedAt && filter.cursorId
          ? Prisma.sql`AND (reports.created_at, reports.id) < (${filter.cursorCreatedAt}, ${filter.cursorId}::uuid)`
          : Prisma.empty;

    const orderBy =
      filter.sort === 'score'
        ? Prisma.sql`ORDER BY (reports.upvote_count - reports.downvote_count) DESC, reports.created_at DESC, reports.id DESC`
        : Prisma.sql`ORDER BY reports.created_at DESC, reports.id DESC`;

    const rows = await this.prisma.$queryRaw<
      (ReportDetailRow & { distanceMeters: number | null })[]
    >`
      SELECT
        reports.id,
        ST_Y(reports.location) AS lat,
        ST_X(reports.location) AS lng,
        reports.severity,
        reports.category,
        reports.description,
        reports.photo_path AS "photoPath",
        reports.status,
        reports.confirm_count AS "confirmCount",
        reports.fixed_count AS "fixedCount",
        reports.still_there_count AS "stillThereCount",
        reports.complaint_count AS "complaintCount",
        reports.upvote_count AS "upvoteCount",
        reports.downvote_count AS "downvoteCount",
        reports.created_at AS "createdAt",
        provinces.name AS "provinceName",
        provinces.slug AS "provinceSlug",
        ${distanceExpr} AS "distanceMeters"
      FROM reports
      LEFT JOIN provinces ON provinces.id = reports.province_id
      WHERE reports.status NOT IN ('deleted', 'hidden')
      ${cursorFilter}
      ${orderBy}
      LIMIT ${filter.limit}
    `;
    return rows.map((row) => ({
      ...mapDetailRow(row),
      distanceMeters: row.distanceMeters,
    }));
  }

  /** Kullanıcının kendi bildirimleri, keyset sayfalama ile. Hidden dahil
   *  (sahibi kendi şikayet edilmiş içeriğini görebilmeli), deleted hariç. */
  async listByUser(filter: {
    userId: string;
    limit: number;
    cursorCreatedAt?: Date;
    cursorId?: string;
  }): Promise<ReportDetail[]> {
    const cursorFilter =
      filter.cursorCreatedAt && filter.cursorId
        ? Prisma.sql`AND (reports.created_at, reports.id) < (${filter.cursorCreatedAt}, ${filter.cursorId}::uuid)`
        : Prisma.empty;

    const rows = await this.prisma.$queryRaw<ReportDetailRow[]>`
      SELECT
        reports.id,
        ST_Y(reports.location) AS lat,
        ST_X(reports.location) AS lng,
        reports.severity,
        reports.category,
        reports.description,
        reports.photo_path AS "photoPath",
        reports.status,
        reports.confirm_count AS "confirmCount",
        reports.fixed_count AS "fixedCount",
        reports.still_there_count AS "stillThereCount",
        reports.complaint_count AS "complaintCount",
        reports.upvote_count AS "upvoteCount",
        reports.downvote_count AS "downvoteCount",
        reports.created_at AS "createdAt",
        provinces.name AS "provinceName",
        provinces.slug AS "provinceSlug"
      FROM reports
      LEFT JOIN provinces ON provinces.id = reports.province_id
      WHERE reports.user_id = ${filter.userId}::uuid
        AND reports.status != 'deleted'
      ${cursorFilter}
      ORDER BY reports.created_at DESC, reports.id DESC
      LIMIT ${filter.limit}
    `;
    return rows.map(mapDetailRow);
  }

  async findStatusById(id: string): Promise<ReportStatus | null> {
    const rows = await this.prisma.$queryRaw<{ status: ReportStatus }[]>`
      SELECT status FROM reports WHERE id = ${id}::uuid LIMIT 1
    `;
    return rows[0]?.status ?? null;
  }

  /** Idempotent vote insert; returns null if the (report, user, type) vote already existed. */
  async vote(
    reportId: string,
    userId: string,
    type: VoteType,
    thresholds: { fixed: number; hide: number },
  ): Promise<{ alreadyVoted: boolean; report: ReportDetail }> {
    const countColumn = VOTE_COUNT_COLUMN[type];
    return this.prisma.$transaction(async (tx) => {
      const inserted = await tx.$queryRaw<{ id: string }[]>`
        INSERT INTO votes (id, report_id, user_id, type)
        VALUES (gen_random_uuid(), ${reportId}::uuid, ${userId}::uuid, ${type}::vote_type)
        ON CONFLICT (report_id, user_id, type) DO NOTHING
        RETURNING id
      `;
      const alreadyVoted = inserted.length === 0;

      if (!alreadyVoted) {
        await tx.$executeRaw`
          UPDATE reports SET ${Prisma.raw(countColumn)} = ${Prisma.raw(countColumn)} + 1, updated_at = now()
          WHERE id = ${reportId}::uuid
        `;
        if (type === 'fixed') {
          await tx.$executeRaw`
            UPDATE reports SET status = 'fixed', updated_at = now()
            WHERE id = ${reportId}::uuid AND status = 'active' AND fixed_count >= ${thresholds.fixed}
          `;
        } else if (type === 'complaint') {
          await tx.$executeRaw`
            UPDATE reports SET status = 'hidden', updated_at = now()
            WHERE id = ${reportId}::uuid AND status = 'active' AND complaint_count >= ${thresholds.hide}
          `;
        }
      }

      const rows = await tx.$queryRaw<ReportDetailRow[]>`
        SELECT
          reports.id,
          ST_Y(reports.location) AS lat,
          ST_X(reports.location) AS lng,
          reports.severity,
          reports.category,
          reports.description,
          reports.photo_path AS "photoPath",
          reports.status,
          reports.confirm_count AS "confirmCount",
          reports.fixed_count AS "fixedCount",
          reports.still_there_count AS "stillThereCount",
          reports.complaint_count AS "complaintCount",
          reports.upvote_count AS "upvoteCount",
          reports.downvote_count AS "downvoteCount",
          reports.created_at AS "createdAt",
          provinces.name AS "provinceName",
          provinces.slug AS "provinceSlug"
        FROM reports
        LEFT JOIN provinces ON provinces.id = reports.province_id
        WHERE reports.id = ${reportId}::uuid
      `;
      return { alreadyVoted, report: mapDetailRow(rows[0]) };
    });
  }
}

interface ReportDetailRow {
  id: string;
  lat: number;
  lng: number;
  severity: number;
  category: ReportCategory;
  description: string | null;
  photoPath: string | null;
  status: ReportStatus;
  confirmCount: number;
  fixedCount: number;
  stillThereCount: number;
  complaintCount: number;
  upvoteCount: number;
  downvoteCount: number;
  createdAt: Date;
  provinceName: string | null;
  provinceSlug: string | null;
}

function mapDetailRow(row: ReportDetailRow): ReportDetail {
  return { ...row };
}
