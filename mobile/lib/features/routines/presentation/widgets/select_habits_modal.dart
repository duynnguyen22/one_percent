import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/routine.dart';

/// Available selectable habit for routine builder.
class SelectableHabitItem {
  const SelectableHabitItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.category,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final String category;
  final IconData icon;

  static const List<SelectableHabitItem> defaults = [
    SelectableHabitItem(
      id: 'sh-1',
      title: 'Drink Water',
      subtitle: 'Awaken',
      durationMinutes: 2,
      category: 'Hydration',
      icon: Icons.water_drop_outlined,
    ),
    SelectableHabitItem(
      id: 'sh-2',
      title: 'Stretch',
      subtitle: 'Open Body',
      durationMinutes: 5,
      category: 'Movement',
      icon: Icons.self_improvement_rounded,
    ),
    SelectableHabitItem(
      id: 'sh-3',
      title: 'Meditate',
      subtitle: 'Center',
      durationMinutes: 10,
      category: 'Mindfulness',
      icon: Icons.spa_outlined,
    ),
    SelectableHabitItem(
      id: 'sh-4',
      title: 'Journal',
      subtitle: 'Anchor',
      durationMinutes: 5,
      category: 'Reflection',
      icon: Icons.edit_note_rounded,
    ),
    SelectableHabitItem(
      id: 'sh-5',
      title: 'Deep Work',
      subtitle: 'Immersion',
      durationMinutes: 25,
      category: 'Productivity',
      icon: Icons.psychology_outlined,
    ),
    SelectableHabitItem(
      id: 'sh-6',
      title: 'Read',
      subtitle: 'Unplug',
      durationMinutes: 10,
      category: 'Leisure',
      icon: Icons.menu_book_rounded,
    ),
  ];
}

/// Bottom Sheet modal to select habits from Today (Stitch Screen 3 modal).
class SelectHabitsModal extends StatefulWidget {
  const SelectHabitsModal({
    super.key,
    this.initialSelectedIds = const {},
    required this.onHabitsSelected,
  });

  final Set<String> initialSelectedIds;
  final ValueChanged<List<RoutineStep>> onHabitsSelected;

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
  State<SelectHabitsModal> createState() => _SelectHabitsModalState();
}

class _SelectHabitsModalState extends State<SelectHabitsModal> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
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
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                ),
                itemCount: SelectableHabitItem.defaults.length,
                itemBuilder: (context, index) {
                  final item = SelectableHabitItem.defaults[index];
                  final isSelected = _selectedIds.contains(item.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.borderRadiusCard,
                      child: InkWell(
                        onTap: () => _toggleSelection(item.id),
                        borderRadius: AppSpacing.borderRadiusCard,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Checkbox Icon Circle
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
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
                                      item.title,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.durationMinutes} min · ${item.category}',
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
                },
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: () {
                    final selectedSteps = SelectableHabitItem.defaults
                        .where((item) => _selectedIds.contains(item.id))
                        .map(
                          (item) => RoutineStep(
                            id: 'step-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
                            title: item.title,
                            subtitle: item.subtitle,
                            durationMinutes: item.durationMinutes,
                            category: item.category,
                            icon: item.icon,
                          ),
                        )
                        .toList();

                    widget.onHabitsSelected(selectedSteps);
                    Navigator.of(context).pop();
                  },
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
                    'Add Selected Habits (${_selectedIds.length})',
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
}
