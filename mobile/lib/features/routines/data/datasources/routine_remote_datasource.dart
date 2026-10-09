import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/routine_draft.dart';
import '../models/routine_model.dart';

/// Routine CRUD against the NestJS backend.
///
/// Unlike `/habits`, every `/routines` response is wrapped as
/// `{ statusCode, message, data }`; this class unwraps `data`.
///
/// Throws [AppException] on failure — mapping to a `Failure` is the
/// repository's job.
abstract interface class RoutineRemoteDataSource {
  /// `GET /routines[?date=yyyy-MM-dd]`
  Future<List<RoutineModel>> getRoutines({DateTime? date});

  /// `POST /routines`
  Future<RoutineModel> createRoutine(RoutineDraft draft);

  /// `PATCH /routines/:id` — sends the whole draft, steps included.
  Future<RoutineModel> updateRoutine(String routineId, RoutineDraft draft);

  /// `DELETE /routines/:id`
  Future<void> deleteRoutine(String routineId);
}

class RoutineRemoteDataSourceImpl implements RoutineRemoteDataSource {
  const RoutineRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<RoutineModel>> getRoutines({DateTime? date}) async {
    final json = await _client.get<Map<String, dynamic>>(
      ApiConstants.routines,
      queryParameters: date == null
          ? null
          : {'date': AppDateUtils.toApiDate(date)},
    );
    return (_data(json) as List<dynamic>)
        .map((row) => RoutineModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RoutineModel> createRoutine(RoutineDraft draft) async {
    final json = await _client.post<Map<String, dynamic>>(
      ApiConstants.routines,
      data: _toBody(draft),
    );
    return RoutineModel.fromJson(_data(json) as Map<String, dynamic>);
  }

  @override
  Future<RoutineModel> updateRoutine(
    String routineId,
    RoutineDraft draft,
  ) async {
    final json = await _client.patch<Map<String, dynamic>>(
      ApiConstants.routine(routineId),
      data: _toBody(draft),
    );
    return RoutineModel.fromJson(_data(json) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await _client.delete<Map<String, dynamic>>(ApiConstants.routine(routineId));
  }

  Object? _data(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data == null) {
      throw const ServerException('The server returned an empty response.');
    }
    return data;
  }

  /// Array position is the step order on the backend. A blank cadence is
  /// omitted because the DTO requires 1–30 characters when present.
  Map<String, dynamic> _toBody(RoutineDraft draft) {
    final cadence = draft.cadence.trim();
    return {
      'name': draft.name,
      'description': draft.description,
      'color': draft.color,
      if (cadence.isNotEmpty) 'cadence': cadence,
      'steps': [
        for (final step in draft.steps)
          {
            'habitId': step.habitId,
            'durationMinutes': step.durationMinutes,
            if (step.guides != null)
              'guides': [
                for (final guide in step.guides!)
                  {
                    'title': guide.title,
                    'durationSeconds': guide.durationSeconds,
                  },
              ],
          },
      ],
    };
  }
}
