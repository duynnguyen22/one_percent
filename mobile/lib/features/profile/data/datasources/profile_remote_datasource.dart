import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

/// Profile operations against the NestJS backend.
///
/// Throws [AppException] on failure — mapping to a `Failure` is the
/// repository's job.
abstract interface class ProfileRemoteDataSource {
  /// `PATCH /profile` — updates optional user profile fields.
  Future<UserModel> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  });

  /// `POST /profile/avatar` — uploads the image at [filePath] as the user's
  /// avatar and returns the user with the new `avatarUrl`.
  Future<UserModel> uploadAvatar(String filePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<UserModel> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiConstants.profile,
      data: {
        if (userName != null) 'userName': userName,
        if (userPhone != null) 'userPhone': userPhone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );

    final userData = response['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  @override
  Future<UserModel> uploadAvatar(String filePath) async {
    final response = await _client.upload<Map<String, dynamic>>(
      ApiConstants.profileAvatar,
      filePath: filePath,
    );

    final userData = response['user'] as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }
}
