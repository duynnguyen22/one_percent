import '../../../../core/errors/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/profile_repository.dart';

/// Replaces the signed-in user's avatar with the image at a local file path.
class UploadAvatar {
  const UploadAvatar(this._repository);

  final ProfileRepository _repository;

  Future<Result<User>> call(String filePath) =>
      _repository.uploadAvatar(filePath);
}
