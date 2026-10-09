import 'package:flutter/foundation.dart' show listEquals;

import 'routine.dart';

/// One step of a routine being created or edited.
class RoutineStepDraft {
  const RoutineStepDraft({
    required this.habitId,
    required this.durationMinutes,
    this.guides,
  });

  final String habitId;
  final int durationMinutes;

  /// Null leaves the step's guides as the server has them; a list, even an
  /// empty one, replaces them. The edit screen always passes the step's own.
  final List<RoutineGuide>? guides;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineStepDraft &&
          habitId == other.habitId &&
          durationMinutes == other.durationMinutes &&
          listEquals(guides, other.guides);

  @override
  int get hashCode =>
      Object.hash(habitId, durationMinutes, Object.hashAll(guides ?? const []));
}

/// What the create and edit screens submit. The list order of [steps] is the
/// order the routine plays them in.
class RoutineDraft {
  const RoutineDraft({
    required this.name,
    required this.description,
    required this.color,
    required this.cadence,
    required this.steps,
  });

  final String name;
  final String description;
  final String color;
  final String cadence;
  final List<RoutineStepDraft> steps;

  RoutineDraft copyWith({String? name}) => RoutineDraft(
    name: name ?? this.name,
    description: description,
    color: color,
    cadence: cadence,
    steps: steps,
  );
}
