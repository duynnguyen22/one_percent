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
}
