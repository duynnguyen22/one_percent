import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/routine.dart';

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

/// State notifier managing all available routines.
class RoutinesNotifier extends Notifier<List<Routine>> {
  @override
  List<Routine> build() => Routine.defaults;

  void addRoutine(Routine routine) {
    state = [...state, routine];
  }

  void updateRoutine(Routine updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  void deleteRoutine(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  Routine? findById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

final routinesNotifierProvider =
    NotifierProvider<RoutinesNotifier, List<Routine>>(RoutinesNotifier.new);

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
