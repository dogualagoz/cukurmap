import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Birincil altın dolgu pill buton — "Bildir", "Başla" gibi ana aksiyonlar.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
          foregroundColor: AppTheme.bgDark,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        child: Text(label),
      ),
    );
  }
}

/// İkincil pill buton — koyu zeminde outline, açık zeminde hafif dolgu.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.dark = false,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppTheme.bgLight : AppTheme.bgDark;
    final bg = dark ? AppTheme.bgLight.withValues(alpha: 0.08) : AppTheme.bgDark.withValues(alpha: 0.08);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Transparan metin butonu (ör. "Nasıl çalışır?")
class GhostTextButton extends StatelessWidget {
  const GhostTextButton({super.key, required this.label, required this.onPressed, this.dark = true});

  final String label;
  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppTheme.bgLight : AppTheme.bgDark;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color.withValues(alpha: 0.75)),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}
