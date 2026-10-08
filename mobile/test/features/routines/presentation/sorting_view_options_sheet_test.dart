import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/providers/routine_view_preferences_provider.dart';
import 'package:mobile/features/routines/presentation/widgets/sorting_view_options_sheet.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/routine_doubles.dart';

void main() {
  group('SortingViewOptionsSheet', () {
    void setTallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('renders all sections, cards, chips, and buttons', (
      tester,
    ) async {
      setTallViewport(tester);

      await pumpApp(
        tester,
        const Scaffold(body: SortingViewOptionsSheet()),
        overrides: RoutineDoubles(routines: Routine.defaults).overrides,
      );

      // Header
      expect(find.text('Sorting & View Options'), findsOneWidget);
      expect(
        find.text('Customize how your rituals and habits appear'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Section 1: Sort & Reorder
      expect(find.text('Sort & Reorder Routines'), findsOneWidget);
      expect(find.text('ARRANGEMENT'), findsOneWidget);
      expect(find.text('Priority First'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Scheduled Time'), findsOneWidget);
      expect(find.text('Custom Manual Order'), findsOneWidget);

      // Section 2: Display & Card View
      expect(find.text('Display & Card View'), findsOneWidget);
      expect(find.text('PREVIEW DENSITY'), findsOneWidget);
      expect(find.text('Compact View'), findsOneWidget);
      expect(find.text('Expanded View'), findsOneWidget);
      expect(find.text('Displaying steps inline'), findsOneWidget);

      // Section 3: Filter by Ritual Time
      expect(find.text('Filter by Ritual Time'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Afternoon'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Context Banner
      expect(find.text('Small steps, done consistently'), findsOneWidget);
      expect(
        find.text('Preferences automatically sync with your daily habit log'),
        findsOneWidget,
      );

      // Action Buttons
      expect(find.text('Apply Preferences'), findsOneWidget);
      expect(find.text('Reset to Default View'), findsOneWidget);
    });

    testWidgets('switching density updates live preview callout text', (
      tester,
    ) async {
      setTallViewport(tester);

      await pumpApp(
        tester,
        const Scaffold(body: SortingViewOptionsSheet()),
        overrides: RoutineDoubles(routines: Routine.defaults).overrides,
      );

      expect(find.text('Displaying steps inline'), findsOneWidget);

      // Tap Compact View card
      await tester.tap(find.text('Compact View'));
      await tester.pumpAndSettle();

      expect(find.text('Displaying compact overview'), findsOneWidget);
      expect(
        find.text('Hides step breakdowns for high-density habit overview'),
        findsOneWidget,
      );

      // Tap Expanded View card again
      await tester.tap(find.text('Expanded View'));
      await tester.pumpAndSettle();

      expect(find.text('Displaying steps inline'), findsOneWidget);
    });

    testWidgets('applying preferences updates provider', (tester) async {
      setTallViewport(tester);
      late WidgetRef capturedRef;

      await pumpApp(
        tester,
        Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const Scaffold(body: SortingViewOptionsSheet());
          },
        ),
        overrides: RoutineDoubles(routines: Routine.defaults).overrides,
      );

      // Tap Scheduled Time
      await tester.tap(find.text('Scheduled Time'));
      await tester.pumpAndSettle();

      // Tap Compact View
      await tester.tap(find.text('Compact View'));
      await tester.pumpAndSettle();

      // Tap Morning filter
      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();

      // Tap Apply Preferences
      await tester.tap(find.text('Apply Preferences'));
      await tester.pump();

      expect(find.text('Saved & Updated'), findsOneWidget);

      final state = capturedRef.read(routineViewPreferencesProvider);
      expect(state.sortOption, RoutineSortOption.scheduledTime);
      expect(state.viewDensity, RoutineViewDensity.compact);
      expect(state.timeFilter, RitualTimeFilter.morning);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping reset button resets choices to default', (
      tester,
    ) async {
      setTallViewport(tester);

      await pumpApp(
        tester,
        const Scaffold(body: SortingViewOptionsSheet()),
        overrides: RoutineDoubles(routines: Routine.defaults).overrides,
      );

      // Tap Compact View
      await tester.tap(find.text('Compact View'));
      await tester.pumpAndSettle();
      expect(find.text('Displaying compact overview'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset to Default View'));
      await tester.pumpAndSettle();

      expect(find.text('Displaying steps inline'), findsOneWidget);
    });
  });
}
