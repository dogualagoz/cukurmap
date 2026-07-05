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

  // Kamera (Faz 1'de gerçek akış)
  static const cameraComingSoon =
      'Kamera akışı yolda. Şimdilik çukurlar güvende... ama değil.';
  static const reportWithoutPhoto = 'Fotoğrafsız bildir';

  // Harita
  static const emptyMap =
      'Bu bölgede çukur yok... ya da kimse bildirmedi. '
      'Hangisi daha az olası sence?';
  static const mapComingSoon = 'Harita Faz 1\'de açılıyor. Marker\'lar ısınıyor.';

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
