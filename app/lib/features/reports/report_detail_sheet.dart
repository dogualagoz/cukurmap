import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import 'data/reports_api.dart';
import 'models/report.dart';

const _categoryLabels = {
  ReportCategory.cukur: Strings.categoryCukur,
  ReportCategory.bozukAsfalt: Strings.categoryBozukAsfalt,
  ReportCategory.rogar: Strings.categoryRogar,
  ReportCategory.kasis: Strings.categoryKasis,
  ReportCategory.diger: Strings.categoryDiger,
};

String _severityLabel(int severity) => switch (severity) {
      1 => Strings.severity1,
      2 => Strings.severity2,
      3 => Strings.severity3,
      _ => Strings.severity4,
    };

String _formatDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}

/// Marker'a tıklayınca açılan detay + oylama bottom sheet'i.
class ReportDetailSheet extends ConsumerWidget {
  const ReportDetailSheet({super.key, required this.reportId});

  final String reportId;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(reportDetailProvider(reportId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ReportDetail detail) {
    final origin = ref.watch(apiOriginProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detail.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                '$origin${detail.photoUrl}',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_pin, color: AppTheme.severityColors[detail.severity]),
              const SizedBox(width: 4),
              Text(
                _severityLabel(detail.severity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(_categoryLabels[detail.category] ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.description?.isNotEmpty == true
                ? detail.description!
                : Strings.detailNoDescription,
          ),
          const SizedBox(height: 8),
          if (detail.provinceName != null)
            Text('${Strings.detailProvinceLabel}: ${detail.provinceName}'),
          Text(_formatDate(detail.createdAt), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _voteButton(context, ref, Strings.voteConfirm, Icons.thumb_up_outlined,
                  detail.confirmCount, VoteType.confirm),
              _voteButton(context, ref, Strings.voteFixed, Icons.check_circle_outline,
                  detail.fixedCount, VoteType.fixed),
              _voteButton(context, ref, Strings.voteStillThere, Icons.warning_amber_outlined,
                  detail.stillThereCount, VoteType.stillThere),
              _voteButton(context, ref, Strings.voteComplaint, Icons.flag_outlined,
                  detail.complaintCount, VoteType.complaint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voteButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    int count,
    VoteType type,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _vote(context, ref, type),
      icon: Icon(icon, size: 18),
      label: Text('$label ($count)'),
    );
  }
}
