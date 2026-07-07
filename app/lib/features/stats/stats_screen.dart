import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'data/stats_api.dart';
import 'models/city_league_entry.dart';

String _formatCount(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(cityLeagueProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cityLeagueProvider);
            try {
              await ref.read(cityLeagueProvider.future);
            } catch (_) {
              // Hata durumu zaten AsyncValue.error dalıyla ekranda gösteriliyor.
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Strings.leagueTitle,
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 30, color: AppTheme.bgLight, letterSpacing: -0.4),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      Strings.leagueWeekly,
                      style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.bgDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(Strings.leagueSubtitle, style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14)),
              const SizedBox(height: 20),
              ..._buildBody(context, ref, league),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CityLeagueEntry>> league,
  ) {
    return league.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, stackTrace) => [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              Text(
                Strings.leagueLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(cityLeagueProvider),
                child: const Text(Strings.retry),
              ),
            ],
          ),
        ),
      ],
      data: (cities) {
        if (cities.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(Strings.leagueEmpty, style: TextStyle(color: AppTheme.textSecondaryDark)),
              ),
            ),
          ];
        }
        final leader = cities.first;
        final rest = cities.skip(1).toList();
        return [
          _LeaderCard(city: leader),
          const SizedBox(height: 22),
          for (var i = 0; i < rest.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _RankRow(rank: i + 2, city: rest[i]),
            ),
        ];
      },
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.city});

  final CityLeagueEntry city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color(0xFFFF8A1E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#1 ${Strings.leagueThisWeek}', style: AppTheme.mono(color: const Color(0xFF7A4A00), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    city.name,
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 30, color: AppTheme.bgDark, height: 1.1),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCount(city.reportCount),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 26, color: AppTheme.bgDark),
                  ),
                  Text(Strings.leaguePotholes, style: TextStyle(fontSize: 12, color: const Color(0xFF7A4A00), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _LeaderStat(value: '%${city.resolvedPct}', label: Strings.leagueResolved)),
              if (city.verifications > 0) ...[
                const SizedBox(width: 8),
                Expanded(child: _LeaderStat(value: _formatCount(city.verifications), label: Strings.leagueVerifications)),
              ],
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 44,
                decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(10)),
                child: const Center(
                  child: Text('𝕏', style: TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderStat extends StatelessWidget {
  const _LeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.bgDark.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.bgDark)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7A4A00))),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.city});

  final int rank;
  final CityLeagueEntry city;

  @override
  Widget build(BuildContext context) {
    final emphasized = rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: emphasized ? AppTheme.cardDark : AppTheme.cardDarkAlt,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                fontSize: emphasized ? 17 : 16,
                color: emphasized ? const Color(0xFFC9C3B4) : AppTheme.textSecondaryDarkAlt,
              ),
            ),
          ),
          Expanded(
            child: Text(
              city.name,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                fontSize: emphasized ? 16 : 15.5,
                color: emphasized ? AppTheme.bgLight : AppTheme.textSecondaryDark,
              ),
            ),
          ),
          if (emphasized)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCount(city.reportCount), style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.bgLight)),
                Text('%${city.resolvedPct} ${Strings.leagueResolved}', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark)),
              ],
            )
          else
            Text(
              _formatCount(city.reportCount),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textSecondaryDark),
            ),
        ],
      ),
    );
  }
}
