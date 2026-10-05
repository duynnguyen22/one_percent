import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/errors/result.dart';
import 'package:mobile/features/routines/domain/entities/routine_draft.dart';
import 'package:mobile/features/routines/presentation/pages/create_routine_page.dart';
import 'package:mobile/features/routines/presentation/pages/edit_routine_page.dart';
import 'package:mobile/features/routines/presentation/pages/routine_execution_page.dart';
import 'package:mobile/features/routines/presentation/pages/routines_home_page.dart';
import 'package:mobile/features/routines/presentation/widgets/routine_loader.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/routine_doubles.dart';
import '../../../helpers/toasts.dart';

void main() {
  final routine = buildRoutineModel(id: 'routine-1', name: 'Sunrise Flow');
  final read = buildDailyHabit(
    habit: buildHabitModel(id: 'habit-read', name: 'Read'),
  );
  final stretch = buildDailyHabit(
    habit: buildHabitModel(id: 'habit-stretch', name: 'Stretch'),
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );

  group('RoutinesHomePage', () {
    testWidgets('lists the routines the API returns', (tester) async {
      final doubles = RoutineDoubles(routines: [routine]);

      await pumpApp(
        tester,
        const RoutinesHomePage(),
        overrides: doubles.overrides,
      );

      expect(find.text('Sunrise Flow'), findsOneWidget);
      expect(find.text('Drink Water'), findsOneWidget);
      expect(find.text('Morning Ritual'), findsNothing);
    });

    testWidgets('invites the user to create one when there are none', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const RoutinesHomePage(),
        overrides: RoutineDoubles().overrides,
      );

      expect(find.text('No routines yet'), findsOneWidget);
    });

    testWidgets('shows the failure with a Try again that reloads', (
      tester,
    ) async {
      final doubles = RoutineDoubles();
      when(
        () => doubles.routines.getRoutines(date: any(named: 'date')),
      ).thenAnswer((_) async => const ResultError(ServerFailure('Down')));

      await pumpApp(
        tester,
        const RoutinesHomePage(),
        overrides: doubles.overrides,
      );
      expect(find.text('Down'), findsOneWidget);

      when(
        () => doubles.routines.getRoutines(date: any(named: 'date')),
      ).thenAnswer((_) async => Success([routine]));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Flow'), findsOneWidget);
    });
  });

  group('CreateRoutinePage', () {
    testWidgets('starts empty, with Create disabled until a habit is added', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const CreateRoutinePage(),
        overrides: RoutineDoubles().overrides,
      );

      await scrollTo(tester, find.text('Create Routine'));
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create Routine'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('the habit picker lists the user\'s own habits', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const CreateRoutinePage(),
        overrides: RoutineDoubles(habits: [read, stretch]).overrides,
      );

      await scrollTo(tester, find.text('+ Add Habit'));
      await tester.tap(find.text('+ Add Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
    });

    testWidgets('creates the routine with the picked habits, in order', (
      tester,
    ) async {
      final doubles = RoutineDoubles(habits: [read, stretch]);
      when(
        () => doubles.routines.createRoutine(any()),
      ).thenAnswer((_) async => Success(routine));

      await pumpRoutedApp(
        tester,
        const CreateRoutinePage(),
        overrides: doubles.overrides,
      );

      await tester.enterText(find.byType(TextField).first, 'Evening Reset');
      await tester.tap(find.text('Evening'));
      await scrollTo(tester, find.text('+ Add Habit'));
      await tester.tap(find.text('+ Add Habit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stretch'));
      await tester.tap(find.text('Read'));
      await tester.tap(find.textContaining('Add Selected Habits'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Create Routine'));
      await tester.tap(find.text('Create Routine'));
      await tester.pumpAndSettle();

      final draft =
          verify(
                () => doubles.routines.createRoutine(captureAny()),
              ).captured.single
              as RoutineDraft;
      expect(draft.name, 'Evening Reset');
      expect(draft.cadence, 'Evening');
      expect(draft.steps.map((s) => s.habitId), [
        'habit-stretch',
        'habit-read',
      ]);
      expect(find.byType(CreateRoutinePage), findsNothing);
      await clearToasts(tester);
    });

    testWidgets('keeps the page open and shows why when saving fails', (
      tester,
    ) async {
      final doubles = RoutineDoubles(habits: [read]);
      when(() => doubles.routines.createRoutine(any())).thenAnswer(
        (_) async => const ResultError(ValidationFailure('Habit is archived')),
      );

      await pumpRoutedApp(
        tester,
        const CreateRoutinePage(),
        overrides: doubles.overrides,
      );
      await tester.enterText(find.byType(TextField).first, 'Focus');
      await scrollTo(tester, find.text('+ Add Habit'));
      await tester.tap(find.text('+ Add Habit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read'));
      await tester.tap(find.textContaining('Add Selected Habits'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Create Routine'));
      await tester.tap(find.text('Create Routine'));
      await tester.pumpAndSettle();

      expect(find.text('Habit is archived'), findsOneWidget);
      expect(find.byType(CreateRoutinePage), findsOneWidget);
      await clearToasts(tester);
    });
  });

  group('EditRoutinePage', () {
    testWidgets('saves the edited routine through the API', (tester) async {
      final doubles = RoutineDoubles(routines: [routine]);
      when(
        () => doubles.routines.updateRoutine(any(), any()),
      ).thenAnswer((_) async => Success(routine));

      await pumpRoutedApp(
        tester,
        EditRoutinePage(routine: routine),
        overrides: doubles.overrides,
      );
      await tester.enterText(find.byType(TextField).first, 'Sunrise 2.0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final captured = verify(
        () => doubles.routines.updateRoutine(captureAny(), captureAny()),
      ).captured;
      expect(captured[0], 'routine-1');
      final draft = captured[1] as RoutineDraft;
      expect(draft.name, 'Sunrise 2.0');
      expect(draft.steps.map((s) => s.durationMinutes), [5, 10]);
      await clearToasts(tester);
    });

    testWidgets('deletes only after the user confirms', (tester) async {
      final doubles = RoutineDoubles(routines: [routine]);
      when(
        () => doubles.routines.deleteRoutine(any()),
      ).thenAnswer((_) async => const Success(null));

      await pumpRoutedApp(
        tester,
        EditRoutinePage(routine: routine),
        overrides: doubles.overrides,
      );
      await scrollTo(tester, find.text('Delete Routine'));
      await tester.tap(find.text('Delete Routine'));
      await tester.pumpAndSettle();

      verifyNever(() => doubles.routines.deleteRoutine(any()));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => doubles.routines.deleteRoutine('routine-1')).called(1);
      await clearToasts(tester);
    });
  });

  group('RoutineExecutionPage', () {
    testWidgets('Done & Next checks the step\'s habit off on Today', (
      tester,
    ) async {
      final doubles = RoutineDoubles(routines: [routine]);

      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: doubles.overrides,
      );
      await scrollTo(tester, find.text('Done & Next'));
      await tester.tap(find.text('Done & Next'));
      await tester.pumpAndSettle();

      verify(
        () => doubles.entries.checkOff(
          habitId: routine.steps.first.habitId,
          date: any(named: 'date'),
        ),
      ).called(1);
    });

    testWidgets('Skip Step does not check anything off', (tester) async {
      final doubles = RoutineDoubles(routines: [routine]);

      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: doubles.overrides,
      );
      await scrollTo(tester, find.text('Skip Step'));
      await tester.tap(find.text('Skip Step'));
      await tester.pumpAndSettle();

      verifyNever(
        () => doubles.entries.checkOff(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
        ),
      );
      expect(find.textContaining('logged to Today'), findsNothing);
    });

    testWidgets('explains a routine whose habits are all archived', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine.copyWith(steps: const [])),
        overrides: RoutineDoubles().overrides,
      );

      expect(find.text('No active habits in this routine'), findsOneWidget);
    });
  });

  group('RoutineLoader', () {
    testWidgets('builds with the routine matching the id', (tester) async {
      await pumpApp(
        tester,
        RoutineLoader(
          routineId: 'routine-1',
          builder: (routine) => Text('Loaded ${routine.name}'),
        ),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      expect(find.text('Loaded Sunrise Flow'), findsOneWidget);
    });

    testWidgets('says so when the routine does not exist', (tester) async {
      await pumpApp(
        tester,
        RoutineLoader(
          routineId: 'missing',
          builder: (routine) => Text('Loaded ${routine.name}'),
        ),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      expect(find.text('Routine not found'), findsOneWidget);
    });
  });
}
