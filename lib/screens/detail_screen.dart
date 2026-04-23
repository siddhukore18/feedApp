import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/extensions.dart';
import '../models/post_model.dart';
import '../providers/like_provider.dart';
import '../services/download_service.dart';
import '../widgets/like_button.dart';
import '../widgets/tiered_image.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Hero Image with Tiered Loading ────────────────
          Expanded(child: _buildHeroImage(post)),

          // ── Action Bar ────────────────────────────────────
          _buildActionBar(context, post),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        '#${widget.post.id.substring(0, 8).toUpperCase()}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildHeroImage(Post post) {
    if (post.mediaThumbUrl == null) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white30,
            size: 60,
          ),
        ),
      );
    }

    return Hero(
      // Must match the tag used in PostCard for the animation to work
      tag: '${AppConstants.heroTagPrefix}${post.id}',
      // flightShuttleBuilder ensures smooth transition between
      // thumbnail in feed and detail image
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) => ClipRRect(
                // Animate border radius during Hero flight
                borderRadius: BorderRadius.circular(
                  Tween<double>(begin: 20, end: 0).evaluate(animation),
                ),
                child: TieredDetailImage(
                  thumbUrl: post.mediaThumbUrl!,
                  mobileUrl: post.mediaMobileUrl ?? post.mediaThumbUrl!,
                ),
              ),
            );
          },
      child: TieredDetailImage(
        thumbUrl: post.mediaThumbUrl!,
        mobileUrl: post.mediaMobileUrl ?? post.mediaThumbUrl!,
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, Post post) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Like Button ────────────────────────────────
          LikeButton(post: post),

          const Spacer(),

          // ── Download High-Res Button ───────────────────
          // Only shown if raw URL exists.
          // Only fires network request on explicit tap.
          if (post.mediaRawUrl != null)
            _buildDownloadButton(context, post.mediaRawUrl!),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, String rawUrl) {
    return ElevatedButton.icon(
      onPressed: _isDownloading
          ? null
          : () => _downloadHighRes(context, rawUrl),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6D28D9),
        disabledBackgroundColor: const Color(0xFF3D1E7A),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: _isDownloading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(
        _isDownloading ? 'Downloading...' : 'Download High-Res',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _downloadHighRes(BuildContext context, String rawUrl) async {
    setState(() => _isDownloading = true);
    try {
      await DownloadService.downloadHighRes(rawUrl);
      if (mounted) {
        context.showSuccessSnackBar(AppConstants.downloadSuccessMessage);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(AppConstants.downloadErrorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}
