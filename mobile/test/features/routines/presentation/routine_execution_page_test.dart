import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/route_names.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/routine_execution_page.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/routine_doubles.dart';

void main() {
  group('RoutineExecutionPage', () {
    final routine = Routine.defaults.first; // Morning Ritual

    testWidgets(
      'renders Step 1 with timer, mindful intention and portion goal',
      (tester) async {
        await pumpApp(
          tester,
          RoutineExecutionPage(routine: routine),
          overrides: RoutineDoubles(routines: [routine]).overrides,
        );

        expect(
          find.textContaining('MORNING RITUAL', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Step 1 of 4', findRichText: true),
          findsOneWidget,
        );
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
          find.textContaining(
            'Completing this automatically checks off Drink Water on Today',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows the guided sequence and advances the active move', (
      tester,
    ) async {
      final stretch = Routine.defaults.first.copyWith(
        steps: [Routine.defaults.first.steps[1]], // 5 min, 1m + 2m + 2m
      );
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: stretch),
        overrides: RoutineDoubles(routines: [stretch]).overrides,
      );

      expect(find.text('GUIDED SEQUENCE'), findsOneWidget);
      expect(find.text('Active · 1m'), findsOneWidget);
      expect(find.text('2 min'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 61));

      expect(find.text('Active · 2m'), findsOneWidget);
      expect(find.text('1 min'), findsOneWidget);
    });

    testWidgets('hides the guided sequence for a step without guides', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      expect(find.text('GUIDED SEQUENCE'), findsNothing);
    });

    testWidgets('counts down from the step duration every second', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      expect(find.text('02:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('01:59'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('01:56'), findsOneWidget);
    });

    testWidgets('Pause stops the countdown and Resume continues it', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('01:59'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Pause'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pause'));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('01:59'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('01:57'), findsOneWidget);
    });

    testWidgets('stops at 00:00 instead of going negative', (tester) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      await tester.pump(const Duration(seconds: 125));
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('resets the countdown to the next step duration', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );
      await tester.pump(const Duration(seconds: 10));

      await tester.scrollUntilVisible(
        find.text('Skip Step'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Skip Step'));
      await tester.pump();

      expect(find.text('05:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('04:59'), findsOneWidget);
    });

    testWidgets(
      'finishing the last step opens the completed route through the router',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/routines/${routine.id}/execute',
          routes: [
            GoRoute(
              path: '/routines',
              builder: (context, state) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: ':routineId/execute',
                  builder: (context, state) =>
                      RoutineExecutionPage(routine: routine),
                ),
                GoRoute(
                  path: ':routineId/completed',
                  name: RouteNames.routineCompleted,
                  builder: (context, state) =>
                      Text('COMPLETED ${state.pathParameters['routineId']}'),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: RoutineDoubles(routines: [routine]).overrides,
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();

        for (var i = 0; i < routine.steps.length; i++) {
          await tester.scrollUntilVisible(
            find.text('Skip Step'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('Skip Step'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(find.text('COMPLETED ${routine.id}'), findsOneWidget);
        expect(find.byType(RoutineExecutionPage), findsNothing);
      },
    );

    testWidgets('transitions to Step 2 when tapping Done & Next', (
      tester,
    ) async {
      await pumpApp(
        tester,
        RoutineExecutionPage(routine: routine),
        overrides: RoutineDoubles(routines: [routine]).overrides,
      );

      await tester.scrollUntilVisible(
        find.text('Done & Next'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Done & Next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Step 1 logged to Today', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Step 2 of 4', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('GENTLE STRETCH'), findsOneWidget);
      expect(find.text('Soft bell every 60s'), findsOneWidget);
      expect(find.text('YOUR SEQUENCE'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('Up next: Mindful Stillness', findRichText: true),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Up next: Mindful Stillness', findRichText: true),
        findsOneWidget,
      );
    });
    group('YOUR SEQUENCE card', () {
      Finder row(String habitId) =>
          find.byKey(ValueKey('sequence-step-$habitId'));
      Finder inRow(String habitId, String text) =>
          find.descendant(of: row(habitId), matching: find.text(text));

      Future<void> scrollToSequence(WidgetTester tester) =>
          tester.scrollUntilVisible(
            find.text('YOUR SEQUENCE'),
            200,
            scrollable: find.byType(Scrollable).first,
          );

      Future<void> tapVisible(WidgetTester tester, String label) async {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      testWidgets(
        'lists every routine step with its duration and marks the current one active',
        (tester) async {
          await pumpApp(
            tester,
            RoutineExecutionPage(routine: routine),
            overrides: RoutineDoubles(routines: [routine]).overrides,
          );
          await scrollToSequence(tester);

          for (final step in routine.steps) {
            expect(inRow(step.habitId, step.title), findsOneWidget);
          }
          expect(inRow('step-1', 'Active · 2m'), findsOneWidget);
          expect(inRow('step-2', '5 min'), findsOneWidget);
          expect(inRow('step-3', '10 min'), findsOneWidget);
          expect(inRow('step-4', '5 min'), findsOneWidget);
          expect(
            find.textContaining('Cat-Cow', findRichText: true),
            findsNothing,
          );
        },
      );

      testWidgets(
        'marks a step done after Done & Next but leaves a skipped step pending',
        (tester) async {
          await pumpApp(
            tester,
            RoutineExecutionPage(routine: routine),
            overrides: RoutineDoubles(routines: [routine]).overrides,
          );

          await tapVisible(tester, 'Done & Next');
          await tapVisible(tester, 'Skip Step');
          await scrollToSequence(tester);

          expect(inRow('step-1', 'Done'), findsOneWidget);
          expect(inRow('step-2', '5 min'), findsOneWidget);
          expect(inRow('step-3', 'Active · 10m'), findsOneWidget);
        },
      );

      testWidgets(
        'marks a step whose habit is already checked off today as done',
        (tester) async {
          final checked = routine.copyWith(
            steps: [
              ...routine.steps.take(3),
              routine.steps[3].copyWith(isCompleted: true),
            ],
          );
          await pumpApp(
            tester,
            RoutineExecutionPage(routine: checked),
            overrides: RoutineDoubles(routines: [checked]).overrides,
          );
          await scrollToSequence(tester);

          expect(inRow('step-4', 'Done'), findsOneWidget);
        },
      );
    });
  });
}
