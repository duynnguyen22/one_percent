import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/routine_execution_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('RoutineExecutionPage', () {
    final routine = Routine.defaults.first; // Morning Ritual

    testWidgets('renders Step 1 with timer, mindful intention and portion goal', (tester) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.textContaining('MORNING RITUAL', findRichText: true), findsOneWidget);
      expect(find.textContaining('Step 1 of 4', findRichText: true), findsOneWidget);
      expect(find.text('DRINK WATER'), findsOneWidget);
      expect(find.text('Mindful Intention'), findsOneWidget);
      expect(find.text('Portion Goal'), findsOneWidget);
      expect(find.text('+1% today'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Done & Next'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Done & Next'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Skip Step'), findsOneWidget);
      expect(
        find.textContaining('Completing this automatically checks off Drink Water on Today', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('transitions to Step 2 when tapping Done & Next', (tester) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Done & Next'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Done & Next'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Step 1 logged to Today', findRichText: true), findsOneWidget);
      expect(find.textContaining('Step 2 of 4', findRichText: true), findsOneWidget);
      expect(find.text('GENTLE STRETCH'), findsOneWidget);
      expect(find.text('Soft bell every 60s'), findsOneWidget);
      expect(find.text('GUIDED SEQUENCE'), findsOneWidget);
      expect(find.textContaining('Cat-Cow spinal rolls', findRichText: true), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Up next: Mindful Stillness', findRichText: true),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Up next: Mindful Stillness', findRichText: true), findsOneWidget);
    });
  });
}
