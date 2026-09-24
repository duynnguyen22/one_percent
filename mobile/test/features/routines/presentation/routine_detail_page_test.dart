import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/routine_detail_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('RoutineDetailPage', () {
    final routine = Routine.defaults.first; // Morning Ritual

    testWidgets('renders routine header overview and metrics', (tester) async {
      await pumpApp(
        tester,
        RoutineDetailPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('Morning Ritual'), findsOneWidget);
      expect(find.text('Morning Cadence'), findsOneWidget);
      expect(find.text(routine.description), findsOneWidget);
      expect(find.text('4 steps'), findsOneWidget);
      expect(find.text('~22 min total'), findsOneWidget);
      expect(find.text('Low energy'), findsOneWidget);
    });

    testWidgets('renders sequence roadmap steps and incremental momentum card', (tester) async {
      await pumpApp(
        tester,
        RoutineDetailPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('SEQUENCE ROADMAP'), findsOneWidget);
      expect(find.text('Self-Paced'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Drink Water'), findsOneWidget);
      expect(find.text('Awaken'), findsOneWidget);
      expect(find.text('Hydration'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Incremental Momentum'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Incremental Momentum'), findsOneWidget);
      expect(
        find.textContaining('completing just Step 01 still counts toward your streak', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders Start Routine button', (tester) async {
      await pumpApp(
        tester,
        RoutineDetailPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('Start Routine'), findsOneWidget);
    });
  });
}
