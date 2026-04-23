import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/post_model.dart';

/// Main feed provider - handles pagination, refresh, and
/// optimistic post-level state mutations
class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    _loadInitial();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  int _currentPage = 0;

  /// ── Initial Load ──────────────────────────────────────────
  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _fetchPage(page: 0);
      _currentPage = 0;
      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == AppConstants.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// ── Pull-to-Refresh ───────────────────────────────────────
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _fetchPage(page: 0);
      _currentPage = 0;
      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == AppConstants.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// ── Load More (infinite scroll) ───────────────────────────
  Future<void> loadMore() async {
    // Guard: don't double-fetch or fetch when exhausted
    if (state.isFetchingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isFetchingMore: true);
    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _fetchPage(page: nextPage);

      // Merge, deduplicating by id (handles edge-case where
      // a new post was inserted between page fetches)
      final existingIds = state.posts.map((p) => p.id).toSet();
      final uniqueNew = newPosts
          .where((p) => !existingIds.contains(p.id))
          .toList();

      _currentPage = nextPage;
      state = state.copyWith(
        posts: [...state.posts, ...uniqueNew],
        isFetchingMore: false,
        hasMore: newPosts.length == AppConstants.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false, error: e.toString());
    }
  }

  /// ── Core Fetch ────────────────────────────────────────────
  Future<List<Post>> _fetchPage({required int page}) async {
    final from = page * AppConstants.pageSize;
    final to = from + AppConstants.pageSize - 1;

    // Fetch posts with a left-join to user_likes so we know
    // which posts the current user has already liked.
    // This single query avoids N+1 requests.
    final response = await _supabase
        .from('posts')
        .select('''
          id,
          created_at,
          media_thumb_url,
          media_mobile_url,
          media_raw_url,
          like_count,
          user_likes!left(user_id)
        ''')
        .eq('user_likes.user_id', AppConstants.testUserId)
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// ── Optimistic Like Mutation ──────────────────────────────
  /// Called by LikeNotifier after it computes the new state.
  /// This keeps feed list in sync without a full re-fetch.
  void updatePostLike({
    required String postId,
    required bool isLiked,
    required int likeCount,
  }) {
    state = state.copyWith(
      posts: state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLikedByCurrentUser: isLiked,
            likeCount: likeCount,
          );
        }
        return post;
      }).toList(),
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(),
);
