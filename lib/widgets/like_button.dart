import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/extensions.dart';
import '../models/post_model.dart';
import '../providers/like_provider.dart';

class LikeButton extends ConsumerWidget {
  const LikeButton({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch per-post like state - only this widget rebuilds on change,
    // not the entire card or list
    final likeState = ref.watch(likeProvider(post));

    return GestureDetector(
      onTap: () {
        // Toggle with error callback - rollback happens inside notifier
        ref
            .read(likeProvider(post).notifier)
            .toggle((message) => context.showErrorSnackBar(message));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: likeState.isLiked
              ? Colors.red.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated heart icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                likeState.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(likeState.isLiked),
                color: likeState.isLiked ? Colors.red : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 6),
            // Animated count
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '${likeState.likeCount}',
                key: ValueKey(likeState.likeCount),
                style: TextStyle(
                  color: likeState.isLiked ? Colors.red : Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Subtle processing indicator
            if (likeState.isProcessing) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: likeState.isLiked ? Colors.red : Colors.white38,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
