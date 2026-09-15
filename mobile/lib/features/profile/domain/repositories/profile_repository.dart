import '../../../../core/errors/result.dart';
import '../../../auth/domain/entities/user.dart';

/// Contract for profile modifications.
abstract interface class ProfileRepository {
  /// Updates user profile details against the remote API and synchronises
  /// local session caches.
  Future<Result<User>> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  });
}
