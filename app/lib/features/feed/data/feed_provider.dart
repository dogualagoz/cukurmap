import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reports/data/reports_api.dart';
import '../../reports/models/report.dart';

class FeedState {
  const FeedState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.sort,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
  });

  const FeedState.initial()
      : items = const [],
        cursor = null,
        hasMore = true,
        sort = FeedSort.recent,
        isLoading = true,
        isLoadingMore = false,
        error = null;

  final List<FeedItem> items;
  final FeedCursor? cursor;
  final bool hasMore;
  final FeedSort sort;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  FeedState copyWith({
    List<FeedItem>? items,
    FeedCursor? cursor,
    bool clearCursor = false,
    bool? hasMore,
    FeedSort? sort,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return FeedState(
      items: items ?? this.items,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Feed sekmesi: sayfalı liste + sıralama (yeni/popüler) + oylama sonrası
/// yerinde güncelleme. `AuthNotifier`'daki gibi elle yönetilen bir Notifier —
/// AsyncNotifier kullanılmadı çünkü "daha fazla yükle" sırasında mevcut
/// listenin ekranda kalması gerekiyor (AsyncValue.loading tüm listeyi gizler).
class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    Future.microtask(_load);
    return const FeedState.initial();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(reportsApiProvider).getFeed(sort: state.sort);
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

  Future<void> setSort(FeedSort sort) async {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
    await _load();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref.read(reportsApiProvider).getFeed(
            sort: state.sort,
            cursor: state.cursor,
          );
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

  Future<void> vote(String reportId, VoteType type) async {
    final updated = await ref.read(reportsApiProvider).vote(reportId, type);
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.report.id == reportId) item.copyWithReport(updated) else item,
      ],
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
