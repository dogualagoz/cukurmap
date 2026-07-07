import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../models/city_league_entry.dart';

class StatsApi {
  StatsApi(this._dio);

  final Dio _dio;

  Future<List<CityLeagueEntry>> getCityLeague({String sort = 'total'}) async {
    final response = await _dio.get<List<dynamic>>(
      '/stats/cities',
      queryParameters: {'sort': sort},
    );
    return (response.data ?? [])
        .map((e) => CityLeagueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final statsApiProvider = Provider<StatsApi>((ref) {
  return StatsApi(ref.watch(authedDioProvider));
});

final cityLeagueProvider = FutureProvider.autoDispose<List<CityLeagueEntry>>((ref) {
  final api = ref.watch(statsApiProvider);
  return api.getCityLeague();
});
