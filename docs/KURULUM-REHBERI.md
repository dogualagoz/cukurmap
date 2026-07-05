# Claude Code Kurulum & Token Stratejisi — CukurMap Projesi

Hedef: **2 gün içinde kalan %30 Fable limitini** projenin en zor kısımlarına yakmak,
geri kalan her şeyi Sonnet/Haiku'ya devretmek, context'i şişirmeden ilerlemek.

---

## 1. Model Stratejisi (en kritik bölüm)

### Fable'a yaptırılacaklar (2 günlük pencere — öncelik sırasıyla)
1. **Plan mode'da tüm proje planı** (brief'i ver, plan çıkart, onayla) — plan mode
   read-only olduğu için implementasyona göre çok ucuzdur ve en yüksek kaldıraçlı iştir.
2. **Faz 0: iskelet** — monorepo, docker-compose, PostGIS, migration altyapısı,
   anonim auth uçtan uca.
3. **Faz 1'in zor parçaları:** fotoğraf pipeline (sharp + EXIF), bbox/PostGIS sorguları,
   harita clustering, kamera akışı.
4. Kalan limitle: Faz 2'nin mimarisini kurdurup implementasyonu Sonnet'e bırak.

### Sonnet'e bırakılacaklar
- CRUD endpoint'leri, UI ekranlarının çoğaltılması, istatistik ekranları, testler,
  metin/ton işleri, bugfix, Faz 3'ün tamamı.

### Pratik komutlar
```bash
claude --model fable        # Fable ile başla (model adını /model listesinden doğrula)
/model sonnet               # oturum içinde geçiş
```
Kural: **"Bu işi Sonnet yapabilir mi?" sorusunun cevabı evetse Fable'da yapma.**
Fable'ı sadece mimari kararlar, ilk çalışan sürüm ve Sonnet'in takıldığı yerlerde
"kurtarıcı" olarak kullan.

---

## 2. CLAUDE.md (proje köküne koy — kısa tut!)

CLAUDE.md her mesajda context'e girer; her satırı token yakar. 30-40 satırı geçmesin.
Detaylar `docs/` altında dursun, CLAUDE.md sadece referans versin:

```markdown
# CukurMap

Crowdsourced çukur ihbar uygulaması. Flutter (app/) + NestJS/PostgreSQL/PostGIS (api/).

## Kaynaklar (gerektiğinde oku, hepsini birden yükleme)
- Proje brief: docs/BRIEF.md
- İlerleme/devir: docs/PROGRESS.md  ← her oturum başında OKU, her faz sonunda GÜNCELLE

## Kurallar
- Plan onayı olmadan büyük implementasyon yapma.
- Flutter: Riverpod + go_router. Backend: NestJS + TypeORM/Prisma (karar: PROGRESS.md).
- Tüm UI metinleri app/lib/core/strings.dart içinde; ton: mizahi, küfürsüz,
  kimseyi hedef göstermez.
- Fotoğraf upload'ında EXIF GPS her zaman silinir.
- Commit: Conventional Commits. Türkçe UI, İngilizce kod/commit.
- Testleri ve lint'i değişiklik sonrası çalıştır; kırık bırakma.
- Keşif/araştırma gerektiren işleri subagent'a devret (Explore/general-purpose),
  ana context'i temiz tut.

## Komutlar
- api: docker compose up -d && npm run start:dev | test: npm test
- app: flutter run | test: flutter test | analyze: flutter analyze
```

---

## 3. Context / Token Tasarrufu

- **`/clear` > `/compact`:** Faz aralarında ve konu değişiminde `/clear` at. Compact
  bile token harcar; en ucuz context, hiç olmayan context'tir. Devirden önce
  Claude'a "PROGRESS.md'yi güncelle" de, sonra `/clear`.
- **`/compact` manuel kullan:** Otomatik compaction'ı beklemeden (%80 dolulukta
  tetiklenir), iş ortasında context şişince odaklı talimatla çalıştır:
  `/compact sadece mevcut fazın kararlarını ve açık işleri koru`.
- **`/context` ile ara ara doluluk kontrolü** yap; %60'ı geçtiyse toparlanma planla.
- **Uzun dosyaları yapıştırma:** "docs/BRIEF.md'nin 7. bölümünü oku" de; Claude
  gerektiği kadarını okur.
- **Tek oturumda tek faz.** Oturumları küçük ve amaçlı tut.
- Build/test çıktılarının tamamını değil, sadece hata kısmını tartıştır
  ("sadece failing testleri göster" gibi yönlendir).

---

## 4. Subagent'lar (.claude/agents/)

Subagent'lar kendi context pencerelerinde çalışır → ana oturumun context'ini
kirletmez, üstelik ucuz modele sabitlenebilir. Fable ana oturumdayken keşif işlerini
bunlara devret. Üç dosya oluştur:

**.claude/agents/explorer.md**
```markdown
---
name: explorer
description: Kod tabanında keşif, dosya/pattern arama, "X nerede tanımlı" tipi sorular. Salt okunur.
tools: Read, Grep, Glob
model: haiku
---
Kod tabanını ara ve KISA, madde madde rapor ver. Dosya yolu + satır referansı ver.
Kod bloklarını komple yapıştırma; sadece ilgili 3-5 satırı alıntıla.
```

**.claude/agents/test-runner.md**
```markdown
---
name: test-runner
description: Test ve lint çalıştırıp sadece hataları raporlar. Kod değiştirmez.
tools: Bash, Read
model: sonnet
---
İlgili test/lint komutlarını çalıştır. SADECE başarısız testleri ve hata mesajlarını
raporla; geçen testlerin çıktısını dahil etme. Düzeltme önerisi 1-2 cümleyi geçmesin.
```

**.claude/agents/doc-writer.md**
```markdown
---
name: doc-writer
description: PROGRESS.md güncelleme ve dokümantasyon işleri.
tools: Read, Write, Edit
model: haiku
---
docs/PROGRESS.md'yi güncelle: biten işler, kalan işler, bilinen sorunlar,
bir sonraki oturumun ilk adımı. Kısa ve maddeli yaz.
```

Kural: `model:` alanı sayesinde bu ajanlar Fable kotanı yemez.

---

## 5. Skills & Komutlar

- Mevcut skill'lerin (`conventional-commit`, `versioning`, `pre-deploy-check`)
  bu projede de çalışır; `pre-deploy-check`'i CukurMap docker düzenine uyarlamayı
  Sonnet'e yaptır (Fable'a değil).
- Yeni önerilen custom komut — **.claude/commands/handoff.md**:
```markdown
Oturumu kapatmadan önce: docs/PROGRESS.md'yi güncelle (doc-writer subagent'ını kullan),
commit atılmamış değişiklik varsa conventional commit ile commit'le,
sonra bana tek paragraf devir özeti ver.
```
  Kullanımı: her oturum sonunda `/handoff` → sonra `/clear` veya oturumu kapat.

---

## 6. settings.json önerisi (.claude/settings.json)

Sık kullanılan güvenli komutlara izin verip onay beklemelerini (ve her onayın
yarattığı gidip-gelme turlarını) azalt:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(npm test*)",
      "Bash(flutter analyze*)",
      "Bash(flutter test*)",
      "Bash(docker compose *)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)"
    ]
  }
}
```
`git push`, `rm`, migration çalıştırma gibi geri dönüşü zor işleri allow listesine
EKLEME — onlar onaylı kalsın.

---

## 7. 2 Günlük Fable Oyun Planı

**Gün 1 — Sabah:** `claude --model fable` → brief'i ver → plan mode → planı onayla →
Faz 0 iskeleti. Faz 0 bitince `/handoff` + `/clear`.
**Gün 1 — Öğleden sonra/akşam:** Yeni oturum, Fable → PROGRESS.md okut → Faz 1'in
zor parçaları: fotoğraf pipeline + bbox sorguları. `/handoff`.
**Gün 2 — Sabah:** Fable → harita clustering + kamera akışı + Faz 1'i uçtan uca
çalışır hale getir. `/handoff`.
**Gün 2 — Kalan limit:** Fable'a Faz 2'nin mimari taslağını (dosya/iskelet düzeyinde)
kurdur, implementasyon TODO'larıyla bırak. Limit biterse zaten `/model sonnet`.
**Sonrası:** Her şey Sonnet. Sonnet bir yerde 2-3 denemede çözemezse o spesifik
problemi izole edip bir sonraki Fable dönemine not düş (PROGRESS.md → "Fable'lık işler").

Not: Buradaki komut/özellik detayları hızla değişebiliyor; şüpheye düşersen Claude Code
içinden sorman yeterli (yerleşik docs ajanı var) veya https://code.claude.com/docs
