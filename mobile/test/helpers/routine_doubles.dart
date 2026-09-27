// Riverpod 3 moved `Override` out of the main barrel.
import 'package:flutter_riverpod/misc.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/habits/domain/entities/daily_habit.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/injection/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';
import 'pump_app.dart';

/// The repositories a routine screen reaches, stubbed to answer from memory.
///
/// Routine screens read routines, pick from the user's habits, and check
/// habits off, so all three repositories are faked together.
class RoutineDoubles {
  RoutineDoubles({
    List<Routine> routines = const [],
    List<DailyHabit>? habits,
  }) {
    registerFallbacks();
    when(() => this.routines.getRoutines(date: any(named: 'date')))
        .thenAnswer((_) async => Success(routines));
    when(() => this.habits.getHabitsForDate(any())).thenAnswer(
      (_) async => Success(habits ?? const []),
    );
    when(() => entries.checkOff(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => Success(buildHabitEntryModel()));
  }

  final routines = MockRoutineRepository();
  final habits = MockHabitRepository();
  final entries = MockEntryRepository();

  List<Override> get overrides => [
        ...signedOutOverrides(),
        routineRepositoryProvider.overrideWithValue(routines),
        habitRepositoryProvider.overrideWithValue(habits),
        entryRepositoryProvider.overrideWithValue(entries),
      ];
}
