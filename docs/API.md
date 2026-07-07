# CukurMap — API Sözleşmesi

Base: `/api/v1` · Auth: `Authorization: Bearer <JWT>` (anonim, cihaz bazlı)
Validation: class-validator + global ValidationPipe(whitelist) · Rate limit: @nestjs/throttler
(POST /reports için sıkı, ör. 5/dk).

## Auth & Kullanıcı
- `POST /auth/anonymous` `{deviceId}` → `{token, user:{id, nickname}}` — kayıt-veya-giriş
- `GET /users/me` → `{id, nickname, reportCount, confirmsReceived, fixedReportCount, confirmsGiven}`
  (rozetler bu istatistiklerden istemci tarafında hesaplanır, ayrı bir alan değil)
- `PATCH /users/me` `{nickname}` (max 40 karakter)
- `GET /users/me/reports` → kendi bildirimleri

## Bildirimler
- `POST /reports` (multipart) — `photo?` + `lat, lng` + `severity(1-4)` + `category?` + `description?(≤280)`
  - 50m / 24saat mükerrer kontrolü (`ST_DWithin`) → **409** + `{nearbyReportId}` (istemci "doğrula?" önerir)
  - Foto pipeline: multer memory (max 10MB) → sharp decode (gerçek görüntü doğrulaması) →
    rotate() → resize ≤1280px → WebP q~70 → `uploads/<uuid>.webp`. EXIF/GPS otomatik silinir.
- `GET /reports?bbox=minLng,minLat,maxLng,maxLat&severity=&status=&since=` → hafif marker listesi
  `[{id, lat, lng, severity, status, photoUrl}]`, limit'li (default 500)
- `GET /reports/:id` → detay: fotoURL, açıklama, kategori, sayaçlar, tarih, il
- `GET /reports/feed?sort=recent|score&limit=&lat=&lng=&cursorCreatedAt=&cursorId=&cursorScore=`
  → Twitter-vari feed, keyset sayfalama (`nextCursor: {createdAt, id, score} | null`).
  `sort=recent` (varsayılan) oluşturulma zamanına göre; `sort=score` net oya
  (`upvoteCount - downvoteCount`) göre sıralar. `lat`/`lng` verilirse her öğede
  `distanceMeters` döner. `status=hidden|deleted` olan bildirimler feed'de görünmez.
- `POST /reports/:id/votes` `{type: confirm|fixed|still_there|complaint|upvote|downvote}` — idempotent
  (unique constraint); eşik aşımı status'u aynı transaction'da günceller.
  **Bilinen sınırlama:** oy değiştirme/geri alma yok — bir kullanıcı bir rapora aynı
  tip oyu sadece bir kez verebilir (toggle/undo gelecekte ele alınacak).

## İstatistik
- `GET /stats/cities?sort=total|per_capita` (varsayılan `total`) → Çukur Ligi, son 7 gün
  penceresi (`status != deleted`, `created_at >= now() - 7 gün`), rapor sayısına (veya
  `per_capita` için nüfusa bölünmüş orana) göre azalan sıralı, en fazla 20 il:
  `[{name, slug, reportCount, resolvedPct, verifications}]`
  (`resolvedPct`: pencere içindeki raporların `fixed` olma yüzdesi; `verifications`: toplam
  `confirmCount`). Hiç raporu olmayan iller listede yer almaz.
- `GET /stats/cities/:slug` → toplam, çözülme oranı, "en efsane çukur" — henüz implement edilmedi
- `GET /stats/weekly` → haftalık özet — henüz implement edilmedi

## Admin (X-Admin-Token header, env'den, timing-safe compare)
- `DELETE /admin/reports/:id`
- `POST /admin/users/:id/ban`

## Statik
- `GET /uploads/<uuid>.webp` — UUID dosya adı, path traversal imkânsız
