# PROGRESS — Oturumlar Arası Devir

## Durum: Faz 1 API tarafı TAMAMLANDI ✅ (2026-07-06) — sırada Flutter (kamera + harita)

### Bitti (Faz 0)
- [x] Plan onaylandı (kararlar: Prisma 6, Flutter stable, offline PostGIS il tespiti)
- [x] Monorepo: app/ (Flutter), api/ (NestJS), docker/, docs/, .claude/
- [x] docker-compose (postgis:16, sadece loopback) + Prisma şema + init migration
      (users/provinces/reports/votes, GIST indexler, severity CHECK)
- [x] 81 il seed: sınırlar (alpers/Turkey-Maps-GeoJSON, Apache-2.0), TÜİK 2023 nüfus,
      genitif hashtag üretimi (#EskişehirinÇukurları) — ST_Contains sanity check geçti
- [x] Anonim auth uçtan uca: POST /auth/anonymous (HMAC+pepper device hash, mizahi rumuz),
      JwtAuthGuard + ban kontrolü, GET/PATCH /users/me — e2e testler + canlı smoke geçti
- [x] Flutter iskeleti: stable 3.44.4, Riverpod + go_router, 4 sekme (kamera açılış),
      koyu tema/amber, strings.dart, device-UUID→JWT akışı + offline fallback
- [x] npm audit: 0 vulnerability (prisma 6.x pin, multer override ^2.1.2)
- [x] Doğrulama: api build/lint/e2e ✓, flutter analyze/test ✓, iOS debug build ✓

### Bitti (Faz 1 — API)
- [x] ReportsModule: POST /reports (multipart, sharp decode→rotate→≤1280px→WebP q70,
      EXIF/GPS otomatik silinir çünkü withMetadata hiç kullanılmıyor), 50m/24s ST_DWithin
      mükerrer kontrolü → 409 + nearbyReportId
- [x] GET /reports (bbox+severity+status+since filtreli marker listesi, limit 500),
      GET /reports/:id (detay: il, sayaçlar, fotoURL)
- [x] POST /reports/:id/votes: idempotent (unique constraint), FIXED_THRESHOLD/HIDE_THRESHOLD
      eşik geçişleri aynı transaction'da (reports.repository.ts, raw SQL izole)
- [x] GET /uploads/<uuid>.webp statik servis (useStaticAssets, global prefix dışında)
- [x] Rate limit: POST /reports 5/dk, POST /auth/anonymous 10/dk — ama artık **cihaz bazlı**
      (UserThrottlerGuard: JWT sub'a göre track eder, IP'ye göre değil — anonim auth NAT
      arkasındaki cihazları haksız yere birlikte throttle etmesin diye; token yoksa IP'ye düşer)
- [x] e2e: reports.e2e-spec.ts (16 test, tüm suite) — gerçek DB'ye karşı: create/dup/foto/
      bbox/detay/oy/eşik geçişi. Sabit cihaz havuzu (userA-D) kullanılıyor çünkü hem auth
      hem reports endpoint'i kasıtlı olarak rate-limitli; testler tekrar tekrar aynı DB'ye
      karşı çalıştırılabilir (beforeAll'da reports/votes TRUNCATE edilir)
- [x] Doğrulama: api build/lint/e2e ✓ (16/16), npm audit 0 vulnerability

### Kaldı (Faz 1 — Flutter, sonraki oturum)
- [ ] Flutter: kamera akışı (camera paketi) → önizleme (pin sürükleme, tehlike seviyesi) → bildir
- [ ] Flutter: harita (flutter_map + clustering + filtreler + detay sheet + oylama)
- [ ] Faz 1 paketleri eklenecek: camera, geolocator, flutter_map, flutter_map_marker_cluster, latlong2 (+izin konfigürasyonları: iOS Info.plist kamera/konum, Android manifest)
- [ ] app/lib tarafında reports API client'ı (multipart upload dahil) + Riverpod state

### Bilinen sorunlar / notlar
- Bu Mac'te Android SDK YOK → APK build doğrulanamadı (iOS build ✓). Android'i kullanıcı test eder;
  uygulama önce iOS'ta yayınlanacak, Android doğrulaması gerekmiyor.
- Cihazda test: `flutter run --dart-define=API_BASE_URL=http://MAC_IP:3000/api/v1` (fiziksel cihaz için)
- Dev secrets api/.env ve docker/.env'de (gitignore'lu, openssl rand ile üretildi). VPS deploy'da yenileri üretilecek.
- Prisma migrate dev, postgis image'ının hazır extension'ı yüzünden drift/reset isteyebilir;
  yeni migration akışı: `prisma migrate diff` ile SQL üret → migrations klasörüne koy → `prisma migrate deploy`.
- İl nüfusları yaklaşık TÜİK 2023; hassasiyet lig normalizasyonu için yeterli.
- Docker Desktop bu oturumda kapalıydı, `open -a Docker` ile başlatıldı — yeni oturumda
  db container ayakta değilse önce Docker Desktop'ın çalıştığından emin ol.
- reports.repository.ts'te tüm INSERT/UPDATE'ler `updated_at`'i elle `now()` ile set ediyor;
  Prisma'nın `@updatedAt` davranışı sadece client API'sinde otomatik, raw SQL'de yok.

### Sonraki oturumun ilk adımı
1. `docker compose -f docker/docker-compose.yml up -d` (DB) — Docker Desktop kapalıysa önce aç
2. Faz 1'e Flutter tarafından devam: camera + geolocator + flutter_map paketlerini ekle,
   docs/API.md'deki POST /reports sözleşmesine göre kamera→önizleme→bildir akışını kur
