import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/create_routine_page.dart';
import 'package:mobile/features/routines/presentation/pages/edit_routine_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('CreateRoutinePage', () {
    testWidgets('renders sequence builder form inputs and add habits button', (tester) async {
      await pumpApp(
        tester,
        const CreateRoutinePage(),
        overrides: signedOutOverrides(),
      );

      expect(find.text('Habit Creation'), findsOneWidget);
      expect(find.text('SEQUENCE BUILDER'), findsOneWidget);
      expect(
        find.textContaining('Design an intentional sequence', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('ROUTINE NAME'), findsOneWidget);
      expect(find.text('ACCENT COLOR'), findsOneWidget);
      expect(find.text('INTENTION / DESCRIPTION'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('+ Add Habit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('+ Add Habit'), findsOneWidget);
    });

    testWidgets('opens Select Habits modal when tapping Add Habit', (tester) async {
      await pumpApp(
        tester,
        const CreateRoutinePage(),
        overrides: signedOutOverrides(),
      );

      await tester.scrollUntilVisible(
        find.text('+ Add Habit'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('+ Add Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Select Habits from Today'), findsOneWidget);
      expect(
        find.textContaining('Choose existing habits to weave into this routine', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Add Selected Habits', findRichText: true), findsOneWidget);
    });
  });

  group('EditRoutinePage', () {
    final routine = Routine.defaults.first;

    testWidgets('renders routine editor with sequence steps and cadence card', (tester) async {
      await pumpApp(
        tester,
        EditRoutinePage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('EDITING SEQUENCE'), findsOneWidget);
      expect(find.text('Sequence Steps'), findsOneWidget);
      expect(find.text('4 Steps'), findsOneWidget);
      expect(find.text('Drink Water'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Sequence Cadence'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sequence Cadence'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete Routine'), findsOneWidget);
    });
  });
}
