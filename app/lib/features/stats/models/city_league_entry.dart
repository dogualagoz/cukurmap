/// GET /stats/cities'deki tek bir il satırı.
class CityLeagueEntry {
  const CityLeagueEntry({
    required this.name,
    required this.slug,
    required this.reportCount,
    required this.resolvedPct,
    required this.verifications,
  });

  final String name;
  final String slug;
  final int reportCount;
  final int resolvedPct;
  final int verifications;

  factory CityLeagueEntry.fromJson(Map<String, dynamic> json) => CityLeagueEntry(
        name: json['name'] as String,
        slug: json['slug'] as String,
        reportCount: json['reportCount'] as int,
        resolvedPct: json['resolvedPct'] as int,
        verifications: json['verifications'] as int,
      );
}
