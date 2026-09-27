import '../../../../core/errors/result.dart';
import '../repositories/routine_repository.dart';

/// Removes a routine. Its habits and their check-offs survive.
class DeleteRoutine {
  const DeleteRoutine(this._repository);

  final RoutineRepository _repository;

  Future<Result<void>> call(String routineId) =>
      _repository.deleteRoutine(routineId);
}
