import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Claude Design mockup'ından (CukurMap.dc.html) alınan görsel dil:
/// sıcak krem zemin + altın vurgu, Kamera/Onboarding/Çukur Ligi'nde
/// bilinçli koyu kontrast.
abstract final class AppTheme {
  static const accent = Color(0xFFFFC400); // altın
  static const bgLight = Color(0xFFF5F3EF); // krem
  static const bgDark = Color(0xFF16150F); // neredeyse siyah
  static const cardDark = Color(0xFF211D16);
  static const cardDarkAlt = Color(0xFF1B1811);
  static const textSecondaryLight = Color(0xFF8A8474);
  static const textSecondaryLightAlt = Color(0xFF57534A);
  static const textSecondaryDark = Color(0xFFA8A296);
  static const textSecondaryDarkAlt = Color(0xFF75705F);

  static TextTheme _textTheme(Color base) => TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: base),
        displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: base),
        headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: base),
        headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: base),
        headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: base),
        titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: base),
        titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: base),
        titleSmall: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600, color: base),
        bodyLarge: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w400, color: base),
        bodyMedium: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w400, color: base),
        bodySmall: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w400, color: base),
        labelLarge: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600, color: base),
        labelMedium: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w500, color: base),
        labelSmall: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w500, color: base),
      );

  /// Etiket/rozet metinleri için JetBrains Mono — TextTheme'in parçası değil,
  /// mockup'ta sadece küçük "ETİKET" tarzı yerlerde kullanılıyor.
  static TextStyle mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textSecondaryLight,
    double letterSpacing = 0.6,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Varsayılan tema — form/harita/detay/profil gibi işlevsel ekranlar bunu kullanır.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
          surface: bgLight,
        ),
        scaffoldBackgroundColor: bgLight,
        textTheme: _textTheme(bgDark),
        appBarTheme: AppBarTheme(
          backgroundColor: bgLight,
          foregroundColor: bgDark,
          centerTitle: true,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 19,
            color: bgDark,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: accent.withValues(alpha: 0.25),
        ),
      );

  /// Kamera/Onboarding/Çukur Ligi gibi bilinçli koyu ekranlar bu paleti
  /// widget ağaçlarında doğrudan kullanır (bunlar Material bileşenlerine değil
  /// özel çizime dayandığı için ambient Theme switch'ine gerek yok).
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: bgDark,
        ),
        scaffoldBackgroundColor: bgDark,
        textTheme: _textTheme(bgLight),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: accent.withValues(alpha: 0.25),
        ),
      );

  /// Tehlike seviyesi renkleri (1-4) — Claude Design mockup'ındaki paletle eşleşir.
  static const severityColors = <int, Color>{
    1: Color(0xFF35C46A), // 🟢 Hafif tümsek
    2: Color(0xFFFFC400), // 🟡 Jant düşmanı
    3: Color(0xFFFF8A1E), // 🟠 Araba yutar
    4: Color(0xFFF4331F), // 🔴 Kayıp aracımız var
  };
}
