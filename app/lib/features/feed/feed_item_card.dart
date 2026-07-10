import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/severity_badge.dart';
import '../reports/data/hidden_reports_provider.dart';
import '../reports/models/report.dart';

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

String? _formatDistance(double? meters) {
  if (meters == null) return null;
  if (meters < 1000) return '${meters.round()} m ${Strings.feedDistanceAway}';
  return '${(meters / 1000).toStringAsFixed(1)} km ${Strings.feedDistanceAway}';
}

class FeedItemCard extends ConsumerWidget {
  const FeedItemCard({super.key, required this.item, required this.onVote});

  final FeedItem item;
  final void Function(VoteType type) onVote;

  void _reportContent(BuildContext context, WidgetRef ref) {
    onVote(VoteType.complaint);
    ref.read(hiddenReportsProvider.notifier).hide(item.report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.ugcReportedSnack)),
    );
  }

  void _hideContent(BuildContext context, WidgetRef ref) {
    ref.read(hiddenReportsProvider.notifier).hide(item.report.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(Strings.ugcHiddenSnack)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(apiOriginProvider);
    final report = item.report;
    final distanceLabel = _formatDistance(item.distanceMeters);
    final score = report.upvoteCount - report.downvoteCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (report.photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CachedNetworkImage(
                      imageUrl: '$origin${report.photoUrl}',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: SeverityBadge(severity: report.severity, dense: true)),
                        SizedBox(
                          width: 28,
                          height: 24,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.more_horiz, size: 20, color: AppTheme.textSecondaryLight),
                            onSelected: (action) => action == 'report'
                                ? _reportContent(context, ref)
                                : _hideContent(context, ref),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLabels[report.category] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.bgDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (report.provinceName != null) report.provinceName!,
                        if (distanceLabel != null) distanceLabel,
                        _formatDate(report.createdAt),
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.description?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              '"${report.description}"',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textSecondaryLightAlt),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _VoteButton(
                icon: Icons.arrow_upward,
                count: report.upvoteCount,
                onTap: () => onVote(VoteType.upvote),
              ),
              const SizedBox(width: 8),
              _VoteButton(
                icon: Icons.arrow_downward,
                count: report.downvoteCount,
                onTap: () => onVote(VoteType.downvote),
              ),
              const Spacer(),
              Text(
                score >= 0 ? '+$score' : '$score',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: score >= 0 ? const Color(0xFF1E7A44) : const Color(0xFF9A1F16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({required this.icon, required this.count, required this.onTap});

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.textSecondaryLightAlt),
            const SizedBox(width: 6),
            Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.bgDark)),
          ],
        ),
      ),
    );
  }
}
