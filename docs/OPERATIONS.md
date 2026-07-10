# Operasyon Notları (prod VPS)

## Deploy

```sh
cd docker
cp .env.prod.example .env.prod   # doldur: openssl rand -hex 32
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
# İlk kurulumda (ve her yeni migration'da):
docker compose -f docker-compose.prod.yml --env-file .env.prod run --rm migrate
```

- Seed idempotenttir (il kayıtları plaka koduna upsert edilir); `migrate`
  servisini tekrar çalıştırmak güvenlidir.
- Plesk nginx `${DOMAIN}` için reverse proxy + Let's Encrypt yönetir; api
  yalnız `127.0.0.1:${API_PORT}` dinler.

## Healthcheck

- `api` servisinin compose healthcheck'i `GET /api/v1/health`'i (DB `SELECT 1`
  dahil) 30 sn'de bir yoklar. Durum: `docker compose -f docker-compose.prod.yml ps`.

## Yedekleme

`docker/backup.sh`: Postgres dump'ı (`pg_dump | gzip`, container içinden) ve
uploads volume tar'ını alır, 14 günden eski yedekleri siler.

```sh
chmod +x docker/backup.sh
./docker/backup.sh                 # varsayılan hedef: ~/cukurmap-backups
```

Crontab (her gece 04:15):

```cron
15 4 * * * /path/to/cukur_map/docker/backup.sh /var/backups/cukurmap >> /var/log/cukurmap-backup.log 2>&1
```

Geri yükleme:

```sh
gunzip -c db_YYYYMMDD_HHMMSS.sql.gz | docker exec -i cukurmap-db-prod sh -c 'psql -U "$POSTGRES_USER" "$POSTGRES_DB"'
docker run --rm -v docker_uploads:/data -v "$PWD":/backup alpine tar xzf /backup/uploads_YYYYMMDD_HHMMSS.tar.gz -C /data
```

## Loglar

- API, hata durumlarını (>=400 yanıtlar) `HTTP` logger'ıyla stdout'a yazar:
  `docker logs -f cukurmap-api-prod`.
- Log seviyesi prod'da `error/warn/log` ile sınırlıdır (debug/verbose kapalı).
