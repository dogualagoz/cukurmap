import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reports/data/reports_api.dart';
import '../../reports/models/report.dart';

class MyReportsState {
  const MyReportsState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
  });

  const MyReportsState.initial()
      : items = const [],
        cursor = null,
        hasMore = true,
        isLoading = true,
        isLoadingMore = false,
        error = null;

  final List<ReportDetail> items;
  final MyReportsCursor? cursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  MyReportsState copyWith({
    List<ReportDetail>? items,
    MyReportsCursor? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return MyReportsState(
      items: items ?? this.items,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Profildeki "Bildirimlerim" listesi — FeedNotifier ile aynı desen:
/// elle yönetilen Notifier, çünkü "daha fazla yükle" sırasında mevcut
/// listenin ekranda kalması gerekiyor.
class MyReportsNotifier extends Notifier<MyReportsState> {
  @override
  MyReportsState build() {
    Future.microtask(_load);
    return const MyReportsState.initial();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(reportsApiProvider).getMyReports();
      state = state.copyWith(
        items: page.items,
        cursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() => _load();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref.read(reportsApiProvider).getMyReports(cursor: state.cursor);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        cursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasMore: page.nextCursor != null,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final myReportsProvider =
    NotifierProvider<MyReportsNotifier, MyReportsState>(MyReportsNotifier.new);
