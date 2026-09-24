import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/presentation/pages/routines_home_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('RoutinesHomePage', () {
    testWidgets('renders header, title and guided rituals banner', (tester) async {
      await pumpApp(tester, const RoutinesHomePage(), overrides: signedOutOverrides());

      expect(find.text('Your Routines'), findsOneWidget);
      expect(find.text('Small steps, done consistently.'), findsOneWidget);
      expect(find.text('Guided Rituals'), findsOneWidget);
      expect(
        find.textContaining('Press Start to be guided through your habits', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders routine cards including featured Morning Ritual and Focus Block', (tester) async {
      await pumpApp(tester, const RoutinesHomePage(), overrides: signedOutOverrides());

      expect(find.text('Morning Ritual'), findsOneWidget);
      expect(find.text('Focus Block'), findsOneWidget);
      expect(find.text('Drink Water'), findsWidgets);
      expect(find.text('Gentle Stretch'), findsWidgets);

      // Scroll to reveal later cards
      await tester.scrollUntilVisible(
        find.text('Wind Down'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Wind Down'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Weekend Growth'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Weekend Growth'), findsOneWidget);
    });

    testWidgets('renders Create Routine button and Ritual Wisdom card after scrolling', (tester) async {
      await pumpApp(tester, const RoutinesHomePage(), overrides: signedOutOverrides());

      await tester.scrollUntilVisible(
        find.text('+ Create Routine'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('+ Create Routine'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Ritual Wisdom'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ritual Wisdom'), findsOneWidget);
      expect(
        find.textContaining('We do not rise to the level of our goals', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
