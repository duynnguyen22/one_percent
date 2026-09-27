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
import '../widgets/select_habits_modal.dart';

/// Create Routine Screen (Stitch Screen 3 - 04149fd7c3f54e26a2ce66cfae468647).
/// Sequence builder for assembling and ordering daily habits into a guided ritual.
class CreateRoutinePage extends ConsumerStatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  ConsumerState<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends ConsumerState<CreateRoutinePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const List<String> _accentPalette = [
    '#4D6054', // Sage Green
    '#4C5F69', // Sky Slate
    '#7C5454', // Dusty Rose
    '#66796C', // Warm Olive
  ];

  String _selectedAccentHex = '#4D6054';

  String _cadence = CadencePicker.options.first;

  /// Picked habits, in play order. Each step's id is its habit's id.
  List<RoutineStep> _steps = [];

  bool _isSaving = false;

  int get _totalMinutes => _steps.fold(0, (sum, step) => sum + step.durationMinutes);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error('Give your routine a name.');
      return;
    }

    setState(() => _isSaving = true);
    final failure = await ref.read(routinesProvider.notifier).save(
          RoutineDraft(
            name: name,
            description: _descriptionController.text.trim(),
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
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (failure != null) {
      AppToast.error(failure.message);
      return;
    }
    AppToast.success('Routine "$name" created');
    context.pop();
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
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
            // Sequence Builder Intro Header
            Text(
              'SEQUENCE BUILDER',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Design an intentional sequence to guide your daily focus.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Form Configuration Card
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
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _nameController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter routine name...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cadence
                  Text(
                    'CADENCE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CadencePicker(
                    value: _cadence,
                    accentColor: accentColor,
                    onChanged: (cadence) => setState(() => _cadence = cadence),
                  ),
                  const SizedBox(height: 16),

                  // Accent Color
                  Text(
                    'ACCENT COLOR',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.surface : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: col.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Intention / Description
                  Text(
                    'INTENTION / DESCRIPTION',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: AppSpacing.borderRadiusCard,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Describe the intention and tone...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ordered Habits Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ordered habits (drag to reorder)',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_steps.length} habits · ~$_totalMinutes min',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reorderable Step List
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
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppSpacing.borderRadiusCard,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.drag_indicator_rounded,
                          color: AppColors.outlineVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, size: 16, color: accentColor),
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
                                '${step.durationMinutes} min · ${step.category}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
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

            // Add Habit Button
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
                        _steps =
                            SelectHabitsModal.mergeSelection(_steps, selected);
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
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '+ Add Habit',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: FilledButton.icon(
                onPressed: _steps.isEmpty || _isSaving ? null : _saveRoutine,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  'Create Routine',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
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
