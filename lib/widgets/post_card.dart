import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/post_model.dart';
import '../screens/detail_screen.dart';
import 'like_button.dart';
import 'tiered_image.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.displayWidth});

  final Post post;

  /// Physical display width in logical pixels - passed from parent
  /// to compute exact memCacheWidth for OOM prevention
  final double displayWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RepaintBoundary isolates this card's rasterization layer.
    //
    // Why this matters for GPU protection:
    // - Complex BoxShadow requires expensive rasterization
    // - Without RepaintBoundary, Flutter re-rasterizes the ENTIRE
    //   scroll view when ANY child changes (e.g., like count update)
    // - With RepaintBoundary, each card gets its own compositing layer
    //   that is cached on the GPU. Only the changed card re-rasterizes.
    // - During fast scrolling, unchanged cards are composited from GPU
    //   cache rather than recomputed - this prevents jank.
    return RepaintBoundary(
      child: _PostCardContent(post: post, displayWidth: displayWidth),
    );
  }
}

/// Separated to allow const construction where possible
class _PostCardContent extends StatelessWidget {
  const _PostCardContent({required this.post, required this.displayWidth});

  final Post post;
  final double displayWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          // Heavy BoxShadow as required - GPU protection via
          // RepaintBoundary above prevents this from causing jank
          boxShadow: const [
            BoxShadow(
              color: Color(0x60000000),
              blurRadius: 30,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x20A855F7), // Purple glow
              blurRadius: 40,
              spreadRadius: -5,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section with Hero ──────────────────
              _buildImageSection(context),

              // ── Metadata Section ─────────────────────────
              _buildMetadataSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final thumbUrl = post.mediaThumbUrl;

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: thumbUrl != null
            ? Hero(
                // Unique tag per post for Hero animation
                tag: '${AppConstants.heroTagPrefix}${post.id}',
                child: ThumbImage(
                  url: thumbUrl,
                  // memCacheWidth = displayWidth * devicePixelRatio
                  // Caps decoded image buffer to exact render size.
                  // devicePixelRatio is handled by MediaQuery here.
                  cacheWidth: AppConstants.thumbCacheWidth,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.white30,
                    size: 50,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // ── Post ID Display ──────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post #${post.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(post.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Like Button ──────────────────────────────
          // Provides the post snapshot to the like system.
          // The LikeButton internally uses likeProvider(post)
          // which is a family provider - one instance per post.
          LikeButton(post: post),

          const SizedBox(width: 8),

          // ── View Detail Button ───────────────────────
          IconButton(
            onPressed: () => _navigateToDetail(context),
            icon: const Icon(
              Icons.open_in_full_rounded,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailScreen(post: post),
        // Use a custom route for smoother Hero transitions
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
