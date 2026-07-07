import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../reports/models/report.dart';
import 'data/feed_provider.dart';
import 'feed_item_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  Future<void> _vote(String reportId, VoteType type) async {
    try {
      await ref.read(feedProvider.notifier).vote(reportId, type);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.voteError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    Strings.tabFeed,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.bgDark),
                  ),
                  const Spacer(),
                  _SortToggle(
                    sort: state.sort,
                    onChanged: (sort) => ref.read(feedProvider.notifier).setSort(sort),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(Strings.feedLoadError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(feedProvider.notifier).refresh(),
                child: const Text(Strings.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Text(Strings.feedEmpty, style: TextStyle(color: AppTheme.textSecondaryLight)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final item = state.items[index];
          return FeedItemCard(
            item: item,
            onVote: (type) => _vote(item.report.id, type),
          );
        },
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.sort, required this.onChanged});

  final FeedSort sort;
  final ValueChanged<FeedSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortOption(label: Strings.feedSortRecent, selected: sort == FeedSort.recent, onTap: () => onChanged(FeedSort.recent)),
          _SortOption(label: Strings.feedSortScore, selected: sort == FeedSort.score, onTap: () => onChanged(FeedSort.score)),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.bgDark : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.bgLight : AppTheme.textSecondaryLightAlt,
          ),
        ),
      ),
    );
  }
}
