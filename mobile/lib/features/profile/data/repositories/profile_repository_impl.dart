import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

/// The only place where profile exceptions become failures.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required AuthLocalDataSource authLocalDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _authLocal = authLocalDataSource,
        _networkInfo = networkInfo;

  final ProfileRemoteDataSource _remote;
  final AuthLocalDataSource _authLocal;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<User>> updateProfile({
    String? userName,
    String? userPhone,
    String? avatarUrl,
  }) {
    return _guard(() async {
      final updatedUser = await _remote.updateProfile(
        userName: userName,
        userPhone: userPhone,
        avatarUrl: avatarUrl,
      );
      await _authLocal.cacheUser(updatedUser);
      return updatedUser;
    });
  }

  /// Checks connectivity, runs [call], and converts anything thrown into a
  /// [Failure].
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    if (!await _networkInfo.isConnected) {
      return const ResultError(NetworkFailure());
    }
    try {
      return Success(await call());
    } on AppException catch (exception) {
      return ResultError(_toFailure(exception));
    } on Object catch (error, stackTrace) {
      Logger.error('Profile request failed', error: error, stackTrace: stackTrace);
      return const ResultError(UnexpectedFailure());
    }
  }

  Failure _toFailure(AppException exception) => switch (exception) {
        NetworkException() => NetworkFailure(exception.message),
        UnauthorizedException() => AuthFailure(exception.message),
        ValidationException(:final errors) =>
          ValidationFailure(exception.message, errors: errors),
        NotFoundException() => NotFoundFailure(exception.message),
        CacheException() => CacheFailure(exception.message),
        ServerException(:final statusCode) =>
          ServerFailure(exception.message, statusCode: statusCode),
      };
}
