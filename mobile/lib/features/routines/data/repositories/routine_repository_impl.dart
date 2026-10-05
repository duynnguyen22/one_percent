import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_draft.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_remote_datasource.dart';

/// The only place where routine exceptions become failures.
class RoutineRepositoryImpl implements RoutineRepository {
  const RoutineRepositoryImpl({
    required RoutineRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remote = remoteDataSource,
       _networkInfo = networkInfo;

  final RoutineRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<List<Routine>>> getRoutines({DateTime? date}) =>
      _guard(() => _remote.getRoutines(date: date));

  @override
  Future<Result<Routine>> createRoutine(RoutineDraft draft) =>
      _guard(() => _remote.createRoutine(draft));

  @override
  Future<Result<Routine>> updateRoutine(String routineId, RoutineDraft draft) =>
      _guard(() => _remote.updateRoutine(routineId, draft));

  @override
  Future<Result<void>> deleteRoutine(String routineId) =>
      _guard(() => _remote.deleteRoutine(routineId));

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
      Logger.error(
        'Routine request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const ResultError(UnexpectedFailure());
    }
  }

  Failure _toFailure(AppException exception) => switch (exception) {
    NetworkException() => NetworkFailure(exception.message),
    UnauthorizedException() => AuthFailure(exception.message),
    ValidationException(:final errors) => ValidationFailure(
      exception.message,
      errors: errors,
    ),
    NotFoundException() => NotFoundFailure(exception.message),
    CacheException() => CacheFailure(exception.message),
    ServerException(:final statusCode) => ServerFailure(
      exception.message,
      statusCode: statusCode,
    ),
  };
}
