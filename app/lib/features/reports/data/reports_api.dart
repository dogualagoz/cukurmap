import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../models/report.dart';

class ReportsApi {
  ReportsApi(this._dio);

  final Dio _dio;

  Future<ReportDetail> createReport({
    required double lat,
    required double lng,
    required int severity,
    ReportCategory? category,
    String? description,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    final form = FormData.fromMap({
      'lat': lat,
      'lng': lng,
      'severity': severity,
      if (category != null) 'category': category.wireName,
      if (description != null && description.isNotEmpty) 'description': description,
      if (photoBytes != null)
        'photo': MultipartFile.fromBytes(photoBytes, filename: photoFilename ?? 'photo.jpg'),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>('/reports', data: form);
      return ReportDetail.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final nested = e.response?.data is Map ? (e.response!.data as Map)['message'] : null;
        if (nested is Map) {
          throw ReportConflictException(
            message: nested['message'] as String? ?? 'Bu çukur zaten bildirilmiş',
            nearbyReportId: nested['nearbyReportId'] as String,
          );
        }
      }
      rethrow;
    }
  }

  Future<List<ReportMarker>> getReports({
    required double minLng,
    required double minLat,
    required double maxLng,
    required double maxLat,
    int? severity,
    ReportStatus? status,
    DateTime? since,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/reports',
      queryParameters: {
        'bbox': '$minLng,$minLat,$maxLng,$maxLat',
        if (severity != null) 'severity': severity,
        if (status != null) 'status': status.wireName,
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );
    return (response.data ?? [])
        .map((e) => ReportMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReportDetail> getReport(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/reports/$id');
    return ReportDetail.fromJson(response.data!);
  }

  Future<ReportDetail> vote(String id, VoteType type) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/reports/$id/votes',
      data: {'type': type.wireName},
    );
    return ReportDetail.fromJson(response.data!);
  }

  Future<FeedPage> getFeed({
    FeedSort sort = FeedSort.recent,
    int limit = 20,
    double? lat,
    double? lng,
    FeedCursor? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reports/feed',
      queryParameters: {
        'sort': sort.wireName,
        'limit': limit,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (cursor != null) ...{
          'cursorCreatedAt': cursor.createdAt,
          'cursorId': cursor.id,
          'cursorScore': cursor.score,
        },
      },
    );
    return FeedPage.fromJson(response.data!);
  }

  Future<MyReportsPage> getMyReports({
    int limit = 20,
    MyReportsCursor? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users/me/reports',
      queryParameters: {
        'limit': limit,
        if (cursor != null) ...{
          'cursorCreatedAt': cursor.createdAt,
          'cursorId': cursor.id,
        },
      },
    );
    return MyReportsPage.fromJson(response.data!);
  }
}

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(ref.watch(authedDioProvider));
});

/// Harita bbox'ı + filtreler — Dart record'ları yapısal eşitliğe sahip
/// olduğu için doğrudan FutureProvider.family key'i olarak kullanılabilir.
typedef ReportsQuery = ({
  double minLng,
  double minLat,
  double maxLng,
  double maxLat,
  int? severity,
  ReportStatus? status,
});

final reportMarkersProvider =
    FutureProvider.autoDispose.family<List<ReportMarker>, ReportsQuery>((ref, query) {
  final api = ref.watch(reportsApiProvider);
  return api.getReports(
    minLng: query.minLng,
    minLat: query.minLat,
    maxLng: query.maxLng,
    maxLat: query.maxLat,
    severity: query.severity,
    status: query.status,
  );
});

final reportDetailProvider = FutureProvider.autoDispose.family<ReportDetail, String>((ref, id) {
  final api = ref.watch(reportsApiProvider);
  return api.getReport(id);
});
