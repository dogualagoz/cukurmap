-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "postgis";

-- CreateEnum
CREATE TYPE "report_category" AS ENUM ('cukur', 'bozuk_asfalt', 'rogar', 'kasis', 'diger');

-- CreateEnum
CREATE TYPE "report_status" AS ENUM ('active', 'fixed', 'hidden', 'deleted');

-- CreateEnum
CREATE TYPE "vote_type" AS ENUM ('confirm', 'fixed', 'still_there', 'complaint');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "device_hash" TEXT NOT NULL,
    "nickname" VARCHAR(40) NOT NULL,
    "is_banned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "provinces" (
    "id" SMALLINT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "hashtag" TEXT NOT NULL,
    "population" INTEGER NOT NULL,
    "boundary" geometry(MultiPolygon,4326) NOT NULL,

    CONSTRAINT "provinces_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "location" geometry(Point,4326) NOT NULL,
    "province_id" SMALLINT,
    "severity" SMALLINT NOT NULL,
    "category" "report_category" NOT NULL DEFAULT 'cukur',
    "description" VARCHAR(280),
    "photo_path" TEXT,
    "status" "report_status" NOT NULL DEFAULT 'active',
    "confirm_count" INTEGER NOT NULL DEFAULT 0,
    "fixed_count" INTEGER NOT NULL DEFAULT 0,
    "still_there_count" INTEGER NOT NULL DEFAULT 0,
    "complaint_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "votes" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" "vote_type" NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "votes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_device_hash_key" ON "users"("device_hash");

-- CreateIndex
CREATE UNIQUE INDEX "provinces_slug_key" ON "provinces"("slug");

-- CreateIndex
CREATE INDEX "reports_province_id_status_idx" ON "reports"("province_id", "status");

-- CreateIndex
CREATE INDEX "reports_user_id_idx" ON "reports"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "votes_report_id_user_id_type_key" ON "votes"("report_id", "user_id", "type");

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_province_id_fkey" FOREIGN KEY ("province_id") REFERENCES "provinces"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "votes" ADD CONSTRAINT "votes_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "votes" ADD CONSTRAINT "votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- Spatial GIST indexes (hand-written: Prisma cannot express these)
CREATE INDEX "provinces_boundary_gist" ON "provinces" USING GIST ("boundary");
CREATE INDEX "reports_location_gist" ON "reports" USING GIST ("location");

-- Severity is a 1-4 scale
ALTER TABLE "reports" ADD CONSTRAINT "reports_severity_range" CHECK ("severity" BETWEEN 1 AND 4);
