# PROJE BRIEF: Çukur Haritası Uygulaması (kod adı: "CukurMap")

> Bu doküman Claude Code'a verilmek üzere hazırlanmıştır. Claude Code bu dokümanı okuyup
> önce **plan mode** ile detaylı bir implementasyon planı çıkarmalı, plan onaylandıktan
> sonra faz faz geliştirmeye başlamalıdır. Sıfırdan, tamamlanabilir bir MVP hedeflenmektedir.

---

## 1. Proje Özeti

Türkiye'deki bozuk yol / çukur sorununa dikkat çeken, topluluk kaynaklı (crowdsourced)
bir çukur ihbar ve haritalama uygulaması. Kullanıcılar yolda gördükleri çukurları
fotoğraflayıp (veya fotoğrafsız) tek dokunuşla mevcut konumlarıyla birlikte paylaşır;
tüm ihbarlar ortak bir haritada işaretlenir.

**İkili hedef:**
1. **Pratik fayda:** Belediyelerin çukur/yol hatası tespitini kolaylaştırmak.
2. **Viral etki:** Şehirler arası "çukur sayısı yarışı", mizahi dil ve paylaşılabilir
   içeriklerle uygulamanın Twitter'da (özellikle siyasi/gündem timeline'ında) patlaması.

**Ton ve dil:** Serbest, mizahi, hafif iğneleyici ama küfürsüz ve hedef göstermeyen.
Uygulama içi metinler (boş durum mesajları, bildirimler, başarı rozetleri) esprili
yazılmalı. Örnek: boş harita durumunda "Bu bölgede çukur yok... ya da kimse bildirmedi.
Hangisi daha az olası sence?"

**Gelir modeli:** Yok. Tamamen ücretsiz. İleride AdMob banner eklenebilir diye mimari
buna kapı açık bırakılmalı ama MVP'de reklam YOK. Bu yüzden **işletme maliyeti minimum**
olmalı (aşağıdaki stack kararları buna göre verildi).

---

## 2. Tech Stack (KESİNLEŞMİŞ KARARLAR)

| Katman | Teknoloji | Gerekçe |
|---|---|---|
| Mobil | **Flutter** (Dart, stable channel) | Cross-platform, geliştirici deneyimi mevcut |
| State management | **Riverpod** (flutter_riverpod) | Test edilebilir, boilerplate az |
| Harita | **flutter_map + OpenStreetMap tiles** | Ücretsiz, hesap/API key/kredi kartı gerektirmiyor. Marker clustering için `flutter_map_marker_cluster`. (Mapbox ve Apple Maps değerlendirildi: Mapbox estetik olarak iyi ama hesap+kota+fatura riski taşıyor; Apple Maps yalnızca iOS'ta çalışıyor ve Android'i (Türkiye'de kullanıcı tabanının büyük kısmı) dışarıda bırakıyor. Karar OSM'de kesinleşti, tekrar tartışılmasın.) |
| Kamera | `camera` paketi | Snapchat benzeri hızlı çekim akışı için |
| Konum | `geolocator` | GPS konumu |
| Backend | **NestJS (TypeScript) + PostgreSQL + PostGIS** | Mevcut VPS'te barındırılacak (Plesk + Docker Compose). Sıfır ek maliyet. PostGIS coğrafi sorgular için ideal. (FastAPI değerlendirildi — geo tarafında GeoAlchemy2 de iyi bir seçenek olurdu, ama EstateDesk ile aynı stack/deploy düzenini korumak için NestJS'te karar kılındı. Bu tartışma kapalı, tekrar gündeme getirilmesin.) |
| Görsel depolama | VPS lokal disk + **sharp** ile agresif sıkıştırma (WebP, max 1280px, ~150-250KB hedef) | Ücretsiz. Cloudflare (veya benzeri CDN/proxy) MVP'de KULLANILMAYACAK — sadece Faz 3'te, gerçek trafik patlaması olursa devreye alınacak acil önlem olarak dursun; şimdiden mimariye eklenmesin |
| Push bildirim | Firebase Cloud Messaging (FCM) — **sadece bildirim için**, MVP'de opsiyonel/Faz 3 | Ücretsiz |
| Auth | **Anonim, cihaz bazlı** (device UUID + sunucu tarafı imzalı token). Hesap açma ZORUNLU DEĞİL | Sürtünmeyi sıfıra indir — viral akışta kayıt ekranı ölümdür |
| Deploy | Docker Compose, mevcut Plesk VPS | EstateDesk ile aynı düzen |

**NOT — Firebase alternatifi:** Eğer geliştirme sırasında VPS backend beklenenden fazla
zaman alırsa fallback Firebase'dir (Firestore + Blaze plan Storage). Ama varsayılan
karar VPS backend'idir; Claude Code Firebase'e geçişi ancak kullanıcı onayıyla önerebilir.
Gerekçe: gelir modeli olmayan, viral olması hedeflenen bir uygulamada Firebase'in
kullandıkça-öder modeli (özellikle fotoğraf storage/egress) trafik patlamasında
kontrolsüz maliyet riski taşıyor; VPS'te aynı senaryo yavaşlama/çökme ile sonuçlanır
ki bu ücretsiz bir uygulama için daha kabul edilebilir bir başarısızlık modudur.

---

## 3. Kullanıcı Akışları

### 3.1 Ana akış: Çukur bildir (uygulamanın kalbi — maksimum 3 dokunuş)
1. Uygulama açılır → **doğrudan kamera ekranı** (Snapchat gibi). İlk açılışta kamera +
   konum izni istenir.
2. Kullanıcı çukurun fotoğrafını çeker **veya** "fotoğrafsız bildir" butonuna basar.
3. Önizleme ekranı:
   - Konum otomatik alınır (harita üzerinde küçük pin ile gösterilir, kullanıcı pin'i
     sürükleyerek ince ayar yapabilir — GPS araç içinde sapabilir).
   - **Tehlike seviyesi** seçimi (zorunlu, varsayılan orta): mizahi etiketlerle 4 seviye:
     - 1 "Tümsek sayılır" 🟡
     - 2 "Jant sallanır" 🟠
     - 3 "Lastik gider" 🔴
     - 4 "Araç yutar" ⚫ (krater seviyesi)
   - Opsiyonel açıklama (max 280 karakter — Twitter göndermesi bilinçli).
   - Kategori (opsiyonel): çukur / bozuk asfalt / rögar kapağı / kasis / diğer.
4. "Bildir" → post haritaya düşer. Başarı ekranında mizahi onay mesajı + **"Twitter'da
   paylaş"** butonu (hazır tweet metni: fotoğraf + konum + şehir hashtag'i, ör.
   "#EskişehirinÇukurları").

### 3.2 Harita (ana sayfa sekmesi)
- Tam ekran harita, kullanıcının konumuna odaklı açılır.
- Tüm bildirimler tehlike seviyesine göre renkli marker. Zoom-out'ta clustering.
- Marker'a dokununca alt sheet: fotoğraf, açıklama, tehlike seviyesi, tarih,
  "Ben de gördüm" (+1 doğrulama) butonu, "Hâlâ orada / Yapılmış" durumu oylaması.
- Filtreler: tehlike seviyesi, tarih, durum (aktif / yapıldı).
- **"Yapıldı" mekanizması:** yeterli sayıda "yapılmış" oyu alan çukur yeşile döner ve
  "Belediye buraya el atmış 👏" olarak işaretlenir. Bu, belediyelere pozitif teşvik
  verir ve uygulamayı düşmanca olmaktan çıkarır.

### 3.3 İstatistik / Yarış sekmesi (viral motor)
- **Şehir ligi:** aktif çukur sayısına göre il sıralaması ("Çukur Ligi" — mizahi
  puan durumu tablosu görünümü). Kişi başına normalize edilmiş ve ham sayı olmak üzere
  iki görünüm.
- Şehir detayı: toplam bildirim, çözülen (yapıldı) oranı, "en efsane çukur"
  (en çok doğrulama alan).
- Her istatistik kartında "Twitter'da paylaş" butonu — kart, görsel olarak paylaşılabilir
  (screenshot-friendly) tasarlanmalı.
- Haftalık özet: "Bu hafta Türkiye'ye 342 yeni çukur katıldı."

### 3.4 Profil (minimal)
- Anonim kullanıcı: otomatik atanmış mizahi rumuz (ör. "Çukur Avcısı #4821"),
  değiştirilebilir takma ad.
- Kendi bildirimlerinin listesi, toplam doğrulama sayısı, basit rozetler
  ("İlk Çukur", "10 Çukur — Jant Düşmanı", "Kraterolog" vs).

---

## 4. Kötüye Kullanım & Güvenlik & Yasal

- **Moderasyon (MVP):** "Şikayet et" butonu + N şikayet alan post otomatik gizlenir +
  basit admin endpoint'i (token korumalı) ile silme. Gelişmiş moderasyon Faz 3.
- **Spam:** rate limit + aynı konuma (50m yarıçap) kısa sürede mükerrer bildirim
  engelleme (mevcut rapora doğrulama olarak yönlendir).
- **KVKK/Gizlilik:** fotoğraflardaki EXIF GPS verisi silinir; kullanıcıya yüklediği
  fotoğrafta plaka/yüz görünmemesi konusunda uyarı metni; anonim kimlik varsayılan.
- **Sürüş güvenliği:** uygulama açılış uyarısı — "Sürerken kullanma, çukura kendin
  düşme." (mizahi ama gerçek bir yasal koruma metniyle birlikte).
- Mizahi dil sınırı: belediye/kişi hedef gösterme yok, siyasi parti ismi yok.
  Uygulama çukurla dalga geçer, insanlarla değil.

---

## 6. Geliştirme Fazları (Claude Code bu sırayla plan çıkarmalı)

### Faz 0 — İskelet (Fable ile yapılacak, kritik)
- Monorepo yapısı: `/app` (Flutter), `/api` (NestJS), `/docker`, `/docs`
- NestJS projesi + PostgreSQL/PostGIS docker-compose + migration altyapısı (TypeORM
  veya Prisma — Claude Code önersin, PostGIS desteğine göre)
- Flutter projesi + Riverpod + routing (go_router) + tema (koyu tema öncelikli,
  vurgu rengi: turuncu-amber tonları — "tehlike/asfalt" hissi)
- Anonim auth uçtan uca çalışır halde

### Faz 1 — Çekirdek döngü (Fable ile yapılacak)
- Kamera → önizleme → bildir akışı (fotoğraflı + fotoğrafsız)
- Fotoğraf upload pipeline (sıkıştırma, EXIF temizleme)
- Harita ekranı: bbox sorgusu, marker'lar, clustering, detay sheet
- Doğrulama/yapıldı oylaması

### Faz 2 — Viral katman (Sonnet ile yapılabilir)
- Şehir ligi + istatistik ekranları
- Twitter paylaşım entegrasyonu (share_plus + hazır tweet metinleri)
- Rozetler, mizahi metin sözlüğü (tüm UI metinleri tek `strings` dosyasında —
  kolayca ton ayarı için)
- Şikayet/moderasyon temel akışı

### Faz 3 — Cila ve yayın (Sonnet)
- Android ana ekran widget'ı (tek dokunuş kamera) — home_widget paketi
- FCM bildirimleri ("Bildirdiğin çukur yapılmış!")
- Onboarding, uygulama ikonu, splash, store metinleri (mizahi)
- Test coverage (backend unit + kritik Flutter widget testleri), CI temizliği

**MVP tanımı = Faz 0 + Faz 1 + Faz 2.** Faz 3 yayın öncesi cila.

---

## 7. Claude Code'dan Beklenen Çalışma Şekli

1. Bu dokümanı oku, **plan mode**'da fazlara ve dosya yapısına inen bir plan çıkar,
   onay iste. Onaysız büyük implementasyona başlama.
2. **Veri modeli ve API tasarımı bilinçli olarak bu dokümanda yok** — bunlar plan
   mode'da birlikte, bölüm 2-3'teki kararlara göre çıkarılacak (tablolar/ilişkiler,
   endpoint listesi, reverse geocoding yaklaşımı gibi). Planını çıkarırken bunları
   önerip onay iste, tek taraflı karar verip ilerleme.
3. Her faz sonunda `docs/PROGRESS.md` dosyasını güncelle: ne bitti, ne kaldı, bilinen
   sorunlar, bir sonraki oturumun ilk adımı. (Oturumlar arası devir teslim dosyası.)
   Veri modeli ve API netleştikten sonra bunları da PROGRESS.md'ye (veya ayrı bir
   docs/SCHEMA.md ve docs/API.md dosyasına) yazıp orada güncel tut.
4. Kararsız kaldığın mimari noktalarda uzun uzun keşif yapmak yerine 2-3 seçeneği
   tek mesajda özetleyip sor.
5. Commit'lerde Conventional Commits kullan (mevcut `conventional-commit` skill).
6. Backend deploy hazırlığında `pre-deploy-check` skill mantığını bu projeye uyarla.
