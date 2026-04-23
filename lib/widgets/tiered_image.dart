// import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a cached thumbnail with strict memory width cap.
///
/// The [memCacheWidth] parameter tells the image library to
/// decode the image at exactly [cacheWidth] pixels wide,
/// preventing the raw 300px WebP from being decoded into a
/// full RGBA buffer that's larger than needed.
///
/// This is the primary OOM prevention mechanism for the feed.
class ThumbImage extends StatelessWidget {
  const ThumbImage({
    super.key,
    required this.url,
    required this.cacheWidth,
    this.fit = BoxFit.cover,
  });

  final String url;
  final int cacheWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: cacheWidth,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade900,
        child: const Icon(
          Icons.broken_image_rounded,
          color: Colors.white38,
          size: 40,
        ),
      ),
    );
  }
}

/// Tiered image for the Detail Screen:
/// 1. Shows cached thumbnail immediately (from CachedNetworkImage cache)
/// 2. Fades in the mobile-quality image when loaded
/// 3. Never loads raw until explicitly requested
class TieredDetailImage extends StatefulWidget {
  const TieredDetailImage({
    super.key,
    required this.thumbUrl,
    required this.mobileUrl,
  });

  final String thumbUrl;
  final String mobileUrl;

  @override
  State<TieredDetailImage> createState() => _TieredDetailImageState();
}

class _TieredDetailImageState extends State<TieredDetailImage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Thumbnail - shown instantly from cache
        CachedNetworkImage(
          imageUrl: widget.thumbUrl,
          fit: BoxFit.cover,
          // No memCacheWidth here - already in cache from feed
        ),

        // Layer 2: Mobile quality - fades in over thumbnail
        CachedNetworkImage(
          imageUrl: widget.mobileUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 400),
          placeholder: (context, url) =>
              const SizedBox.shrink(), // Let thumb show through
          errorWidget: (context, url, error) =>
              const SizedBox.shrink(), // Graceful degradation
        ),
      ],
    );
  }
}
