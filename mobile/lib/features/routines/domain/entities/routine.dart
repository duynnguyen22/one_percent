import 'package:flutter/material.dart';

/// A single step inside a routine sequence.
class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.category,
    this.icon = Icons.spa_rounded,
    this.description = '',
    this.mindfulIntention = '',
    this.portionGoal = '',
    this.subSteps = const [],
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final String category;
  final IconData icon;
  final String description;
  final String mindfulIntention;
  final String portionGoal;
  final List<String> subSteps;
  final bool isCompleted;

  RoutineStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? durationMinutes,
    String? category,
    IconData? icon,
    String? description,
    String? mindfulIntention,
    String? portionGoal,
    List<String>? subSteps,
    bool? isCompleted,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      mindfulIntention: mindfulIntention ?? this.mindfulIntention,
      portionGoal: portionGoal ?? this.portionGoal,
      subSteps: subSteps ?? this.subSteps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// A guided routine grouping multiple habits in a deliberate sequence.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.cadence,
    required this.description,
    required this.accentColorHex,
    required this.steps,
    this.energyLevel = 'Low energy',
    this.isFeatured = false,
    this.presetTag = '',
  });

  final String id;
  final String name;
  final String cadence; // Morning, Afternoon, Evening, Weekend
  final String description;
  final String accentColorHex;
  final List<RoutineStep> steps;
  final String energyLevel;
  final bool isFeatured;
  final String presetTag;

  int get totalMinutes => steps.fold(0, (sum, step) => sum + step.durationMinutes);
  int get stepCount => steps.length;

  Routine copyWith({
    String? id,
    String? name,
    String? cadence,
    String? description,
    String? accentColorHex,
    List<RoutineStep>? steps,
    String? energyLevel,
    bool? isFeatured,
    String? presetTag,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      cadence: cadence ?? this.cadence,
      description: description ?? this.description,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      steps: steps ?? this.steps,
      energyLevel: energyLevel ?? this.energyLevel,
      isFeatured: isFeatured ?? this.isFeatured,
      presetTag: presetTag ?? this.presetTag,
    );
  }

  /// Default mock routines matching the 7 Stitch screens
  static List<Routine> get defaults => [
        Routine(
          id: 'morning-ritual',
          name: 'Morning Ritual',
          cadence: 'Morning',
          description: 'Start your morning grounded and clear.',
          accentColorHex: '#4D6054', // Sage Green
          energyLevel: 'Low energy',
          isFeatured: true,
          steps: [
            const RoutineStep(
              id: 'step-1',
              title: 'Drink Water',
              subtitle: 'Awaken',
              durationMinutes: 2,
              category: 'Hydration',
              icon: Icons.water_drop_outlined,
              description:
                  'Drink 250ml of warm or room-temperature water with fresh lemon to gently awaken your digestion and restore cellular hydration.',
              mindfulIntention:
                  'Take small, deliberate sips. Feel the coolness soothe your throat as your senses gently arrive.',
              portionGoal: '1 tall ceramic glass (250ml)',
            ),
            const RoutineStep(
              id: 'step-2',
              title: 'Gentle Stretch',
              subtitle: 'Open Body',
              durationMinutes: 5,
              category: 'Mobility',
              icon: Icons.self_improvement_rounded,
              description:
                  'Open your chest, lengthen your spine, and gently loosen your neck and shoulders with slow, steady breaths.',
              mindfulIntention: 'Feel each vertebra align. Breathe through any tightness with gentle patience.',
              subSteps: [
                'Cat-Cow spinal rolls (Active · 1m)',
                'Standing chest opener (2 min)',
                'Slow forward bend & hip release (2 min)',
              ],
            ),
            const RoutineStep(
              id: 'step-3',
              title: 'Mindful Stillness',
              subtitle: 'Center',
              durationMinutes: 10,
              category: 'Meditation',
              icon: Icons.spa_outlined,
              description:
                  'Silent breath tracking and box breathing. Let thoughts drift past without clinging to them.',
              mindfulIntention: 'Observe the natural cadence of your breath. Anchor in the present moment.',
            ),
            const RoutineStep(
              id: 'step-4',
              title: 'Intentional Journaling',
              subtitle: 'Anchor',
              durationMinutes: 5,
              category: 'Reflection',
              icon: Icons.edit_note_rounded,
              description:
                  'Write three lines of gratitude and define your single most impactful priority for today.',
              mindfulIntention: 'Clarify what truly matters before external noise enters your consciousness.',
            ),
          ],
        ),
        Routine(
          id: 'focus-block',
          name: 'Focus Block',
          cadence: 'Afternoon',
          description: 'Carve out deep, uninterrupted immersion.',
          accentColorHex: '#4C5F69', // Sky Slate
          energyLevel: 'High focus',
          presetTag: 'Focus Mode preset',
          steps: [
            const RoutineStep(
              id: 'step-fb-1',
              title: 'Deep Work',
              subtitle: 'Immersion',
              durationMinutes: 25,
              category: 'Productivity',
              icon: Icons.psychology_outlined,
              description: 'Single-task on your primary objective with all notifications silenced.',
            ),
            const RoutineStep(
              id: 'step-fb-2',
              title: 'Walk',
              subtitle: 'Recovery',
              durationMinutes: 10,
              category: 'Movement',
              icon: Icons.directions_walk_rounded,
              description: 'Step away from all screens to allow subconscious incubation.',
            ),
          ],
        ),
        Routine(
          id: 'wind-down',
          name: 'Wind Down',
          cadence: 'Evening',
          description: 'Release the day and prepare for restful sleep.',
          accentColorHex: '#7C5454', // Dusty Rose
          energyLevel: 'Calming cadence',
          presetTag: 'Calming cadence',
          steps: [
            const RoutineStep(
              id: 'step-wd-1',
              title: 'Read',
              subtitle: 'Unplug',
              durationMinutes: 10,
              category: 'Leisure',
              icon: Icons.menu_book_rounded,
              description: 'Read physical pages to down-regulate your nervous system.',
            ),
            const RoutineStep(
              id: 'step-wd-2',
              title: 'Plan Tomorrow',
              subtitle: 'Offload',
              durationMinutes: 5,
              category: 'Organization',
              icon: Icons.calendar_today_outlined,
              description: 'Jot down the top 3 priorities for tomorrow so your mind can rest.',
            ),
            const RoutineStep(
              id: 'step-wd-3',
              title: 'Digital Detox',
              subtitle: 'Boundary',
              durationMinutes: 5,
              category: 'Wellbeing',
              icon: Icons.phonelink_erase_rounded,
              description: 'Place phone on charger across the room and engage night mode.',
            ),
          ],
        ),
        Routine(
          id: 'weekend-growth',
          name: 'Weekend Growth',
          cadence: 'Weekend',
          description: 'Recharge mind, spirit, and personal relationships.',
          accentColorHex: '#66796C',
          energyLevel: 'Soul restoration',
          presetTag: 'Soul restoration',
          steps: [
            const RoutineStep(
              id: 'step-wg-1',
              title: 'Long Run',
              subtitle: 'Endurance',
              durationMinutes: 20,
              category: 'Cardio',
              icon: Icons.directions_run_rounded,
            ),
            const RoutineStep(
              id: 'step-wg-2',
              title: 'Reflective Journal',
              subtitle: 'Perspective',
              durationMinutes: 5,
              category: 'Mindset',
              icon: Icons.auto_stories_rounded,
            ),
            const RoutineStep(
              id: 'step-wg-3',
              title: 'Deep Reading',
              subtitle: 'Wisdom',
              durationMinutes: 5,
              category: 'Learning',
              icon: Icons.import_contacts_rounded,
            ),
            const RoutineStep(
              id: 'step-wg-4',
              title: 'Weekly Review',
              subtitle: 'Systems',
              durationMinutes: 5,
              category: 'Review',
              icon: Icons.checklist_rtl_rounded,
            ),
            const RoutineStep(
              id: 'step-wg-5',
              title: 'Call Family',
              subtitle: 'Connection',
              durationMinutes: 5,
              category: 'Relationships',
              icon: Icons.call_outlined,
            ),
          ],
        ),
      ];
}
