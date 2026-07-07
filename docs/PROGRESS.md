# PROGRESS — Oturumlar Arası Devir

## Durum: Faz 3 "Yayına hazırlık" Track A TAMAMLANDI ✅ (2026-07-07) — sonraki: Track B (kullanıcı: domain satın al, VPS deploy, App Store Connect kaydı, signing+upload, screenshot'lar)

### Bitti (Faz 3 — Yayına Hazırlık, Track A, 2026-07-07)
- [x] Bundle ID rename: iOS `com.example.cukurMap` → `com.cukurmap.app` (project.pbxproj 6 girdi),
      Android applicationId+namespace → `com.cukurmap.app`, MainActivity.kt paket taşındı
      (kotlin/com/cukurmap/app/)
- [x] App ikonu: PIL ile programatik üretildi (koyu #16150F zemin + amber çatlaklı çukur motifi,
      scratchpad gen_icon.py) → app/assets/icon/{icon,icon_foreground}.png; flutter_launcher_icons
      ^0.14.2 ile iOS+Android tüm boyutlar üretildi (adaptive icon dahil). Fonksiyonel v1 —
      istenirse sonra tasarımcı işiyle değiştirilir.
- [x] Native splash: flutter_native_splash ^2.4.4, koyu #16150F + ikon (android_12 dahil)
- [x] Sürüş güvenliği uyarısı: Strings.drivingWarning* onboarding'e bağlandı — "Başla" butonuna
      basınca barrierDismissible:false dialog, "Söz, sürerken kullanmam" onayı olmadan geçilmez
- [x] Privacy Policy: api/public/privacy.html (KVKK, EXIF silme, anonim kimlik, silme talebi;
      PRIVACY_CONTACT_EMAIL placeholder — kullanıcı gerçek e-posta koymalı!); main.ts'te
      useStaticAssets(public) ile kökten servis — canlı smoke: GET /privacy.html → 200 ✓
- [x] Prod deploy altyapısı: api/Dockerfile (multi-stage node:22-slim, prisma generate build
      stage'de, .prisma client final'e kopyalanır), api/.dockerignore,
      docker/docker-compose.prod.yml (db+api loopback-only + tek seferlik `migrate` servisi
      [profile: tools] — prisma migrate deploy + seed), docker/.env.prod.example.
      **Karar: nginx/certbot container YOK** — VPS'te Plesk zaten 80/443'ü yönetiyor; SSL +
      reverse proxy Plesk üzerinden, api sadece 127.0.0.1:${API_PORT} dinler.
- [x] **start:prod bug fix**: nest build çıktısı dist/src/main.js'e gidiyordu (prisma/seed.ts
      derlemeye giriyordu) → `node dist/main` hiç çalışmıyormuş; tsconfig.build.json exclude'una
      "prisma" eklendi, dist/main.js artık kökte. (e2e/dev bunu yakalamıyordu çünkü ikisi de
      ts üzerinden koşuyor.)
- [x] Store metadata: docs/STORE_LISTING.md (isim/subtitle/keywords/description/what's new,
      App Privacy formu beyan tablosu, age rating UGC cevapları, İngilizce review notes,
      screenshot planı 5-6 kare + boyutlar)
- [x] Version bump: pubspec 0.1.0+1 → 1.0.0+1
- [x] Doğrulama: flutter analyze ✓ (0 issue), flutter test ✓, `flutter build ios --release
      --no-codesign` ✓ (20.1MB), api build/lint ✓, e2e 18/18 ✓, compose config ✓,
      privacy.html canlı 200 ✓, Docker image build (sonuç aşağıda güncellenir)

### Track B — Kullanıcının yapacağı yayın adımları (sırayla)
1. **Domain satın al** (registrar) → DNS A kaydını VPS IP'sine yönlendir; Plesk'te subdomain
   (ör. api.DOMAIN) + Let's Encrypt SSL + 127.0.0.1:3000'e reverse proxy
2. **VPS deploy**: repo'yu VPS'e çek, `cp docker/.env.prod.example docker/.env.prod` doldur
   (openssl rand -hex 32 ×3), `docker compose -f docker-compose.prod.yml --env-file .env.prod
   up -d --build`, ilk kurulumda `... run --rm migrate`
3. **privacy.html'deki PRIVACY_CONTACT_EMAIL placeholder'ını gerçek e-postayla değiştir**
4. **Apple Developer portal**: `com.cukurmap.app` bundle ID register + App Store Connect'te
   yeni app kaydı (docs/STORE_LISTING.md'deki metinlerle)
5. **Release build + upload**: `flutter build ipa --release
   --dart-define=API_BASE_URL=https://api.DOMAIN/api/v1` → Xcode Organizer/Transporter ile upload
6. **Screenshot'lar**: simulator/cihazda STORE_LISTING.md'deki 5-6 kare planına göre
7. Store metadata + App Privacy formu doldur → Submit for Review

## Önceki durum: UI Test Geri Bildirimi Düzeltmeleri (8 madde, 5 faz) TAMAMLANDI ✅ (2026-07-06)

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

### UI Reskin — Faz 1 Üzerine (2026-07-06)
- Design kaynağı: 8 ekran iOS mockup (Claude Design, CukurMap.dc.html), DesignSync MCP ile çekildi
- Yeni görsel dil: ısıl krem light tema default (#F5F3EF arka, #16150F metin); Camera/Onboarding/Çukur Ligi
  ekranları kasıtlı dark (#16150F) palette; google_fonts ile Space Grotesk (başlık), Hanken Grotesk (body),
  JetBrains Mono (etiket); severity palet yeşil/altın/turuncu/kırmızıya döndü; labels reword
  ("Hafif tümsek" → "Kayıp aracımız var" vs.)
- Yeni dosyalar: lib/core/theme.dart (yeniden yazıldı), lib/core/widgets/ (severity_badge.dart,
  pill_button.dart, adaptive_bottom_nav.dart), lib/core/prefs_keys.dart, lib/features/onboarding/
  onboarding_screen.dart (first-launch, has_seen_onboarding shared_preferences flag), lib/features/reports/
  report_success_screen.dart (snackbar+pop yerine)
- lib/core/router.dart: `buildRouter(String initialLocation)` refaktörü — main.dart shared_preferences'ı
  okuyup '/onboarding' vs '/camera' karar verir; yeni rotalar /onboarding ve /reports/success
- Restyle (logic aynı): camera_screen.dart, report_form_screen.dart, map_screen.dart (status filtre row + geolocator
  locate button artık canlı), report_detail_sheet.dart (stat tile'lar real confirmCount/stillThereCount/fixedCount),
  detail sheet renk kodlaması severity'ye göre
- stats_screen.dart: Çukur Ligi leaderboard full UI mockup'tan (statik mock data _mockCityLeague — Faz 2'de real
  city-stats API bağlanacak)
- profile_screen.dart: nickname real (authProvider), badges ve "Bildirimlerim" report geçmişi statik mock
  (Faz 2'de per-user stats/history API)
- Paket eklemeler: google_fonts, shared_preferences (pubspec.yaml)
- Doğrulama: `flutter analyze` ✓ (0 issue), `flutter test` ✓ (widget_test.dart '/camera'de direkt router build),
  `flutter build ios --simulator --no-codesign` ✓. **In-app visual/cihaz testi Claude tarafından YAPıLMADI**
  (kural), kullanıcı simulator/cihazda onboarding → kamera → bildir → success ekranı → harita filtreleri/locate →
  lig/profili test etmeli
- League ve Profile mock'ları açık placeholder (Faz 2 API'yi bekliyor)
- 4 commit yapıldı ve pushed (design tokens + widgets, onboarding + success, restyle camera/form/map/detail,
  lig/profil UI)

### UI Test Geri Bildirimi Düzeltmeleri (2026-07-06)
Kullanıcı simulator'de 8 madde geri bildirim (overflow, form layout, badges, settings, feed, geofence) → 5 faz plan + implement + verify çalıştı. Tüm checks geçti: flutter analyze/test ✓, npx tsc ✓, npm lint ✓, npm e2e ✓.

- [x] **Faz 0 (quick wins)**: profile_screen.dart _HistoryRow sağ-taşma bug (severity label + date → Text Flexible + ellipsis); report_form_screen.dart açıklama alanı form üstüne taşı, severity kartları küçült (childAspectRatio 2.7→3.3)
- [x] **Faz 1 (harita pinleri + fotoğraf)**: backend reports.repository listByBbox photo_path select, photoPathToUrl() helper; frontend ReportMarker.photoUrl, cached_network_image; _MapPin teardrop 26→18px, box 36→28, thumbnail küçük circular (severity halka) yok'sa eski teardrop; docs/API.md güncelle
- [x] **Faz 2 (badges real stats)**:  backend users.service profile() fixedReportCount + confirmsGiven; frontend yeni users slice (users_api/userProfileProvider), badge_catalog 8 badge (İlk Çukur/10/50/100/Mahalle Bekçisi/Belediye/Güvenilir/Viral), profile_screen real values (mockHistory hala mock, GET /users/me/reports yok); strings.dart badge yazıları
- [x] **Faz 3 (Settings ekranı)**:  yeni settings_screen (notification toggle geofence, nickname PATCH /users/me + AuthNotifier.updateNickname, app version package_info_plus), router /settings, profile gear button, prefs_keys.dart geofenceNotificationsEnabled
- [x] **Faz 4 (Feed + upvote/downvote — büyük)**: Prisma migration upvote/downvote VoteType + upvote_count/downvote_count columns (migration_lock.toml eksikti, oluşturuldu); backend listFeed keyset pagination (recency + popularity sort), ST_Distance distanceMeters, QueryFeedDto; ReportDetail upvote/downvoteCount (indentation bug: vote-transaction SELECT derin, replace_all miss → e2e catch); GET /reports/feed (feed önce, avoid ':id' parse); **design: no vote undo** (idempotent insert-only, unique constraint, Faz 4+ backlog); e2e feed+idempotency tests (18 toplam); frontend VoteType upvote/downvote, FeedItem/Cursor/Page/Sort report.dart'a, ReportsApi.getFeed, feed slice (hand-rolled Notifier, AsyncNotifier değil, append), feed_item_card/feed_screen (infinite-scroll, pull-refresh, sort toggle); 5. nav tab "Akış", dark-tabs index {0,2}→{0,3}
- [x] **Faz 5 (foreground geofence + "ben de gördüm" behind)**:  **bilinçli scope**: foreground-only (Timer 90s, resumed/paused lifecycle), native bg (iOS region/Android service) sonraki faz TODO; geofence_service GET /reports bbox ~1.5km, 150m'de local-notify + deep-link, dedup PrefsKeys.geofenceNotifiedReportIds; flutter_local_notifications; router appRouter global (plugin callback tree dışı), new /reports/:id rota; report_detail_route_screen wrapper; report_detail_sheet promptConfirm param, "ben de gördüm" sadece promptConfirm:true (map-pin path unchanged), others (fixed/stillThere/complaint) untouched; _TabShell StatefulWidget+WidgetsBindingObserver (geofence lifecycle); **Riverpod bug**: ref.read() dispose'da → initState cache; Android POST_NOTIFICATIONS; iOS local-notify runtime; yeni dependencies (cached_network_image, package_info_plus, flutter_local_notifications); **cihaz testleri yapılamaz**: geofence trigger, notification permission, tap deep-link — simulator/device simulated location ile manuel test

Commit notu: bu oturumda "6 commit push edildi" diye not düşülmüştü ama gerçekte hiçbiri
commit'lenmemişti (working tree'de kaldı) — 2026-07-07 oturumunda fark edilip yayın hazırlığı
commit'leriyle birlikte toplandı.

### Bilinen sorunlar / notlar
- Bu Mac'te Android SDK YOK → APK build doğrulanamadı (iOS build ✓). Android'i kullanıcı test eder;
  uygulama önce iOS'ta yayınlanacak, Android doğrulaması gerekmiyor. Android manifest izinleri eklendi
  ama build/test doğrulanmadı.
- Cihazda test: `flutter run --dart-define=API_BASE_URL=http://MAC_IP:3000/api/v1` (fiziksel cihaz için)
- Kamera + konum izinleri gerektiren gerçek uçtan uca akış (çekim → bildir → haritada görme) simulator/cihazda
  henüz kullanıcı tarafından denenmedi — flutter test platform channel kısıtı yüzünden bunu kapsamıyor.
  Fiziksel cihaz/iOS simulator'de e2e testi yapması gerekir. Aynı şekilde geofence triggering, notification permission
  prompts, tap deep-link behavior da cihaz test'i gerekir.
- Geofencing: bu oturumda foreground-only (Timer 90s, resumed/paused) uygulandı. **Native background geofencing**
  (iOS region monitoring / Android geofencing service) deliberate future phase — clear upgrade path, `// TODO(gelecek faz)`
  comment'i geofence_service.dart'ta; settings toggle'ı zaten yerinde, just needs service impl.
- Oylama: upvote/downvote + tüm vote types (confirm/fixed/stillThere/complaint) için **no toggle/undo** policy — 
  idempotent insert-only, unique constraint re-vote engeller. Undo akışı Faz 4+ backlog'da.
- Profile "Bildirimlerim" (_mockHistory): hala statik mock, `GET /users/me/reports` endpoint'i yok. Faz 2+ scope'u.
- Reports.repository.ts indentation bug: vote-transaction SELECT blok daha derinde, replace_all silince missed.
  tsc/lint catch etmedi, e2e test aldı — reminder: analyze yeterli değil, test çalıştır.
- Riverpod bug (this session): `ref.read()` dispose() içinde → bad state. Fixed by caching in initState.
  **flutter test** bunu aldı; static analysis'te gözükmedi.
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
2. **Manuel cihaz/simulator test** (Claude yapamaz):
   - Kamera: çekim + fotoğraf seçim + permission prompt ✓
   - Geofencing: simulator'de simulated location set, <150m report'a yaklaş → notification + tap deep-link → detail sheet ✓ (geofence toggle settings'de on)
   - Feed: "Akış" tab load + infinite scroll + pull-refresh + Yeni/Popüler sort toggle ✓
   - Settings: nickname edit + notification toggle state persist ✓
3. Test'ler + lint hep geçiş mi kontrol et: `flutter analyze`, `flutter test`, API e2e `npm run test:e2e`
4. Sonraki faz kararı (öncelik sırası):
   - **Native bg geofencing**: iOS region monitoring + Android geofencing service (TODO comment hazır, ~Faz 6?)
   - **Real report history**: `GET /users/me/reports` + pagination; profile "Bildirimlerim" real data, test gerek
   - **Badge Viral criteria**: upvote threshold (e.g. 50+) once data gathered; now locked as design placeholder
   - **Vote undo/toggle**: all vote types idempotent-insert-only; undo flow Faz 4+ backlog
   - **Lig stats real API**: city-stats backend + frontend real leaderboard (currently mock _mockCityLeague)
   - **Other**: form validation msgs, error handling UX, photo carousel in detail (if time), etc.
5. Seçilen faz için plan doc'ı (brief section) yazıp başla
