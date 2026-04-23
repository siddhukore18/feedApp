import 'package:flutter/foundation.dart';

/// Immutable post model - freezed-style manual implementation
/// Using copyWith for state mutations without freezed dependency
@immutable
class Post {
  const Post({
    required this.id,
    required this.createdAt,
    required this.likeCount,
    this.mediaThumbUrl,
    this.mediaMobileUrl,
    this.mediaRawUrl,
    this.isLikedByCurrentUser = false,
  });

  final String id;
  final DateTime createdAt;
  final int likeCount;
  final String? mediaThumbUrl;
  final String? mediaMobileUrl;
  final String? mediaRawUrl;

  /// Local-only flag: not in DB, derived from user_likes join
  final bool isLikedByCurrentUser;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      mediaThumbUrl: json['media_thumb_url'] as String?,
      mediaMobileUrl: json['media_mobile_url'] as String?,
      mediaRawUrl: json['media_raw_url'] as String?,
      // user_likes is a joined list; check if current user exists
      isLikedByCurrentUser: _parseIsLiked(json['user_likes']),
    );
  }

  static bool _parseIsLiked(dynamic userLikes) {
    if (userLikes == null) return false;
    if (userLikes is List) return userLikes.isNotEmpty;
    return false;
  }

  Post copyWith({
    String? id,
    DateTime? createdAt,
    int? likeCount,
    String? mediaThumbUrl,
    String? mediaMobileUrl,
    String? mediaRawUrl,
    bool? isLikedByCurrentUser,
  }) {
    return Post(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      mediaThumbUrl: mediaThumbUrl ?? this.mediaThumbUrl,
      mediaMobileUrl: mediaMobileUrl ?? this.mediaMobileUrl,
      mediaRawUrl: mediaRawUrl ?? this.mediaRawUrl,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          likeCount == other.likeCount &&
          isLikedByCurrentUser == other.isLikedByCurrentUser;

  @override
  int get hashCode =>
      id.hashCode ^ likeCount.hashCode ^ isLikedByCurrentUser.hashCode;

  @override
  String toString() =>
      'Post(id: $id, likes: $likeCount, liked: $isLikedByCurrentUser)';
}

/// Feed state holding paginated posts
@immutable
class FeedState {
  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasMore;
  final String? error;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}
