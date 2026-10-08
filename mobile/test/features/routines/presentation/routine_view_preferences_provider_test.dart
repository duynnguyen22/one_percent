import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routines/domain/entities/routine.dart';
import 'package:mobile/features/routines/presentation/providers/routine_view_preferences_provider.dart';

void main() {
  group('RoutineViewPreferences', () {
    test('default preferences have priority sort, expanded view, and all filter', () {
      const prefs = RoutineViewPreferences();
      expect(prefs.sortOption, RoutineSortOption.priority);
      expect(prefs.viewDensity, RoutineViewDensity.expanded);
      expect(prefs.timeFilter, RitualTimeFilter.all);
    });

    test('filters routines by cadence', () {
      final routines = Routine.defaults;

      final morningPrefs = const RoutineViewPreferences(
        timeFilter: RitualTimeFilter.morning,
      );
      final morningRoutines = morningPrefs.applyTo(routines);
      expect(
        morningRoutines.every((r) => r.cadence.toLowerCase().contains('morning')),
        isTrue,
      );

      final eveningPrefs = const RoutineViewPreferences(
        timeFilter: RitualTimeFilter.evening,
      );
      final eveningRoutines = eveningPrefs.applyTo(routines);
      expect(
        eveningRoutines.every((r) => r.cadence.toLowerCase().contains('evening')),
        isTrue,
      );
    });

    test('sorts routines by scheduledTime', () {
      final routines = Routine.defaults;
      final scheduledPrefs = const RoutineViewPreferences(
        sortOption: RoutineSortOption.scheduledTime,
      );
      final sorted = scheduledPrefs.applyTo(routines);

      // Morning should precede Evening
      final morningIndex = sorted.indexWhere(
        (r) => r.cadence.toLowerCase().contains('morning'),
      );
      final eveningIndex = sorted.indexWhere(
        (r) => r.cadence.toLowerCase().contains('evening'),
      );

      if (morningIndex != -1 && eveningIndex != -1) {
        expect(morningIndex < eveningIndex, isTrue);
      }
    });

    test('resets preferences to default values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(routineViewPreferencesProvider.notifier);
      notifier.update(
        sortOption: RoutineSortOption.scheduledTime,
        viewDensity: RoutineViewDensity.compact,
        timeFilter: RitualTimeFilter.morning,
      );

      final updated = container.read(routineViewPreferencesProvider);
      expect(updated.sortOption, RoutineSortOption.scheduledTime);
      expect(updated.viewDensity, RoutineViewDensity.compact);
      expect(updated.timeFilter, RitualTimeFilter.morning);

      notifier.resetToDefaults();

      final reset = container.read(routineViewPreferencesProvider);
      expect(reset.sortOption, RoutineSortOption.priority);
      expect(reset.viewDensity, RoutineViewDensity.expanded);
      expect(reset.timeFilter, RitualTimeFilter.all);
    });
  });
}
