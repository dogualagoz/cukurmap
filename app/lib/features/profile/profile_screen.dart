import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/severity_badge.dart';
import '../auth/auth_provider.dart';
import '../reports/models/report.dart';
import '../users/data/users_api.dart';
import 'badge_catalog.dart';
import 'data/my_reports_provider.dart';

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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: switch (auth) {
          AsyncData(:final value) => _ProfileContent(nickname: value.nickname),
          AsyncError() => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Strings.profileOffline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondaryLightAlt, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(authProvider),
                      child: const Text(Strings.retry),
                    ),
                  ],
                ),
              ),
            ),
          _ => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(Strings.profileLoading),
                ],
              ),
            ),
        },
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.nickname});

  final String nickname;

  String get _initials {
    final parts = nickname.replaceAll('@', '').split(RegExp(r'[_\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final myReports = ref.watch(myReportsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        await ref.read(myReportsProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  children: [
                    Container(color: AppTheme.bgDark),
                    Center(
                      child: Text(
                        _initials,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 28, color: AppTheme.accent),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 8,
                        color: AppTheme.accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '@$nickname',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.bgDark, letterSpacing: -0.2),
              ),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined, color: AppTheme.bgDark),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (profileAsync.hasError && profile == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: Text(Strings.profileOffline)),
                  TextButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text(Strings.retry),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(child: _StatCard(value: profile != null ? '${profile.reportCount}' : '—', label: Strings.profileYourReports)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(value: profile != null ? '${profile.confirmsReceived}' : '—', label: Strings.profileConfirms)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(value: profile != null ? '${profile.fixedReportCount}' : '—', label: Strings.profileResolved, dark: true)),
            ],
          ),
        const SizedBox(height: 24),
        Text(Strings.profileBadgesTitle, style: AppTheme.mono(color: AppTheme.textSecondaryLight)),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badgeCatalog.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final def = badgeCatalog[i];
              final unlocked = profile != null && def.criteria(profile);
              return _BadgeTile(definition: def, locked: !unlocked);
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(Strings.profileReportsTitle, style: AppTheme.mono(color: AppTheme.textSecondaryLight)),
        const SizedBox(height: 10),
        if (myReports.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (myReports.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  Strings.profileHistoryError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondaryLightAlt, fontSize: 14),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref.read(myReportsProvider.notifier).refresh(),
                  child: const Text(Strings.retry),
                ),
              ],
            ),
          )
        else if (myReports.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              Strings.profileHistoryEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryLightAlt, fontSize: 14, height: 1.4),
            ),
          )
        else ...[
          for (final report in myReports.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _HistoryRow(report: report),
            ),
          if (myReports.hasMore)
            Center(
              child: myReports.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    )
                  : TextButton(
                      onPressed: () => ref.read(myReportsProvider.notifier).loadMore(),
                      child: const Text(Strings.loadMore),
                    ),
            ),
        ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.dark = false});

  final String value;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: dark ? AppTheme.bgDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: dark ? null : Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 24, color: dark ? AppTheme.accent : AppTheme.bgDark),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: dark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.definition, required this.locked});

  final BadgeDefinition definition;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: definition.description,
      child: Opacity(
        opacity: locked ? 0.4 : 1,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: locked ? const Color(0xFFE7E2D6) : AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  locked ? Icons.lock_outline : definition.icon,
                  color: locked ? AppTheme.textSecondaryLight : AppTheme.accent,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                definition.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryLightAlt, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.report});

  final ReportDetail report;

  String get _statusLabel => switch (report.status) {
        ReportStatus.fixed => Strings.statusFixed,
        ReportStatus.hidden => Strings.statusHidden,
        _ => Strings.statusActive,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(apiOriginProvider);
    final resolved = report.status == ReportStatus.fixed;
    final title = [
      _categoryLabels[report.category] ?? '',
      if (report.provinceName != null) report.provinceName!,
    ].join(' · ');
    return InkWell(
      onTap: () => context.push('/reports/${report.id}'),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 52,
                height: 52,
                child: report.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$origin${report.photoUrl}',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Colors.black.withValues(alpha: 0.06)),
                      )
                    : Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        child: Icon(Icons.photo_outlined, color: AppTheme.textSecondaryLight, size: 22),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.bgDark),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      SeverityDot(severity: report.severity, size: 8),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${severityLabel(report.severity)} · ${_formatDate(report.createdAt)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: resolved ? const Color(0xFFD9F2E1) : const Color(0xFFFFEFD6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: resolved ? const Color(0xFF1E7A44) : const Color(0xFFB85A00)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
