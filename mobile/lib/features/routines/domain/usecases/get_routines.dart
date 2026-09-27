import '../../../../core/errors/result.dart';
import '../../../../core/utils/date_utils.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

/// Loads the user's routines, with each step's check-off state for one day.
class GetRoutines {
  const GetRoutines(this._repository);

  final RoutineRepository _repository;

  /// [date] defaults to today, which is what every current caller wants.
  Future<Result<List<Routine>>> call({DateTime? date}) {
    return _repository.getRoutines(date: date ?? AppDateUtils.today);
  }
}
