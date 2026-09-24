import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/routine_completed_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('RoutineCompletedPage', () {
    final routine = Routine.defaults.first;

    testWidgets('renders celebratory badge and routine complete headline', (tester) async {
      await pumpApp(
        tester,
        RoutineCompletedPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('CONSISTENCY UNLOCKED'), findsOneWidget);
      expect(find.text('Morning Ritual Complete'), findsOneWidget);
      expect(
        find.textContaining('Nice work. You showed up for yourself today', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('+1.0%'), findsOneWidget);
    });

    testWidgets('renders completed steps summary card and compound effect quote', (tester) async {
      await pumpApp(
        tester,
        RoutineCompletedPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('4 of 4 steps completed'), findsOneWidget);
      expect(find.text('Drink Water'), findsOneWidget);
      expect(find.text('Gentle Stretch'), findsOneWidget);
      expect(find.text('All 4 habits marked completed on Today'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('COMPOUND EFFECT'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('COMPOUND EFFECT'), findsOneWidget);
      expect(
        find.textContaining('Small daily rituals compound into profound long-term change', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders action buttons and navigation links', (tester) async {
      await pumpApp(
        tester,
        RoutineCompletedPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      await tester.scrollUntilVisible(
        find.text('Done'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Back to Routines'), findsOneWidget);
      expect(find.text('View Today\'s Progress ->'), findsOneWidget);
    });
  });
}
