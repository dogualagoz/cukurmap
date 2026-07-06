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

  // Harita
  static const emptyMap =
      'Bu bölgede çukur yok... ya da kimse bildirmedi. '
      'Hangisi daha az olası sence?';
  static const filterSeverity = 'Tehlike seviyesi';
  static const filterStatus = 'Durum';
  static const filterAll = 'Hepsi';
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

  // İstatistik
  static const statsComingSoon =
      'Çukur Ligi puan durumu hazırlanıyor. Şehrin şimdiden antrenmanda.';

  // Profil
  static const profileYourReports = 'Bildirimlerin';
  static const profileConfirms = 'Doğrulama';
  static const profileLoading = 'Rumuzun hazırlanıyor...';
  static const profileOffline =
      'Sunucuya ulaşamadık. Rumuzun kaçmıyor, merak etme.';
  static const retry = 'Tekrar dene';

  // Tehlike seviyeleri (Faz 1'de kullanılacak)
  static const severity1 = 'Tümsek sayılır';
  static const severity2 = 'Jant sallanır';
  static const severity3 = 'Lastik gider';
  static const severity4 = 'Araç yutar';
}
