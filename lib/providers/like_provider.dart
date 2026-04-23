import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/post_model.dart';
import 'feed_provider.dart';

/// Per-post like state - isolated so rebuilds don't cascade
/// to the entire feed list
class LikeState {
  const LikeState({
    required this.isLiked,
    required this.likeCount,
    this.isProcessing = false,
  });

  final bool isLiked;
  final int likeCount;

  /// True while the debounce timer is pending or RPC is in-flight.
  /// Used to show a subtle loading indicator without blocking UI.
  final bool isProcessing;

  LikeState copyWith({bool? isLiked, int? likeCount, bool? isProcessing}) {
    return LikeState(
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// LikeNotifier per post - handles:
/// 1. Instant optimistic toggle
/// 2. Debouncing to prevent spam (anti spam-click protection)
/// 3. Background RPC execution
/// 4. Rollback on network failure
class LikeNotifier extends StateNotifier<LikeState> {
  LikeNotifier({required this.post, required this.ref})
    : super(
        LikeState(
          isLiked: post.isLikedByCurrentUser,
          likeCount: post.likeCount,
        ),
      );

  final Post post;
  final Ref ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Debounce timer - the key mechanism for spam-click protection.
  ///
  /// How it works:
  /// - Every tap immediately updates UI (optimistic)
  /// - The *network call* is delayed by [AppConstants.likeDebounce]
  /// - If another tap happens before timer fires, timer resets
  /// - Only ONE network call fires after the user stops tapping
  /// - The final UI state (liked or not) is exactly what gets sent to DB
  ///
  /// This means 15 rapid clicks = exactly 1 network call,
  /// and the DB ends up in the correct final state.
  Timer? _debounceTimer;

  /// Tracks the "committed" server state for rollback purposes
  bool _serverIsLiked = false;
  int _serverLikeCount = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void toggle(void Function(String message) onError) {
    // ── Step 1: Instant UI update ──────────────────────────
    final newIsLiked = !state.isLiked;
    final newCount = newIsLiked ? state.likeCount + 1 : state.likeCount - 1;

    state = state.copyWith(
      isLiked: newIsLiked,
      likeCount: newCount,
      isProcessing: true,
    );

    // Propagate to feed list immediately for list-level consistency
    ref
        .read(feedProvider.notifier)
        .updatePostLike(
          postId: post.id,
          isLiked: newIsLiked,
          likeCount: newCount,
        );

    // ── Step 2: Debounce the network call ──────────────────
    // Cancel any pending timer - this is the spam-click guard
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.likeDebounce, () {
      _commitToServer(onError);
    });
  }

  /// Fires the actual RPC after debounce settles
  Future<void> _commitToServer(void Function(String message) onError) async {
    // Capture current optimistic state as the "intended" final state
    final intendedIsLiked = state.isLiked;
    final intendedCount = state.likeCount;

    // Save last known server state before this attempt
    _serverIsLiked = !intendedIsLiked; // inverse of what we're committing
    _serverLikeCount = intendedIsLiked ? intendedCount - 1 : intendedCount + 1;

    try {
      // The toggle_like RPC is idempotent and handles
      // concurrent calls via the unique_violation catch block in SQL
      await _supabase.rpc(
        'toggle_like',
        params: {'p_post_id': post.id, 'p_user_id': AppConstants.testUserId},
      );

      // Success: update server baseline
      _serverIsLiked = intendedIsLiked;
      _serverLikeCount = intendedCount;

      state = state.copyWith(isProcessing: false);

      // Re-sync feed with confirmed server state
      ref
          .read(feedProvider.notifier)
          .updatePostLike(
            postId: post.id,
            isLiked: intendedIsLiked,
            likeCount: intendedCount,
          );
    } catch (e) {
      // ── Step 3: Rollback on failure ──────────────────────
      // Revert optimistic state to last known server state
      state = state.copyWith(
        isLiked: _serverIsLiked,
        likeCount: _serverLikeCount,
        isProcessing: false,
      );

      // Sync rollback to feed list
      ref
          .read(feedProvider.notifier)
          .updatePostLike(
            postId: post.id,
            isLiked: _serverIsLiked,
            likeCount: _serverLikeCount,
          );

      onError(AppConstants.likeErrorMessage);
    }
  }
}

/// Family provider - one LikeNotifier instance per post
/// .autoDispose ensures cleanup when post scrolls off screen
final likeProvider = StateNotifierProvider.family
    .autoDispose<LikeNotifier, LikeState, Post>(
      (ref, post) => LikeNotifier(post: post, ref: ref),
    );
