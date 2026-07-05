import 'package:flutter/material.dart';

/// Koyu tema öncelikli; turuncu-amber vurgu — "tehlike/asfalt" hissi.
abstract final class AppTheme {
  static const accent = Color(0xFFFFB300); // amber
  static const asphalt = Color(0xFF15151A);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: asphalt,
        ),
        scaffoldBackgroundColor: asphalt,
        appBarTheme: const AppBarTheme(
          backgroundColor: asphalt,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: accent.withValues(alpha: 0.25),
        ),
      );

  /// Tehlike seviyesi renkleri (1-4)
  static const severityColors = <int, Color>{
    1: Color(0xFFFFD54F), // 🟡 Tümsek sayılır
    2: Color(0xFFFF9800), // 🟠 Jant sallanır
    3: Color(0xFFE53935), // 🔴 Lastik gider
    4: Color(0xFF37373F), // ⚫ Araç yutar
  };
}
