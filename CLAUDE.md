# CukurMap

Crowdsourced çukur ihbar uygulaması. Flutter (app/) + NestJS/PostgreSQL/PostGIS/Prisma (api/).

## Kaynaklar (gerektiğinde oku, hepsini birden yükleme)
- Proje brief: docs/BRIEF.md
- İlerleme/devir: docs/PROGRESS.md ← her oturum başında OKU, her faz sonunda GÜNCELLE
- Veri modeli: docs/SCHEMA.md · API sözleşmesi: docs/API.md

## Kurallar
- Plan onayı olmadan büyük implementasyon yapma.
- Flutter: Riverpod + go_router. Backend: NestJS + Prisma (geo sorguları parametrik raw SQL, repository içinde izole).
- Tüm UI metinleri app/lib/core/strings.dart içinde; ton: mizahi, küfürsüz, kimseyi hedef göstermez.
- Fotoğraf upload'ında EXIF GPS her zaman silinir (sharp re-encode, withMetadata KULLANMA).
- Secrets yalnız env'de; .env asla commit'lenmez (.env.example güncel tutulur).
- Commit: Conventional Commits, İngilizce. UI metinleri Türkçe. Her önemli adımda commit + push.
- Testleri ve lint'i değişiklik sonrası çalıştır; kırık bırakma.
- Uygulama içi ekran görüntüsü / cihaz testi DENEME — kullanıcı kendisi yapar.
- Keşif/araştırma işlerini subagent'a devret (explorer), ana context'i temiz tut.

## Komutlar
- api: `cd api && npm run start:dev` · test: `npm test` · db: `docker compose -f docker/docker-compose.yml up -d`
- app: `cd app && flutter run` · test: `flutter test` · analyze: `flutter analyze`
