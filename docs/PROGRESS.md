# PROGRESS — Oturumlar Arası Devir

## Durum: Faz 1 API + Flutter TAMAMLANDI ✅ (2026-07-06) — sonraki: cihaz e2e testi + Faz 2 planlama

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

### Bitti (Faz 1 — Flutter)
- [x] Paketler: camera ^0.11.0+2, geolocator ^13.0.2, permission_handler ^11.3.1, flutter_map ^7.0.2,
      flutter_map_marker_cluster ^1.4.0, latlong2 ^0.9.1. iOS: Info.plist'e NSCameraUsageDescription +
      NSLocationWhenInUseUsageDescription. Android: manifest'e CAMERA + ACCESS_FINE_LOCATION izinleri.
- [x] Reports domain: app/lib/features/reports/models/report.dart (ReportCategory/ReportStatus/VoteType
      enum'ları + wireName mapping; ReportMarker, ReportDetail, ReportConflictException modelleri)
- [x] Reports API client: app/lib/features/reports/data/reports_api.dart (createReport multipart+409
      nearbyReportId yakalama, getReports bbox query, getReport, vote) + reportsApiProvider,
      ReportsQuery (Dart record), reportMarkersProvider, reportDetailProvider (autoDispose.family)
- [x] apiOriginProvider: app/lib/core/api_client.dart'a eklendi (photoUrl relative→full URL)
- [x] Kamera: app/lib/features/camera/camera_screen.dart (gerçek canlı önizleme + çekim +
      "fotoğrafsız bildir" butonu, fallback ekran izin reddedilirse)
- [x] Rapor formu: app/lib/features/reports/report_form_screen.dart (fotoğraf önizleme, geolocator
      otomatik konum, flutter_map üzerinde merkez-pin sabit sürükleme deseniyle konum düzeltme,
      tehlike seviyesi 4 chip, kategori 5 seçenek, açıklama max280, POST /reports)
- [x] 409 mükerrer dialog: "bu çukur zaten bildirilmiş" → confirm oyu. 429/genel hatalar ayrı mesajlar.
- [x] Harita: app/lib/features/map/map_screen.dart (flutter_map + clustering, bbox debounce 400ms,
      severity filtre çubuğu, marker'lar rengiyle boyanıyor, tıklama → bottom sheet)
- [x] Detay sheet: app/lib/features/reports/report_detail_sheet.dart (fotoğraf, kategori, açıklama,
      il, tarih, 4 oylama butonu, her oy sonrası invalidate)
- [x] UI metinleri: app/lib/core/strings.dart'a ~35 yeni string (rapor formu, hatalar, mükerrer,
      filtre, oylama, kategori etiketleri); cameraComingSoon/mapComingSoon kaldırıldı.
- [x] Doğrulama: flutter analyze ✓ (0 issue), flutter test ✓ (widget_test.dart, kamera/permission
      platform channel kısıtı yüzünden sadece sekme render test), iOS `flutter build ios --simulator
      --no-codesign` ✓

### Bilinen sorunlar / notlar
- Bu Mac'te Android SDK YOK → APK build doğrulanamadı (iOS build ✓). Android'i kullanıcı test eder;
  uygulama önce iOS'ta yayınlanacak, Android doğrulaması gerekmiyor. Android manifest izinleri eklendi
  ama build/test doğrulanmadı.
- Cihazda test: `flutter run --dart-define=API_BASE_URL=http://MAC_IP:3000/api/v1` (fiziksel cihaz için)
- Kamera + konum izinleri gerektiren gerçek uçtan uca akış (çekim → bildir → haritada görme) simulator/cihazda
  henüz kullanıcı tarafından denenmedi — flutter test platform channel kısıtı yüzünden bunu kapsamıyor.
  Fiziksel cihaz/iOS simulator'de e2e testi yapması gerekir.
- flutter_map_marker_cluster ^1.4.1 arzu edildi ama pub.dev'de en yüksek uyumlu sürüm ^1.4.0 (^1.4.0 kullanılıyor).
- Rapor formunda "pin sürükleme" UX'i: ayrı draggable-marker paketi yerine "merkez-pin sabit, kullanıcı haritayı
  sürükler" (Uber/Google Maps tarzı) deseniyle çözüldü (flutter_map'in kendisinde draggable marker widget'ı yok).
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
2. Faz 1 e2e testi: iOS simulator'de veya fiziksel cihazda çekim → bildir → harita filter/oylama akışını test et
3. PROGRESS.md ve docs/API.md gözden geçir; Faz 2 (stats/lig/geçmiş raporlar) vs. cilalama işleri (UI tweak,
   error handling vb.) arasında karar ver, başla
