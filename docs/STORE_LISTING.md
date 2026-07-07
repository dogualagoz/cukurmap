# App Store Listing — CukurMap

App Store Connect'te "App Information" ve sürüm sayfasına girilecek metinler.
Ton: mizahi, küfürsüz, kimseyi hedef göstermez (CLAUDE.md kuralı).

## Kimlik

| Alan | Değer |
|---|---|
| App Name | CukurMap |
| Bundle ID | com.cukurmap.app |
| SKU | cukurmap-ios-001 |
| Primary Language | Turkish |
| Category (Primary) | Navigation |
| Category (Secondary) | Utilities |
| Age Rating | 4+ (UGC soruları: bkz. aşağıda) |
| Price | Ücretsiz |

## Subtitle (30 karakter sınırı)

> Çukurları haritala, paylaş

(29 karakter)

## Promotional Text (170 karakter, review gerektirmeden değiştirilebilir)

> Yolda gördüğün çukuru 3 dokunuşta bildir, şehrinin Çukur Ligi'ndeki yerini takip et. Belediyene sessiz kalma — haritaya konuş.

## Description

```
Türkiye'nin yollarında çukur mu var? Sorma, bildir.

CukurMap, yolda gördüğün çukurları fotoğraflayıp tek dokunuşla ortak haritaya
işaretlemeni sağlayan topluluk uygulamasıdır. Hesap yok, kayıt yok, sürtünme yok:
uygulamayı aç, çek, bildir.

NASIL ÇALIŞIR?
• Kamerayı çukura doğrult, çek (veya fotoğrafsız bildir)
• Tehlike seviyesini seç: "Hafif tümsek"ten "Kayıp aracımız var"a
• Bildir — çukurun haritaya düşer, herkes görür

NELER VAR?
• Canlı çukur haritası: şehrindeki tüm bildirimler, tehlike seviyesine göre renkli
• "Ben de gördüm" doğrulaması: aynı çukuru gören herkes tek dokunuşla onaylar
• "Yapılmış" oylaması: belediye el atınca çukur yeşile döner — emeğe saygı 👏
• Çukur Ligi: iller arası çukur sıralaması. Şehrin kaçıncı sırada?
• Akış: en yeni ve en popüler çukurlar
• Yakındaki çukur uyarısı: bildirilen bir çukura yaklaşınca haber verir (istersen)

GİZLİLİK?
• Hesap açılmaz, kimlik toplamayız — anonim mizahi rumuzunla katılırsın
• Fotoğraflardaki konum verisi (EXIF/GPS) sunucuya kaydedilmeden silinir
• Reklam yok, izleme yok, para istemiyoruz

Çukurla dalga geçeriz, insanlarla değil. Yolun açık, jantın sağlam olsun.
```

## Keywords (100 karakter sınırı, virgülle)

> çukur,yol,asfalt,harita,belediye,trafik,bildir,ihbar,kasis,rögar,şikayet

(72 karakter — boşluksuz yaz)

## What's New (v1.0.0)

> İlk sürüm! Çukur bildir, haritada gör, şehrin için Çukur Ligi'nde ter dök.
> Jantlarınız için sabırsızlanıyoruz.

## URL'ler

| Alan | Değer |
|---|---|
| Privacy Policy URL | https://DOMAIN/privacy.html (domain alınınca güncelle) |
| Support URL | https://DOMAIN (veya GitHub repo/iletişim sayfası) |
| Marketing URL | (opsiyonel, boş bırakılabilir) |

## App Privacy formu (App Store Connect → App Privacy)

Apple'ın "Data Types" soruları için doğru beyanlar:

| Apple kategorisi | Toplanıyor mu? | Not |
|---|---|---|
| Location → Precise Location | **Evet** — "Linked to you: No", "Tracking: No" | Çukurun konumu; App Functionality amaçlı |
| Photos or Videos | **Evet** — Linked: No, Tracking: No | Kullanıcının çektiği çukur fotoğrafı; EXIF GPS silinir |
| User Content → Other User Content | **Evet** — Linked: No, Tracking: No | Açıklama metni, oylar |
| Identifiers → Device ID | **Hayır** de | Cihaz ID'sinin kendisi hiç sunucuya gitmez; yalnızca geri döndürülemez hash'i gider ve tracking amaçlı kullanılmaz. (Gri alan: istersen "User ID, Linked: No" olarak beyan et — daha muhafazakâr seçenek) |
| Contact Info / Health / Financial / Browsing vb. | Hayır | Toplanmıyor |

"Data Used to Track You": **hiçbiri**. Üçüncü taraf SDK/reklam/analitik yok.

## Age Rating anketi kritik cevaplar

- Unrestricted Web Access: No
- User-Generated Content: **Yes** → Apple UGC gereksinimleri karşılanıyor:
  şikayet (report) mekanizması var, N şikayette otomatik gizleme var,
  kötüye kullanım engelleme (rate limit + ban) var
- Gambling / Violence / Mature themes: No → 4+

## Review Notes (App Review ekibine not — İngilizce)

```
CukurMap is a crowdsourced pothole-reporting app for Turkey. No account or
login is required — the app authenticates anonymously with a random device-
generated UUID (only a salted hash is stored server-side). To test the full
flow: open the app, complete onboarding, take a photo of any road surface
(or tap "Fotoğrafsız bildir" to report without a photo), pick a severity
level, and submit. The report appears on the shared map. Camera and location
permissions are required for the core reporting flow. All UGC has a report/
flag mechanism; content passing a complaint threshold is auto-hidden.
```

## Screenshot planı (kullanıcı çekecek — Claude cihaz testi yapmaz)

Zorunlu boyutlar: 6.9" (1320×2868) + 6.5" (1284×2778 veya 1242×2688). iPad zorunlu değil (iPhone-only işaretle).

Önerilen 5-6 kare (story anlatım sırası):
1. Kamera ekranı — "Çukuru çerçeveye al" (uygulamanın kalbi)
2. Rapor formu — tehlike seviyesi chip'leri görünür halde
3. Harita — renkli marker'lar + cluster'lar, İstanbul/Ankara gibi dolu bölge
4. Detay sheet — fotoğraf + "Ben de gördüm" butonları
5. Çukur Ligi — leaderboard (viral kanca)
6. (ops.) Akış sekmesi

Not: Screenshot'larda gerçek plaka/yüz görünmesin.
