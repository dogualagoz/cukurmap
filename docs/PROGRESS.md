# PROGRESS — Oturumlar Arası Devir

## Durum: Faz 0 TAMAMLANDI ✅ (2026-07-06)

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

### Kaldı (Faz 1 — sonraki oturum)
- [ ] POST /reports + foto pipeline (sharp: decode→rotate→≤1280px→WebP, EXIF silinir) + 50m/24s mükerrer kontrolü
- [ ] GET /reports (bbox) + GET /reports/:id + POST /reports/:id/votes (eşik geçişleri)
- [ ] Flutter: kamera akışı (camera paketi) → önizleme (pin sürükleme, tehlike seviyesi) → bildir
- [ ] Flutter: harita (flutter_map + clustering + filtreler + detay sheet + oylama)
- [ ] Faz 1 paketleri eklenecek: camera, geolocator, flutter_map, flutter_map_marker_cluster, latlong2 (+izin konfigürasyonları: iOS Info.plist kamera/konum, Android manifest)

### Bilinen sorunlar / notlar
- Bu Mac'te Android SDK YOK → APK build doğrulanamadı (iOS build ✓). Android'i kullanıcı test eder.
- Cihazda test: `flutter run --dart-define=API_BASE_URL=http://MAC_IP:3000/api/v1` (fiziksel cihaz için)
- Dev secrets api/.env ve docker/.env'de (gitignore'lu, openssl rand ile üretildi). VPS deploy'da yenileri üretilecek.
- Prisma migrate dev, postgis image'ının hazır extension'ı yüzünden drift/reset isteyebilir;
  yeni migration akışı: `prisma migrate diff` ile SQL üret → migrations klasörüne koy → `prisma migrate deploy`.
- İl nüfusları yaklaşık TÜİK 2023; hassasiyet lig normalizasyonu için yeterli.

### Sonraki oturumun ilk adımı
1. `docker compose -f docker/docker-compose.yml up -d` (DB)
2. Faz 1'e API tarafından başla: sharp kurulumu + POST /reports (docs/API.md sözleşmesine göre)
