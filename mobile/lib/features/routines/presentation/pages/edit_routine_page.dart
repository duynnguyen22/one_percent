import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_draft.dart';
import '../providers/routines_provider.dart';
import '../widgets/cadence_picker.dart';
import '../widgets/routine_field_decoration.dart';
import '../widgets/select_habits_modal.dart';

/// Edit Routine Screen (Stitch Screen 4 - fa04d39476994b879ba44b87df557d1d).
/// Allows reordering, adjusting duration, editing intention, and deleting routines.
class EditRoutinePage extends ConsumerStatefulWidget {
  const EditRoutinePage({super.key, required this.routine});

  final Routine routine;

  @override
  ConsumerState<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends ConsumerState<EditRoutinePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _intentionController;
  late String _selectedAccentHex;
  late String _cadence;
  late List<RoutineStep> _steps;
  bool _isBusy = false;

  static const List<String> _accentPalette = [
    '#4D6054', // Sage Green
    '#7C5454', // Dusty Rose
    '#4C5F69', // Sky Slate
    '#E4E2DD', // Sand
    '#66796C', // Warm Olive
  ];

  static const List<int> _durationOptions = [1, 2, 5, 10, 15, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
    _intentionController = TextEditingController(
      text: widget.routine.description,
    );
    _selectedAccentHex = widget.routine.accentColorHex;
    _cadence = widget.routine.cadence;
    _steps = List.from(widget.routine.steps);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  int get _totalMinutes =>
      _steps.fold(0, (sum, step) => sum + step.durationMinutes);

  Future<void> _saveChanges() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final failure = await ref
        .read(routinesProvider.notifier)
        .save(
          RoutineDraft(
            name: _nameController.text.trim(),
            description: _intentionController.text.trim(),
            color: _selectedAccentHex,
            cadence: _cadence,
            steps: [
              for (final step in _steps)
                RoutineStepDraft(
                  habitId: step.habitId,
                  durationMinutes: step.durationMinutes,
                ),
            ],
          ),
          routineId: widget.routine.id,
        );
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (failure != null) {
      AppToast.error(failure.message);
      return;
    }
    AppToast.success('Routine saved');
    context.pop();
  }

  Future<void> _deleteRoutine() async {
    if (_isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this routine?'),
        content: const Text('Your habits and their history stay on Today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final failure = await ref
        .read(routinesProvider.notifier)
        .remove(widget.routine.id);
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (failure != null) {
      AppToast.error(failure.message);
      return;
    }
    AppToast.success('Routine deleted');
    // Past the detail page too: the routine it shows no longer exists.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(
      int.parse(_selectedAccentHex.replaceAll('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.eco_rounded, color: accentColor, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Habit Creation',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          8,
          AppSpacing.containerMargin,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row: EDITING SEQUENCE & Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'EDITING SEQUENCE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _saveChanges,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryFixed.withValues(
                      alpha: 0.4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Edit Configuration Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.borderRadiusCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Routine Name
                  Text(
                    'ROUTINE NAME',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                            decoration: routineFieldDecoration(),
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Intention & Tone
                  Text(
                    'INTENTION & TONE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: _intentionController,
                      maxLines: 2,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                      decoration: routineFieldDecoration(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cadence
                  Text(
                    'CADENCE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CadencePicker(
                    value: _cadence,
                    accentColor: accentColor,
                    onChanged: (cadence) => setState(() => _cadence = cadence),
                  ),
                  const SizedBox(height: 16),

                  // Theme Accent
                  Text(
                    'THEME ACCENT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _accentPalette.map((hex) {
                      final isSelected = hex == _selectedAccentHex;
                      final col = Color(int.parse(hex.replaceAll('#', '0xFF')));

                      return GestureDetector(
                        onTap: () => setState(() => _selectedAccentHex = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.surface
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: col.computeLuminance() > 0.5
                                      ? AppColors.onSurface
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sequence Steps Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Sequence Steps',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_steps.length} Steps',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reorderable Steps
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final step = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, step);
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];

                return Padding(
                  key: ValueKey(step.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: AppSpacing.borderRadiusCard,
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ambientShadow,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.drag_indicator_rounded,
                          color: AppColors.outlineVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, size: 18, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                step.subtitle,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Duration Dropdown Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppSpacing.borderRadiusPill,
                          ),
                          child: DropdownButton<int>(
                            value:
                                _durationOptions.contains(step.durationMinutes)
                                ? step.durationMinutes
                                : 5,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                            ),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            items: _durationOptions.map((m) {
                              return DropdownMenuItem<int>(
                                value: m,
                                child: Text('$m min'),
                              );
                            }).toList(),
                            onChanged: (newDuration) {
                              if (newDuration != null) {
                                setState(() {
                                  _steps[index] = step.copyWith(
                                    durationMinutes: newDuration,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Delete Step
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                          onPressed: () {
                            setState(() => _steps.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),

            // Add Another Habit Action Card
            Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.borderRadiusCard,
              child: InkWell(
                onTap: () {
                  SelectHabitsModal.show(
                    context: context,
                    initialSelectedIds: _steps.map((s) => s.id).toSet(),
                    onHabitsSelected: (selected) {
                      setState(() {
                        _steps = SelectHabitsModal.mergeSelection(
                          _steps,
                          selected,
                        );
                      });
                    },
                  );
                },
                borderRadius: AppSpacing.borderRadiusCard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: AppColors.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Another Habit',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sequence Cadence Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.borderRadiusCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timelapse_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Sequence Cadence',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 2.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_steps.length} habits · ~$_totalMinutes min',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gentle flow calculated from each habit duration',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Segmented Duration Bar
                  Row(
                    children: _steps.map((s) {
                      final flex = (s.durationMinutes).clamp(1, 60);
                      return Expanded(
                        flex: flex,
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Changes CTA
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton.icon(
                onPressed: _steps.isEmpty || _isBusy ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  'Save Changes',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Routine Button
            Center(
              child: TextButton.icon(
                onPressed: _deleteRoutine,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                label: Text(
                  'Delete Routine',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Delete routine note
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Deleting this routine does NOT delete or reset your underlying habits on Today.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
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
