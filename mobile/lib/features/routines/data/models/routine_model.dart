import '../../domain/entities/routine.dart';

/// Wire representation of [Routine].
///
/// Extends the entity so a model is usable anywhere a [Routine] is, while every
/// mention of JSON stays inside the data layer.
class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.name,
    required super.cadence,
    required super.description,
    required super.accentColorHex,
    required super.steps,
    super.completedToday,
  });

  /// Used when the routine has no colour of its own (Sage Green).
  static const String defaultColor = '#4D6054';

  /// Used when the routine has no cadence of its own.
  static const String defaultCadence = 'Anytime';

  /// Parses a routine view from any `/routines` response.
  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['steps'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    return RoutineModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      accentColorHex: normalizeHex(json['color'] as String?) ?? defaultColor,
      cadence: json['cadence'] as String? ?? defaultCadence,
      completedToday: json['completedToday'] as bool? ?? false,
      steps: [for (final row in rows) _stepFromJson(row)],
    );
  }

  static RoutineStep _stepFromJson(Map<String, dynamic> json) {
    final order = json['order'] as int;
    return RoutineStep(
      id: json['habitId'] as String,
      title: json['name'] as String,
      subtitle: 'Step $order',
      durationMinutes: json['durationMinutes'] as int,
      category: 'Daily habit',
      isCompleted: json['doneToday'] as bool? ?? false,
      guides: _guidesFromJson(json['guides']),
    );
  }

  /// Sorted by `order`; a missing or null list (older server) means none.
  static List<RoutineGuide> _guidesFromJson(Object? raw) {
    final rows =
        (raw as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    return [
      for (final row in rows)
        RoutineGuide(
          title: row['title'] as String,
          durationSeconds: row['durationSeconds'] as int,
        ),
    ];
  }

  static final RegExp _hex = RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');

  /// `@IsHexColor()` accepts `abc`, `#abc` and `#aabbcc`; the UI parses only
  /// `#RRGGBB`. Returns null for anything that is not a hex colour.
  static String? normalizeHex(String? value) {
    final match = value == null ? null : _hex.firstMatch(value.trim());
    if (match == null) return null;
    var digits = match.group(1)!;
    if (digits.length == 3) {
      digits = digits.split('').map((c) => '$c$c').join();
    }
    return '#${digits.toUpperCase()}';
  }
}
