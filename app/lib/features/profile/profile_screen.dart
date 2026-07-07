import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/severity_badge.dart';
import '../auth/auth_provider.dart';
import '../users/data/users_api.dart';
import 'badge_catalog.dart';

/// Bildirim geçmişi için henüz bir "kendi bildirimlerim" API'si yok
/// (bkz. docs/PROGRESS.md). Rozetler ve istatistikler artık `userProfileProvider`
/// üzerinden gerçek veriye bağlı; sadece bu geçmiş listesi hâlâ örnek içerik.
const _mockHistory = [
  (title: 'Bağdat Cd. çukuru', severity: 3, when: '2 gün önce', status: Strings.statusActive),
  (title: 'Moda Sahili girişi', severity: 1, when: '1 hafta önce', status: Strings.statusFixed),
  (title: 'Söğütlüçeşme köprüsü', severity: 4, when: '2 hafta önce', status: Strings.statusActive),
];

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
    return ListView(
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
        for (final item in _mockHistory)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _HistoryRow(item: item),
          ),
      ],
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

typedef _HistoryItem = ({String title, int severity, String when, String status});

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final resolved = item.status == Strings.statusFixed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(11)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.bgDark)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    SeverityDot(severity: item.severity, size: 8),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${severityLabel(item.severity)} · ${item.when}',
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
              item.status,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: resolved ? const Color(0xFF1E7A44) : const Color(0xFFB85A00)),
            ),
          ),
        ],
      ),
    );
  }
}
