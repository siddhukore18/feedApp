import 'package:feed_app/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_shimmer.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Triggers loadMore when user is within 300px of the bottom.
  /// Using a threshold prevents the jarring "load exactly at bottom" UX.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 300.0;

    if (currentScroll >= maxScroll - threshold) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: _buildAppBar(),
      body: _buildBody(feedState, screenWidth),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F1A),
      elevation: 0,
      title: const Text(
        'FEED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF6D28D9),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FeedState feedState, double screenWidth) {
    // ── Initial loading state ──────────────────────────────
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const FeedShimmer();
    }

    // ── Error state with empty feed ───────────────────────
    if (feedState.error != null && feedState.posts.isEmpty) {
      return _buildErrorState(feedState.error!);
    }

    // ── Empty state ───────────────────────────────────────
    if (!feedState.isLoading && feedState.posts.isEmpty) {
      return _buildEmptyState();
    }

    // ── Main feed ─────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: const Color(0xFF6D28D9),
      backgroundColor: const Color(0xFF1E1E2E),
      child: CustomScrollView(
        controller: _scrollController,
        // Physics that allows pull-to-refresh even when content
        // doesn't fill the viewport
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Post list ─────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = feedState.posts[index];
              return PostCard(
                // Providing key ensures Flutter reuses the
                // same element for the same post during scrolling,
                // preventing unnecessary widget tree rebuilds
                key: ValueKey(post.id),
                post: post,
                displayWidth: screenWidth,
              );
            }, childCount: feedState.posts.length),
          ),

          // ── Load more indicator / end of feed ─────────
          SliverToBoxAdapter(child: _buildFooter(feedState)),
        ],
      ),
    );
  }

  Widget _buildFooter(FeedState feedState) {
    if (feedState.isFetchingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6D28D9),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!feedState.hasMore && feedState.posts.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            '— You\'ve seen it all —',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 80);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Could not load feed',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(feedProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: Colors.white30, size: 60),
          SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
