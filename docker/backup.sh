#!/usr/bin/env sh
# CukurMap prod yedeği: Postgres dump + uploads volume tar'ı.
# Kullanım (VPS'te, docker/ dizininden): ./backup.sh [hedef-dizin]
# Crontab örneği için docs/OPERATIONS.md'ye bak.
set -eu

BACKUP_DIR="${1:-$HOME/cukurmap-backups}"
RETENTION_DAYS=14
STAMP="$(date +%Y%m%d_%H%M%S)"
DB_CONTAINER="cukurmap-db-prod"
UPLOADS_VOLUME="docker_uploads"

mkdir -p "$BACKUP_DIR"

# 1) Veritabanı: container içindeki pg_dump'ı kullan (sürüm uyumu garantili)
docker exec "$DB_CONTAINER" sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "$BACKUP_DIR/db_$STAMP.sql.gz"

# 2) Uploads volume'u: geçici bir container ile tar'la
docker run --rm -v "$UPLOADS_VOLUME":/data:ro -v "$BACKUP_DIR":/backup alpine \
  tar czf "/backup/uploads_$STAMP.tar.gz" -C /data .

# 3) Retention: eski yedekleri sil
find "$BACKUP_DIR" -name 'db_*.sql.gz' -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -name 'uploads_*.tar.gz' -mtime +"$RETENTION_DAYS" -delete

echo "OK: $BACKUP_DIR/db_$STAMP.sql.gz + uploads_$STAMP.tar.gz"
