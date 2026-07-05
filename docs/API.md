# CukurMap — API Sözleşmesi

Base: `/api/v1` · Auth: `Authorization: Bearer <JWT>` (anonim, cihaz bazlı)
Validation: class-validator + global ValidationPipe(whitelist) · Rate limit: @nestjs/throttler
(POST /reports için sıkı, ör. 5/dk).

## Auth & Kullanıcı
- `POST /auth/anonymous` `{deviceId}` → `{token, user:{id, nickname}}` — kayıt-veya-giriş
- `GET /users/me` → profil + istatistik (bildirim sayısı, alınan doğrulama, rozetler)
- `PATCH /users/me` `{nickname}` (max 40 karakter)
- `GET /users/me/reports` → kendi bildirimleri

## Bildirimler
- `POST /reports` (multipart) — `photo?` + `lat, lng` + `severity(1-4)` + `category?` + `description?(≤280)`
  - 50m / 24saat mükerrer kontrolü (`ST_DWithin`) → **409** + `{nearbyReportId}` (istemci "doğrula?" önerir)
  - Foto pipeline: multer memory (max 10MB) → sharp decode (gerçek görüntü doğrulaması) →
    rotate() → resize ≤1280px → WebP q~70 → `uploads/<uuid>.webp`. EXIF/GPS otomatik silinir.
- `GET /reports?bbox=minLng,minLat,maxLng,maxLat&severity=&status=&since=` → hafif marker listesi
  `[{id, lat, lng, severity, status}]`, limit'li (default 500)
- `GET /reports/:id` → detay: fotoURL, açıklama, kategori, sayaçlar, tarih, il
- `POST /reports/:id/votes` `{type: confirm|fixed|still_there|complaint}` — idempotent
  (unique constraint); eşik aşımı status'u aynı transaction'da günceller

## İstatistik (Faz 2)
- `GET /stats/cities?sort=total|per_capita` → Çukur Ligi
- `GET /stats/cities/:slug` → toplam, çözülme oranı, "en efsane çukur"
- `GET /stats/weekly` → haftalık özet

## Admin (X-Admin-Token header, env'den, timing-safe compare)
- `DELETE /admin/reports/:id`
- `POST /admin/users/:id/ban`

## Statik
- `GET /uploads/<uuid>.webp` — UUID dosya adı, path traversal imkânsız
