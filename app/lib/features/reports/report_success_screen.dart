import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/severity_badge.dart';
import 'models/report.dart';

/// Mockup ekran 04 (Başarı) — POST /reports başarılı olduğunda gösterilir.
class ReportSuccessScreen extends ConsumerWidget {
  const ReportSuccessScreen({super.key, required this.report});

  final ReportDetail report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(apiOriginProvider);
    return Scaffold(
      backgroundColor: AppTheme.accent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(color: AppTheme.bgDark, shape: BoxShape.circle),
                      child: const Center(
                        child: Icon(Icons.check, color: AppTheme.accent, size: 52),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      Strings.successTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 34, color: AppTheme.bgDark),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        Strings.successBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16.5, height: 1.5, color: Color(0xFF4A4636)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: Column(
                children: [
                  _LocationCard(report: report, photoOrigin: origin),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Text('𝕏', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      label: const Text(Strings.successShare),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bgDark,
                        disabledBackgroundColor: AppTheme.bgDark,
                        foregroundColor: AppTheme.bgLight,
                        disabledForegroundColor: AppTheme.bgLight,
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SecondaryPillButton(
                    label: Strings.successViewMap,
                    dark: false,
                    onPressed: () => context.go('/map'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.report, required this.photoOrigin});

  final ReportDetail report;
  final String photoOrigin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 52,
              height: 52,
              child: report.photoUrl != null
                  ? Image.network(
                      '$photoOrigin${report.photoUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.cardDarkAlt),
                    )
                  : Container(color: AppTheme.cardDarkAlt),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.provinceName ?? Strings.detailProvinceLabel,
                  style: const TextStyle(color: AppTheme.bgLight, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    SeverityDot(severity: report.severity, size: 9),
                    const SizedBox(width: 6),
                    Text(
                      '${severityLabel(report.severity)} · ${Strings.successJustNow}',
                      style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
