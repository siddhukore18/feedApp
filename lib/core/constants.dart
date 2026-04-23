class AppConstants {
  // Hardcoded anonymous user for testing
  static const String testUserId = 'user_123';

  // Pagination
  static const int pageSize = 10;

  // Like debounce duration - prevents spam clicking from
  // firing too many RPC calls while keeping UI instant
  static const Duration likeDebounce = Duration(milliseconds: 800);

  // Image cache dimensions - prevents OOM by capping
  // decoded pixel buffer to exactly what's rendered on screen
  static const int thumbCacheWidth = 600; // 2x for high-DPI screens

  // Hero animation tag prefix
  static const String heroTagPrefix = 'post_hero_';

  // Snackbar messages
  static const String likeErrorMessage =
      'Could not update like. Please check your connection.';
  static const String downloadSuccessMessage = 'High-res image saved!';
  static const String downloadErrorMessage = 'Download failed. Try again.';
}
