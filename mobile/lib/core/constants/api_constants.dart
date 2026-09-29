import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Backend base URL and endpoint paths.
///
/// Paths mirror the NestJS controllers in `backend/src`. Keep them here rather
/// than inline in data sources so a route rename is a one-line change.
abstract final class ApiConstants {
  /// Overridable at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int _port = 3001;

  /// Resolved base URL.
  ///
  /// The Android emulator reaches the host machine on `10.0.2.2`, not
  /// `localhost`, so debug builds pick the host per platform.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$_port';
    return 'http://localhost:$_port';
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// File uploads push far more bytes than JSON requests.
  static const Duration uploadSendTimeout = Duration(seconds: 60);

  // Auth — backend/src/auth/auth.controller.ts
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Password reset, in the order the user walks them.
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';

  // Habits — backend/src/habit/habit.controller.ts
  static const String habits = '/habits';
  static String habit(String id) => '/habits/$id';

  // Habit entries — backend/src/entries/entries.controller.ts
  static String entries(String habitId) => '/habits/$habitId/entries';
  static String entry(String habitId, String date) =>
      '/habits/$habitId/entries/$date';

  // Routines — backend/src/routine/routine.controller.ts
  static const String routines = '/routines';
  static String routine(String id) => '/routines/$id';

  // Profile — backend/src/profile/profile.controller.ts
  static const String profile = '/profile';
  static const String profileAvatar = '/profile/avatar';

  /// Turns a media path stored by the backend (e.g. `/uploads/avatars/x.jpg`)
  /// into a URL this device can load. Absolute URLs pass through unchanged.
  ///
  /// The backend stores paths rather than full URLs because the host differs
  /// per device — `10.0.2.2` on the Android emulator, `localhost` on iOS.
  static String mediaUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return '$baseUrl$pathOrUrl';
  }

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
