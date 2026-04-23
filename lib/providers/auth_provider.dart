import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';

/// Simple provider for current user ID.
/// In a real app this would come from Supabase Auth.
/// Using hardcoded value per project spec.
final currentUserIdProvider = Provider<String>((_) => AppConstants.testUserId);
