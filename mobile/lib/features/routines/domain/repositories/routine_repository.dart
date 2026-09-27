import '../../../../core/errors/result.dart';
import '../entities/routine.dart';
import '../entities/routine_draft.dart';

/// Routine CRUD, as the domain layer needs it.
///
/// Backed by `backend/src/routine/routine.controller.ts`.
abstract interface class RoutineRepository {
  /// `GET /routines` — newest first. With [date], each step carries whether
  /// its habit is done that day.
  Future<Result<List<Routine>>> getRoutines({DateTime? date});

  /// `POST /routines`.
  Future<Result<Routine>> createRoutine(RoutineDraft draft);

  /// `PATCH /routines/:id`. The step sequence is replaced wholesale.
  Future<Result<Routine>> updateRoutine(String routineId, RoutineDraft draft);

  /// `DELETE /routines/:id`. The habits and their history are untouched.
  Future<Result<void>> deleteRoutine(String routineId);
}
