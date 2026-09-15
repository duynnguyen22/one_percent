import '../../../../core/errors/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/profile_repository.dart';

/// Updates the signed-in user's profile details.
class UpdateProfile {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<User>> call({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  }) {
    return _repository.updateProfile(
      userName: userName?.trim(),
      userPhone: userPhone?.trim(),
      avatarUrl: avatarUrl?.trim(),
    );
  }
}
