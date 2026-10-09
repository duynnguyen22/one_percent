import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../injection/dependency_injection.dart';
import '../../domain/entities/routine.dart';

/// Available sorting options for routine arrangement.
enum RoutineSortOption {
  priority('Priority First', 'High impact & core morning habits at the top'),
  scheduledTime(
    'Scheduled Time',
    'Chronological flow: Morning → Midday → Evening',
  ),
  manual('Custom Manual Order', 'Drag and reorder your rituals directly');

  const RoutineSortOption(this.label, this.description);

  final String label;
  final String description;
}

/// Available density/display view modes for routine cards.
enum RoutineViewDensity {
  compact('Compact View', 'Quick scanning & high density'),
  expanded('Expanded View', 'Step breakdowns & launch');

  const RoutineViewDensity(this.label, this.description);

  final String label;
  final String description;
}

/// Filter chips for cadence/ritual time of day.
enum RitualTimeFilter {
  all('All'),
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  custom('Custom');

  const RitualTimeFilter(this.label);

  final String label;
}

/// State representation of the user's active routine display preferences.
class RoutineViewPreferences {
  const RoutineViewPreferences({
    this.sortOption = RoutineSortOption.priority,
    this.viewDensity = RoutineViewDensity.expanded,
    this.timeFilter = RitualTimeFilter.all,
  });

  final RoutineSortOption sortOption;
  final RoutineViewDensity viewDensity;
  final RitualTimeFilter timeFilter;

  RoutineViewPreferences copyWith({
    RoutineSortOption? sortOption,
    RoutineViewDensity? viewDensity,
    RitualTimeFilter? timeFilter,
  }) {
    return RoutineViewPreferences(
      sortOption: sortOption ?? this.sortOption,
      viewDensity: viewDensity ?? this.viewDensity,
      timeFilter: timeFilter ?? this.timeFilter,
    );
  }

  /// Filters and sorts a given list of [routines] according to these preferences.
  List<Routine> applyTo(List<Routine> routines) {
    // 1. Filter
    final filtered = switch (timeFilter) {
      RitualTimeFilter.all => routines.toList(),
      RitualTimeFilter.morning =>
        routines
            .where((r) => r.cadence.toLowerCase().contains('morning'))
            .toList(),
      RitualTimeFilter.afternoon =>
        routines
            .where((r) => r.cadence.toLowerCase().contains('afternoon'))
            .toList(),
      RitualTimeFilter.evening =>
        routines
            .where((r) => r.cadence.toLowerCase().contains('evening'))
            .toList(),
      RitualTimeFilter.custom =>
        routines
            .where(
              (r) =>
                  !r.cadence.toLowerCase().contains('morning') &&
                  !r.cadence.toLowerCase().contains('afternoon') &&
                  !r.cadence.toLowerCase().contains('evening'),
            )
            .toList(),
    };

    // 2. Sort
    switch (sortOption) {
      case RoutineSortOption.priority:
        // Featured routines and high-impact morning rituals at the top
        filtered.sort((a, b) {
          if (a.isFeatured != b.isFeatured) {
            return b.isFeatured ? 1 : -1;
          }
          final aScore = _cadenceScore(a.cadence) * 10 + a.steps.length;
          final bScore = _cadenceScore(b.cadence) * 10 + b.steps.length;
          return bScore.compareTo(aScore);
        });
      case RoutineSortOption.scheduledTime:
        // Chronological order: Morning -> Afternoon -> Evening
        filtered.sort((a, b) {
          return _cadenceTimeOrder(
            a.cadence,
          ).compareTo(_cadenceTimeOrder(b.cadence));
        });
      case RoutineSortOption.manual:
        // Preserves original server or custom position
        break;
    }

    return filtered;
  }

  static int _cadenceScore(String cadence) {
    final lower = cadence.toLowerCase();
    if (lower.contains('morning')) return 3;
    if (lower.contains('afternoon')) return 2;
    if (lower.contains('evening')) return 1;
    return 0;
  }

  static int _cadenceTimeOrder(String cadence) {
    final lower = cadence.toLowerCase();
    if (lower.contains('morning')) return 0;
    if (lower.contains('afternoon')) return 1;
    if (lower.contains('evening')) return 2;
    return 3;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineViewPreferences &&
          runtimeType == other.runtimeType &&
          sortOption == other.sortOption &&
          viewDensity == other.viewDensity &&
          timeFilter == other.timeFilter;

  @override
  int get hashCode => Object.hash(sortOption, viewDensity, timeFilter);
}

/// Provider managing active routine view and sorting preferences.
///
/// Preferences are persisted to [LocalStorage] so they survive app restarts.
class RoutineViewPreferencesNotifier extends Notifier<RoutineViewPreferences> {
  static const _storageKey = 'routine_view_preferences';

  LocalStorage? get _storage {
    try {
      return ref.read(localStorageProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  RoutineViewPreferences build() {
    return _loadFromStorage();
  }

  void update({
    RoutineSortOption? sortOption,
    RoutineViewDensity? viewDensity,
    RitualTimeFilter? timeFilter,
  }) {
    state = state.copyWith(
      sortOption: sortOption,
      viewDensity: viewDensity,
      timeFilter: timeFilter,
    );
    _persist(state);
  }

  void resetToDefaults() {
    state = const RoutineViewPreferences();
    _persist(state);
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  RoutineViewPreferences _loadFromStorage() {
    final storage = _storage;
    if (storage == null) return const RoutineViewPreferences();

    final json = storage.getJson(_storageKey);
    if (json == null) return const RoutineViewPreferences();

    final sortOption = RoutineSortOption.values.firstWhere(
      (e) => e.name == json['sortOption'],
      orElse: () => RoutineSortOption.priority,
    );
    final viewDensity = RoutineViewDensity.values.firstWhere(
      (e) => e.name == json['viewDensity'],
      orElse: () => RoutineViewDensity.expanded,
    );
    final timeFilter = RitualTimeFilter.values.firstWhere(
      (e) => e.name == json['timeFilter'],
      orElse: () => RitualTimeFilter.all,
    );

    return RoutineViewPreferences(
      sortOption: sortOption,
      viewDensity: viewDensity,
      timeFilter: timeFilter,
    );
  }

  void _persist(RoutineViewPreferences prefs) {
    _storage?.setJson(_storageKey, {
      'sortOption': prefs.sortOption.name,
      'viewDensity': prefs.viewDensity.name,
      'timeFilter': prefs.timeFilter.name,
    });
  }
}

final routineViewPreferencesProvider =
    NotifierProvider<RoutineViewPreferencesNotifier, RoutineViewPreferences>(
      RoutineViewPreferencesNotifier.new,
    );
