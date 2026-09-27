import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../habits/domain/entities/daily_habit.dart';
import '../../../habits/presentation/providers/daily_habits_provider.dart';
import '../../domain/entities/routine.dart';

/// Bottom Sheet modal to select habits from Today (Stitch Screen 3 modal).
///
/// Lists the user's active habits. [onHabitsSelected] receives the whole
/// selection — habits already in the routine included — in the order they
/// were picked, so the caller can both add and remove steps.
class SelectHabitsModal extends ConsumerStatefulWidget {
  const SelectHabitsModal({
    super.key,
    this.initialSelectedIds = const {},
    required this.onHabitsSelected,
  });

  final Set<String> initialSelectedIds;
  final ValueChanged<List<RoutineStep>> onHabitsSelected;

  /// How long a newly added step lasts until the user changes it.
  static const int defaultStepMinutes = 5;

  /// Applies a picker [selection] to a routine's [current] steps: deselected
  /// steps drop out, kept steps keep their place and duration, and newly
  /// picked habits join the end.
  static List<RoutineStep> mergeSelection(
    List<RoutineStep> current,
    List<RoutineStep> selection,
  ) {
    final selectedIds = selection.map((s) => s.id).toSet();
    final currentIds = current.map((s) => s.id).toSet();
    return [
      for (final step in current)
        if (selectedIds.contains(step.id)) step,
      for (final step in selection)
        if (!currentIds.contains(step.id)) step,
    ];
  }

  static Future<void> show({
    required BuildContext context,
    Set<String> initialSelectedIds = const {},
    required ValueChanged<List<RoutineStep>> onHabitsSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectHabitsModal(
        initialSelectedIds: initialSelectedIds,
        onHabitsSelected: onHabitsSelected,
      ),
    );
  }

  @override
  ConsumerState<SelectHabitsModal> createState() => _SelectHabitsModalState();
}

class _SelectHabitsModalState extends ConsumerState<SelectHabitsModal> {
  // A LinkedHashSet, so iteration follows the order habits were picked in.
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.of(widget.initialSelectedIds);
  }

  void _confirm(List<DailyHabit> habits) {
    final byId = {for (final habit in habits) habit.id: habit};
    final selected = [
      for (final id in _selectedIds)
        if (byId[id] case final habit?)
          RoutineStep(
            id: habit.id,
            title: habit.name,
            subtitle: 'Daily habit',
            durationMinutes: SelectHabitsModal.defaultStepMinutes,
            category: 'Daily habit',
            isCompleted: habit.doneToday,
          ),
    ];
    widget.onHabitsSelected(selected);
    Navigator.of(context).pop();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(dailyHabitsProvider);
    final habits = habitsAsync.value ?? const <DailyHabit>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Habits from Today',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 28,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              child: Text(
                'Choose existing habits to weave into this routine:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // List of Habits
            Flexible(child: _habitList(habitsAsync)),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: habitsAsync.hasValue ? () => _confirm(habits) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    'Add Selected Habits (${_selectedCount(habits)})',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ignores selected ids that are no longer active habits.
  int _selectedCount(List<DailyHabit> habits) =>
      habits.where((h) => _selectedIds.contains(h.id)).length;

  Widget _habitList(AsyncValue<List<DailyHabit>> habitsAsync) {
    if (habitsAsync.hasValue) {
      final habits = habitsAsync.requireValue;
      if (habits.isEmpty) {
        return const AppError(
          title: 'No habits yet',
          message: 'Create a habit on Today, then weave it into a routine.',
          icon: Icons.eco_outlined,
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerMargin,
        ),
        itemCount: habits.length,
        itemBuilder: (context, index) => _HabitTile(
          habit: habits[index],
          isSelected: _selectedIds.contains(habits[index].id),
          onTap: () => _toggleSelection(habits[index].id),
        ),
      );
    }
    if (habitsAsync.error case final error?) {
      return AppError(
        message: error is Failure ? error.message : '$error',
        onRetry: () => ref.read(dailyHabitsProvider.notifier).refresh(),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: AppLoading(),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.isSelected,
    required this.onTap,
  });

  final DailyHabit habit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = habit.doneToday
        ? 'Done today'
        : habit.currentStreak > 0
            ? '${habit.currentStreak}-day streak'
            : 'Not yet today';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusCard,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Checkbox Icon Circle
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Habit Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    'Active',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
