import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../injection/dependency_injection.dart';
import '../../../habits/presentation/providers/daily_habits_provider.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_draft.dart';

/// State of the active routine player session.
class RoutineExecutionState {
  const RoutineExecutionState({
    required this.routine,
    this.currentStepIndex = 0,
    this.isPaused = false,
    this.secondsRemaining = 120,
    this.isSoundEnabled = true,
    this.isCompleted = false,
  });

  final Routine routine;
  final int currentStepIndex;
  final bool isPaused;
  final int secondsRemaining;
  final bool isSoundEnabled;
  final bool isCompleted;

  RoutineStep? get currentStep =>
      currentStepIndex < routine.steps.length ? routine.steps[currentStepIndex] : null;

  int get totalSteps => routine.steps.length;
  bool get hasNextStep => currentStepIndex < totalSteps - 1;

  RoutineExecutionState copyWith({
    Routine? routine,
    int? currentStepIndex,
    bool? isPaused,
    int? secondsRemaining,
    bool? isSoundEnabled,
    bool? isCompleted,
  }) {
    return RoutineExecutionState(
      routine: routine ?? this.routine,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isPaused: isPaused ?? this.isPaused,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// The user's routines, and every mutation the routine screens perform.
///
/// Mutations return a `Failure?` rather than pushing an `AsyncError`, so a
/// failed save can show a message while the list stays on screen.
class RoutinesNotifier extends AsyncNotifier<List<Routine>> {
  @override
  Future<List<Routine>> build() => _load();

  Future<List<Routine>> _load() async {
    final result = await ref.read(getRoutinesUseCaseProvider)();
    return switch (result) {
      Success(:final data) => data,
      ResultError(:final failure) => throw failure,
    };
  }

  /// Re-reads the routines from the server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  /// Creates a routine, or replaces [routineId]'s name, look and steps.
  Future<Failure?> save(RoutineDraft draft, {String? routineId}) async {
    final result =
        await ref.read(saveRoutineUseCaseProvider)(draft, routineId: routineId);

    switch (result) {
      case ResultError(:final failure):
        return failure;
      case Success(:final data) when routineId != null:
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data([
            for (final r in current) r.id == routineId ? data : r,
          ]);
        }
      case Success():
        // Reload so the new routine lands in the server's order.
        await refresh();
    }
    return null;
  }

  /// Deletes the routine. The list updates first and rolls back on failure.
  Future<Failure?> remove(String routineId) async {
    // The list may still be loading; the delete goes ahead regardless.
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data([
        for (final r in current)
          if (r.id != routineId) r,
      ]);
    }

    final result = await ref.read(deleteRoutineUseCaseProvider)(routineId);
    if (result case ResultError(:final failure)) {
      if (current != null) state = AsyncValue.data(current);
      return failure;
    }
    return null;
  }

  /// Checks a step's habit off for today, as the player does on "Done".
  ///
  /// A habit already done today is left alone: the check-off is idempotent on
  /// the server, but there is no reason to spend the round trip.
  Future<Failure?> completeStep(String routineId, String habitId) async {
    // A routine not loaded yet still gets its check-off; only a step known
    // to be done is skipped.
    final step =
        _find(routineId)?.steps.where((s) => s.habitId == habitId).firstOrNull;
    if (step?.isCompleted ?? false) return null;

    final result = await ref.read(setEntryUseCaseProvider)(
      habitId: habitId,
      date: AppDateUtils.today,
      completed: true,
    );
    if (result case ResultError(:final failure)) return failure;

    _markHabitDone(habitId);
    // Today and Insights read the same check-offs, so they are stale now.
    ref.invalidate(dailyHabitsProvider);
    ref.read(habitsRevisionProvider.notifier).bump();
    return null;
  }

  Routine? _find(String routineId) =>
      state.value?.where((r) => r.id == routineId).firstOrNull;

  /// A habit can sit in several routines, so every routine holding it updates.
  void _markHabitDone(String habitId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data([
      for (final routine in current)
        () {
          final steps = [
            for (final s in routine.steps)
              s.habitId == habitId ? s.copyWith(isCompleted: true) : s,
          ];
          return routine.copyWith(
            steps: steps,
            completedToday: steps.isNotEmpty && steps.every((s) => s.isCompleted),
          );
        }(),
    ]);
  }
}

final routinesProvider =
    AsyncNotifierProvider<RoutinesNotifier, List<Routine>>(
  RoutinesNotifier.new,
  // The screens offer an explicit Retry; see `dailyHabitsProvider`.
  retry: (_, _) => null,
);

/// One routine by id, following the list's loading and error states. Data is
/// null when the routine does not exist (or was just deleted).
final routineByIdProvider =
    Provider.family<AsyncValue<Routine?>, String>((ref, routineId) {
  return ref.watch(routinesProvider).whenData(
        (list) => list.where((r) => r.id == routineId).firstOrNull,
      );
});

/// Execution session notifier for step navigation, timer & sound.
class RoutineExecutionNotifier extends Notifier<RoutineExecutionState?> {
  @override
  RoutineExecutionState? build() => null;

  void start(Routine routine) {
    final firstStep = routine.steps.isNotEmpty ? routine.steps.first : null;
    state = RoutineExecutionState(
      routine: routine,
      currentStepIndex: 0,
      secondsRemaining: (firstStep?.durationMinutes ?? 2) * 60,
    );
  }

  void togglePause() {
    if (state == null) return;
    state = state!.copyWith(isPaused: !state!.isPaused);
  }

  void toggleSound() {
    if (state == null) return;
    state = state!.copyWith(isSoundEnabled: !state!.isSoundEnabled);
  }

  void tick() {
    if (state == null || state!.isPaused || state!.secondsRemaining <= 0) return;
    state = state!.copyWith(secondsRemaining: state!.secondsRemaining - 1);
  }

  void advanceStep() {
    if (state == null) return;
    if (state!.hasNextStep) {
      final nextIndex = state!.currentStepIndex + 1;
      final nextStep = state!.routine.steps[nextIndex];
      state = state!.copyWith(
        currentStepIndex: nextIndex,
        secondsRemaining: nextStep.durationMinutes * 60,
        isPaused: false,
      );
    } else {
      state = state!.copyWith(isCompleted: true);
    }
  }

  void skipStep() {
    advanceStep();
  }
}

final routineExecutionProvider =
    NotifierProvider<RoutineExecutionNotifier, RoutineExecutionState?>(
  RoutineExecutionNotifier.new,
);
