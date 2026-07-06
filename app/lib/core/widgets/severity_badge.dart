import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

Color severityColor(int severity) =>
    AppTheme.severityColors[severity] ?? AppTheme.textSecondaryLight;

String severityLabel(int severity) => switch (severity) {
      1 => Strings.severity1,
      2 => Strings.severity2,
      3 => Strings.severity3,
      _ => Strings.severity4,
    };

/// Renkli nokta — seviye seçimi, harita legend'ı, profil geçmişi gibi
/// tekrarlanan yerlerde kullanılır.
class SeverityDot extends StatelessWidget {
  const SeverityDot({super.key, required this.severity, this.size = 12});

  final int severity;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: severityColor(severity)),
      );
}

/// Rozet zemini üzerinde okunaklı koyu metin tonu (mockup'taki gibi).
const _severityTextColors = <int, Color>{
  1: Color(0xFF1E7A44),
  2: Color(0xFF7A4A00),
  3: Color(0xFF9A4400),
  4: Color(0xFF9A1F16),
};

/// "🟠 Araba yutar · Seviye 3" tarzı pill rozet (bildirim detayı, kamera üstü vb.)
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    super.key,
    required this.severity,
    this.dense = false,
  });

  final int severity;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    final textColor = _severityTextColors[severity] ?? AppTheme.textSecondaryLightAlt;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 5 : 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeverityDot(severity: severity, size: dense ? 7 : 9),
          const SizedBox(width: 7),
          Text(
            severityLabel(severity),
            style: TextStyle(fontSize: dense ? 12 : 13.5, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}
