import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/route_names.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/routine_completed_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('RoutineCompletedPage', () {
    final routine = Routine.defaults.first;

    testWidgets('renders celebratory badge and routine complete headline', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineCompletedPage(routine: routine),
        overrides: signedOutOverrides(),
      );

      expect(find.text('CONSISTENCY UNLOCKED'), findsOneWidget);
      expect(find.text('Morning Ritual Complete'), findsOneWidget);
      expect(
        find.textContaining(
          'Nice work. You showed up for yourself today',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('+1.0%'), findsOneWidget);
    });

    testWidgets(
      'renders completed steps summary card and compound effect quote',
      (tester) async {
        await pumpApp(
          tester,
          RoutineCompletedPage(routine: routine),
          overrides: signedOutOverrides(),
        );

        expect(find.text('4 of 4 steps completed'), findsOneWidget);
        expect(find.text('Drink Water'), findsOneWidget);
        expect(find.text('Gentle Stretch'), findsOneWidget);
        expect(
          find.text('All 4 habits marked completed on Today'),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.text('COMPOUND EFFECT'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('COMPOUND EFFECT'), findsOneWidget);
        expect(
          find.textContaining(
            'Small daily rituals compound into profound long-term change',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

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
      expect(find.text('View Today\'s Progress ->'), findsOneWidget);
    });
    group('navigation', () {
      Future<void> pumpInRouter(WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/routines/completed',
          routes: [
            GoRoute(
              path: '/today',
              name: RouteNames.today,
              builder: (context, state) => const Text('TODAY STUB'),
            ),
            GoRoute(
              path: '/routines',
              name: RouteNames.routines,
              builder: (context, state) => const Text('ROUTINES STUB'),
              routes: [
                GoRoute(
                  path: 'completed',
                  builder: (context, state) =>
                      RoutineCompletedPage(routine: routine),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: signedOutOverrides(),
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('Done goes back to the routine list', (tester) async {
        await pumpInRouter(tester);
        await tester.scrollUntilVisible(
          find.text('Done'),
          300,
          scrollable: find.byType(Scrollable),
        );
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(find.text('ROUTINES STUB'), findsOneWidget);
        expect(find.byType(RoutineCompletedPage), findsNothing);
      });

      testWidgets("View Today's Progress goes to Today", (tester) async {
        await pumpInRouter(tester);
        await tester.scrollUntilVisible(
          find.text('View Today\'s Progress ->'),
          300,
          scrollable: find.byType(Scrollable),
        );
        await tester.tap(find.text('View Today\'s Progress ->'));
        await tester.pumpAndSettle();

        expect(find.text('TODAY STUB'), findsOneWidget);
        expect(find.byType(RoutineCompletedPage), findsNothing);
      });
    });
  });
}
