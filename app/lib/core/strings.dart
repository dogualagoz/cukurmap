/// Tüm UI metinleri burada yaşar — ton: mizahi, küfürsüz, kimseyi hedef
/// göstermez. Çukurla dalga geçeriz, insanlarla değil.
abstract final class Strings {
  static const appName = 'CukurMap';

  // Sekmeler
  static const tabCamera = 'Bildir';
  static const tabMap = 'Harita';
  static const tabStats = 'Çukur Ligi';
  static const tabProfile = 'Profil';

  // Açılış / güvenlik uyarısı
  static const drivingWarningTitle = 'Önce güvenlik!';
  static const drivingWarningBody =
      'Sürerken kullanma; çukura kendin düşme. Bildirimi yolcu koltuğundan '
      'veya güvenle durduktan sonra yap. Bu uygulamayı kullanırken trafik '
      'kurallarına uymak tamamen senin sorumluluğunda.';
  static const drivingWarningOk = 'Söz, sürerken kullanmam';

  // Kamera
  static const reportWithoutPhoto = 'Fotoğrafsız bildir';
  static const cameraPermissionDenied =
      'Kameraya izin vermezsen çukurları hayal gücünle bildirmen lazım.';
  static const locationPermissionDenied =
      'Konum izni olmadan çukuru haritada nereye koyacağız, tahminle mi?';
  static const cameraFrameHint = 'Çukuru çerçeveye al';
  static const cameraShutterLabel = 'ÇEK';
  static const cameraAutoLabel = 'OTO';

  // Harita
  static const emptyMap =
      'Bu bölgede çukur yok... ya da kimse bildirmedi. '
      'Hangisi daha az olası sence?';
  static const filterSeverity = 'Tehlike seviyesi';
  static const filterStatus = 'Durum';
  static const filterAll = 'Hepsi';
  static const mapSearchHint = 'Mahalle veya cadde ara';
  static const statusActive = 'Hâlâ orada';
  static const statusFixed = 'Onarıldı';
  static const statusHidden = 'Şikayet edildi';

  // Rapor formu
  static const reportFormTitle = 'Çukuru bildir';
  static const reportSeverityLabel = 'Ne kadar acıtıyor?';
  static const reportCategoryLabel = 'Ne bu peki?';
  static const categoryCukur = 'Çukur';
  static const categoryBozukAsfalt = 'Bozuk asfalt';
  static const categoryRogar = 'Rogar kapağı';
  static const categoryKasis = 'Kasis';
  static const categoryDiger = 'Diğer';
  static const reportDescriptionLabel = 'Ekleyecek bir şey var mı? (opsiyonel)';
  static const reportDescriptionHint = 'Örn. sağ şeritte, gece görünmüyor...';
  static const reportSubmit = 'Bildir';
  static const reportSubmitting = 'Gönderiliyor...';
  static const reportSuccess = 'Bildirdin! Şehir sana minnettar (belki).';
  static const reportErrorGeneric =
      'Bir şeyler ters gitti. Çukur kazandı, tekrar dene.';
  static const reportErrorRateLimit =
      'Yavaş ol asfalt kahramanı, birazdan tekrar dene.';
  static const reportLocationLoading = 'Konumun bulunuyor...';
  static const reportAdjustPin = 'Pini sürükleyerek konumu düzelt';
  static const reportLocationLabel = 'Konum';

  // 409 mükerrer bildirim
  static const duplicateTitle = 'Bu çukur tanıdık geldi';
  static const duplicateBody =
      'Son 24 saatte buraya zaten birileri bildirim yapmış. '
      'Onu doğrulamak ister misin?';
  static const duplicateConfirm = 'Evet, ben de gördüm';
  static const duplicateCancel = 'Vazgeç';

  // Rapor detayı / oylama
  static const detailProvinceLabel = 'İl';
  static const detailNoDescription =
      'Açıklama eklenmemiş, çukur kendi hâlinde konuşuyor.';
  static const voteConfirm = 'Ben de gördüm';
  static const voteFixed = 'Onarılmış';
  static const voteStillThere = 'Hâlâ duruyor';
  static const voteComplaint = 'Bu bildirim sorunlu';
  static const voteThanks = 'Oyun kaydedildi, teşekkürler!';
  static const voteError = 'Oy kaydedilemedi, tekrar dene.';

  // Profil
  static const profileYourReports = 'Bildirimlerin';
  static const profileConfirms = 'Doğrulama';
  static const profileLoading = 'Rumuzun hazırlanıyor...';
  static const profileOffline =
      'Sunucuya ulaşamadık. Rumuzun kaçmıyor, merak etme.';
  static const retry = 'Tekrar dene';

  // Tehlike seviyeleri
  static const severity1 = 'Hafif tümsek';
  static const severity2 = 'Jant düşmanı';
  static const severity3 = 'Araba yutar';
  static const severity4 = 'Kayıp aracımız var';

  // Karşılama (onboarding)
  static const onboardingHeadline = 'Yoldaki çukuru\n3 saniyede işaretle.';
  static const onboardingBody =
      'Fotoğrafla, konumu onayla, bildir. Belediye görsün, mahalle bilsin — '
      'çukur artık görünmez değil.';
  static const onboardingCta = 'Başla';
  static const onboardingHow = 'Nasıl çalışır?';
  static const onboardingHowBody =
      'Çukuru fotoğrafla veya fotoğrafsız bildir, konumu haritada onayla, '
      'tehlike seviyesini seç. Diğer kullanıcılar oylayarak "hâlâ orada mı, '
      'onarıldı mı" diye günceller.';
  static const dialogOk = 'Tamam';

  // Başarı ekranı
  static const successTitle = 'Çukur haritada!';
  static const successBody =
      'Bildirimin haritaya eklendi. Belediye görsün, mahalle bilsin — '
      'çukur artık görünmez değil.';
  static const successShare = "'te paylaş";
  static const successViewMap = 'Haritada gör';
  static const successJustNow = 'az önce';

  // Çukur Ligi
  static const leagueTitle = 'Çukur Ligi';
  static const leagueWeekly = 'HAFTALIK';
  static const leagueSubtitle = 'Bu hafta en çok çukur bildirilen şehirler.';
  static const leagueResolved = 'çözüldü';
  static const leagueVerifications = 'doğrulama';
  static const leaguePotholes = 'çukur';
  static const leagueThisWeek = 'BU HAFTA';

  // Profil rozetleri
  static const badgeFirstReport = 'İlk Çukur';
  static const badgeNeighborhoodWatch = 'Mahalle Bekçisi';
  static const badge50Reports = '50 Bildirim';
  static const badgeViralLocked = 'Viral · kilitli';
  static const profileBadgesTitle = 'ROZETLER';
  static const profileReportsTitle = 'BİLDİRİMLERİM';
  static const profileResolved = 'Çözüldü';
}
