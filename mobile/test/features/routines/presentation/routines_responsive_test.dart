import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/pages/create_routine_page.dart';
import 'package:mobile/features/routines/presentation/pages/edit_routine_page.dart';
import 'package:mobile/features/routines/presentation/pages/routine_completed_page.dart';
import 'package:mobile/features/routines/presentation/pages/routine_detail_page.dart';
import 'package:mobile/features/routines/presentation/pages/routine_execution_page.dart';
import 'package:mobile/features/routines/presentation/pages/routines_home_page.dart';
import 'package:mobile/features/routines/presentation/widgets/select_habits_modal.dart';

import '../../../helpers/pump_app.dart';

void main() {
  const smallScreenSize = Size(320, 568); // Compact 4-inch phone

  group('Responsive small screen layout checks (zero overflow)', () {
    final routine = Routine.defaults.first;

    testWidgets('RoutinesHomePage renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, const RoutinesHomePage(), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('Your Routines'), findsOneWidget);
    });

    testWidgets('RoutineDetailPage renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, RoutineDetailPage(routine: routine), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('Morning Ritual'), findsOneWidget);
    });

    testWidgets('CreateRoutinePage renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, const CreateRoutinePage(), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('Habit Creation'), findsOneWidget);
    });

    testWidgets('EditRoutinePage renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, EditRoutinePage(routine: routine), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('EDITING SEQUENCE'), findsOneWidget);
    });

    testWidgets('RoutineExecutionPage (Step 1 & Step 2) renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, RoutineExecutionPage(routine: routine), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('DRINK WATER'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Done & Next'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Done & Next'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('GENTLE STRETCH'), findsOneWidget);
    });

    testWidgets('RoutineCompletedPage renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(tester, RoutineCompletedPage(routine: routine), overrides: signedOutOverrides());

      expect(tester.takeException(), isNull);
      expect(find.text('Morning Ritual Complete'), findsOneWidget);
    });

    testWidgets('SelectHabitsModal renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpApp(
        tester,
        SelectHabitsModal(
          initialSelectedIds: const {'sh-1'},
          onHabitsSelected: (_) {},
        ),
        overrides: signedOutOverrides(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select Habits from Today'), findsOneWidget);
    });
  });
}
