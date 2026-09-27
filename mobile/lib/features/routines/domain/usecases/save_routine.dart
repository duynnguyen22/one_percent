import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/routine.dart';
import '../entities/routine_draft.dart';
import '../repositories/routine_repository.dart';

/// Creates a routine, or replaces an existing one when given its id.
///
/// The rules mirror `CreateRoutineDto` so an obviously bad draft fails before
/// it costs a round trip. The backend still validates; this is not the guard.
class SaveRoutine {
  const SaveRoutine(this._repository);

  final RoutineRepository _repository;

  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxSteps = 20;
  static const int minStepMinutes = 1;
  static const int maxStepMinutes = 180;

  Future<Result<Routine>> call(RoutineDraft draft, {String? routineId}) async {
    final failure = _validate(draft);
    if (failure != null) return ResultError(failure);

    final trimmed = draft.copyWith(name: draft.name.trim());
    return routineId == null
        ? _repository.createRoutine(trimmed)
        : _repository.updateRoutine(routineId, trimmed);
  }

  ValidationFailure? _validate(RoutineDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return const ValidationFailure('Give your routine a name.');
    }
    if (name.length > maxNameLength) {
      return const ValidationFailure(
        'Routine names are limited to 100 characters.',
      );
    }
    if (draft.description.length > maxDescriptionLength) {
      return const ValidationFailure(
        'Descriptions are limited to 500 characters.',
      );
    }
    if (draft.steps.isEmpty) {
      return const ValidationFailure('Add at least one habit to the routine.');
    }
    if (draft.steps.length > maxSteps) {
      return const ValidationFailure('A routine can hold up to 20 habits.');
    }
    final habitIds = draft.steps.map((s) => s.habitId).toSet();
    if (habitIds.length != draft.steps.length) {
      return const ValidationFailure(
        'Each habit can appear only once in a routine.',
      );
    }
    final badDuration = draft.steps.any(
      (s) =>
          s.durationMinutes < minStepMinutes ||
          s.durationMinutes > maxStepMinutes,
    );
    if (badDuration) {
      return const ValidationFailure(
        'Each step must last between 1 and 180 minutes.',
      );
    }
    return null;
  }
}
