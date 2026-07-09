import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/prefs_keys.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';

/// Mockup ekran 01 (Karşılama) — ilk açılışta gösterilir.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final origin = ref.read(apiOriginProvider);
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TermsDialog(origin: origin),
    );
    if (accepted != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.hasSeenOnboarding, true);
    await prefs.setBool(PrefsKeys.termsAcceptedV1, true);
    if (context.mounted) context.go('/camera');
  }

  void _showHow(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(Strings.onboardingHow, style: TextStyle(color: AppTheme.bgLight)),
        content: Text(
          Strings.onboardingHowBody,
          style: TextStyle(color: AppTheme.textSecondaryDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.dialogOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: Center(child: AspectRatio(aspectRatio: 1, child: _RoadIllustration())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 16, 30, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 26, height: 6, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 7),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 7),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(3))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Strings.onboardingHeadline,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 31,
                      height: 1.08,
                      letterSpacing: -0.4,
                      color: AppTheme.bgLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.onboardingBody,
                    style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  PrimaryPillButton(label: Strings.onboardingCta, onPressed: () => _start(context, ref)),
                  const SizedBox(height: 4),
                  GhostTextButton(label: Strings.onboardingHow, onPressed: () => _showHow(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sürüş güvenliği sözü + zorunlu kullanım koşulları kabulü (Apple 1.2 EULA).
class _TermsDialog extends StatefulWidget {
  const _TermsDialog({required this.origin});

  final String origin;

  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<_TermsDialog> {
  bool _termsAccepted = false;

  Future<void> _openPage(String path) {
    return launchUrl(
      Uri.parse('${widget.origin}$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _link(String label, String path) {
    return InkWell(
      onTap: () => _openPage(path),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 13.5,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      title: Text(Strings.drivingWarningTitle, style: TextStyle(color: AppTheme.bgLight)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.drivingWarningBody,
            style: TextStyle(color: AppTheme.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _link(Strings.termsLinkTerms, '/terms.html'),
              const SizedBox(width: 16),
              _link(Strings.termsLinkPrivacy, '/privacy.html'),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _termsAccepted,
            onChanged: (value) => setState(() => _termsAccepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppTheme.accent,
            checkColor: AppTheme.bgDark,
            side: BorderSide(color: AppTheme.textSecondaryDark),
            title: Text(
              Strings.termsCheckboxLabel,
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _termsAccepted ? () => Navigator.of(context).pop(true) : null,
          child: const Text(Strings.drivingWarningOk),
        ),
      ],
    );
  }
}

class _RoadIllustration extends StatefulWidget {
  @override
  State<_RoadIllustration> createState() => _RoadIllustrationState();
}

class _RoadIllustrationState extends State<_RoadIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.56,
                heightFactor: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2C271D), Color(0xFF1B1812)]),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.02,
                heightFactor: 1,
                child: CustomPaint(painter: _DashedLinePainter()),
              ),
            ),
            Positioned(
              left: 100,
              top: 140,
              child: Container(
                width: 104,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0A07),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.severityColors[4]!, blurRadius: 0, spreadRadius: 4),
                    const BoxShadow(color: Colors.black54, blurRadius: 34, offset: Offset(0, 14)),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dy = -8.0 * _controller.value;
                return Positioned(
                  right: 70,
                  top: 60 + dy,
                  child: child!,
                );
              },
              child: Column(
                children: [
                  Transform.rotate(
                    angle: 0.785398, // 45deg
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 10))],
                      ),
                      child: Transform.rotate(
                        angle: -0.785398,
                        child: Center(
                          child: Text('!', style: GoogleFonts.spaceGrotesk(color: AppTheme.bgDark, fontWeight: FontWeight.w700, fontSize: 24, height: 1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.28))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.accent.withValues(alpha: 0.9);
    const dashHeight = 24.0;
    const gap = 24.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
