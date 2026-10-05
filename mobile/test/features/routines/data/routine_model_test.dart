import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/data/models/routine_model.dart';

void main() {
  Map<String, dynamic> routineJson() => {
    'id': 'rrrrrrrr-0000-4000-8000-000000000001',
    'name': 'Morning Ritual',
    'description': 'Start grounded.',
    'color': '#4d6054',
    'cadence': 'Morning',
    'stepCount': 2,
    'totalDurationMinutes': 15,
    'completedToday': false,
    'steps': [
      {
        'habitId': 'bbbbbbbb-0000-4000-8000-000000000002',
        'name': 'Stretch',
        'color': '#7C5454',
        'order': 2,
        'durationMinutes': 10,
        'doneToday': false,
      },
      {
        'habitId': 'bbbbbbbb-0000-4000-8000-000000000001',
        'name': 'Drink Water',
        'color': null,
        'order': 1,
        'durationMinutes': 5,
        'doneToday': true,
      },
    ],
    'createdAt': '2026-09-25T08:00:00.000Z',
    'updatedAt': '2026-09-25T08:00:00.000Z',
  };

  group('RoutineModel.fromJson', () {
    test('parses the routine view the API returns', () {
      final routine = RoutineModel.fromJson(routineJson());

      expect(routine.id, 'rrrrrrrr-0000-4000-8000-000000000001');
      expect(routine.name, 'Morning Ritual');
      expect(routine.description, 'Start grounded.');
      expect(routine.cadence, 'Morning');
      expect(routine.accentColorHex, '#4D6054');
      expect(routine.totalMinutes, 15);
      expect(routine.completedToday, isFalse);
    });

    test('orders steps by their server order and keys them by habit id', () {
      final routine = RoutineModel.fromJson(routineJson());

      expect(routine.steps.map((s) => s.title), ['Drink Water', 'Stretch']);
      expect(
        routine.steps.first.habitId,
        'bbbbbbbb-0000-4000-8000-000000000001',
      );
      expect(routine.steps.first.durationMinutes, 5);
      expect(routine.steps.first.isCompleted, isTrue);
      expect(routine.steps.last.isCompleted, isFalse);
    });

    test('falls back to defaults for null optional fields', () {
      final routine = RoutineModel.fromJson(
        {...routineJson(), 'description': null, 'color': null, 'cadence': null}
          ..remove('completedToday'),
      );

      expect(routine.description, '');
      expect(routine.accentColorHex, RoutineModel.defaultColor);
      expect(routine.cadence, RoutineModel.defaultCadence);
      expect(routine.completedToday, isFalse);
    });

    test('normalises short and hash-less hex colours', () {
      expect(
        RoutineModel.fromJson({
          ...routineJson(),
          'color': 'abc',
        }).accentColorHex,
        '#AABBCC',
      );
      expect(
        RoutineModel.fromJson({
          ...routineJson(),
          'color': 'nonsense',
        }).accentColorHex,
        RoutineModel.defaultColor,
      );
    });
  });
}
