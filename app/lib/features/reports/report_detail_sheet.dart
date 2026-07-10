import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/severity_badge.dart';
import 'data/hidden_reports_provider.dart';
import 'data/reports_api.dart';
import 'models/report.dart';

const _categoryLabels = {
  ReportCategory.cukur: Strings.categoryCukur,
  ReportCategory.bozukAsfalt: Strings.categoryBozukAsfalt,
  ReportCategory.rogar: Strings.categoryRogar,
  ReportCategory.kasis: Strings.categoryKasis,
  ReportCategory.diger: Strings.categoryDiger,
};

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}

/// Marker'a tıklayınca açılan detay + oylama bottom sheet'i.
///
/// "Ben de gördüm" ana CTA'sı herkesin her çukura basıp geçebilmesini
/// önlemek için varsayılan olarak GİZLİ — sadece kullanıcı fiziksel olarak
/// çukurun yanından geçip geofence bildirimine dokunduğunda (`promptConfirm:
/// true`) görünür. Harita pin'ine dokunma akışı bunu hiç geçirmez.
class ReportDetailSheet extends ConsumerWidget {
  const ReportDetailSheet({super.key, required this.reportId, this.promptConfirm = false});

  final String reportId;
  final bool promptConfirm;

  Future<void> _vote(BuildContext context, WidgetRef ref, VoteType type) async {
    try {
      await ref.read(reportsApiProvider).vote(reportId, type);
      ref.invalidate(reportDetailProvider(reportId));
      ref.invalidate(reportMarkersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.voteThanks)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.voteError)),
      );
    }
  }

  /// Şikayet + lokal gizleme: sunucuya complaint oyu gider (eşikte auto-hide),
  /// içerik bu cihazda anında gizlenir, sheet kapanır.
  Future<void> _reportAndHide(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(hiddenReportsProvider.notifier).hide(reportId);
    try {
      await ref.read(reportsApiProvider).vote(reportId, VoteType.complaint);
    } catch (_) {
      // Lokal gizleme yeterli; sunucu şikayeti sonraki denemede tekrarlanabilir.
    }
    ref.invalidate(reportMarkersProvider);
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text(Strings.ugcReportedSnack)));
  }

  Future<void> _hideOnly(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(hiddenReportsProvider.notifier).hide(reportId);
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text(Strings.ugcHiddenSnack)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reportDetailProvider(reportId));
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: detailAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SizedBox(
              height: 120,
              child: Center(child: Text(Strings.reportErrorGeneric)),
            ),
            data: (detail) => _buildContent(context, ref, detail),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ReportDetail detail) {
    final origin = ref.watch(apiOriginProvider);
    final resolvedVotes = detail.stillThereCount + detail.fixedCount;
    final stillTherePct = resolvedVotes > 0 ? (detail.stillThereCount / resolvedVotes * 100).round() : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: detail.photoUrl != null
                      ? Image.network(
                          '$origin${detail.photoUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.black.withValues(alpha: 0.06)),
                        )
                      : Container(color: Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: SeverityBadge(severity: detail.severity, dense: true)),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_horiz, size: 20, color: AppTheme.textSecondaryLight),
                          constraints: const BoxConstraints(),
                          onSelected: (action) => action == 'report'
                              ? _reportAndHide(context, ref)
                              : _hideOnly(context, ref),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text(Strings.ugcReportAction),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hide',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text(Strings.ugcHideAction),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLabels[detail.category] ?? '',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.bgDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (detail.provinceName != null) detail.provinceName!,
                        _formatDate(detail.createdAt),
                      ].join(' · '),
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            detail.description?.isNotEmpty == true ? '"${detail.description}"' : Strings.detailNoDescription,
            style: TextStyle(fontSize: 14.5, height: 1.5, color: AppTheme.textSecondaryLightAlt),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                _StatTile(value: '${detail.confirmCount}', label: Strings.voteConfirm),
                if (stillTherePct != null) ...[
                  Container(width: 1, height: 32, color: Colors.black.withValues(alpha: 0.08)),
                  _StatTile(value: '%$stillTherePct', label: Strings.voteStillThere),
                ],
              ],
            ),
          ),
          if (promptConfirm) ...[
            const SizedBox(height: 18),
            PrimaryPillButton(
              label: '${Strings.voteConfirm}  ·  +1',
              onPressed: () => _vote(context, ref, VoteType.confirm),
              height: 54,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _vote(context, ref, VoteType.stillThere),
                    icon: SeverityDot(severity: 4, size: 9),
                    label: const Text(Strings.voteStillThere),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.bgDark,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.bgDark, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _vote(context, ref, VoteType.fixed),
                    icon: SeverityDot(severity: 1, size: 9),
                    label: const Text(Strings.voteFixed),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryLightAlt,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 20, color: AppTheme.bgDark)),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }
}
