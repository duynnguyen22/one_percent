import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/routine.dart';

/// Routine Detail Preview Screen (Stitch Screen 1 - 37104ba5aca94716b3fdb55355df2b81).
/// Displays a comprehensive sequence roadmap, energy profile, and cadence guide.
class RoutineDetailPage extends ConsumerWidget {
  const RoutineDetailPage({
    super.key,
    required this.routine,
  });

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Color(
      int.parse(routine.accentColorHex.replaceAll('#', '0xFF')),
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
                'Routine Detail',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              8,
              AppSpacing.containerMargin,
              140, // Space for sticky bottom CTA
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Routine Overview Ambient Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppSpacing.borderRadiusCard,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ambientShadow,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb & Edit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Routines',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed(
                                RouteNames.editRoutine,
                                pathParameters: {'routineId': routine.id},
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Edit',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cadence Tag
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wb_twilight_rounded,
                              size: 14,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${routine.cadence} Cadence',
                            style: AppTypography.labelSmall.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Name & Description
                      Text(
                        routine.name,
                        style: AppTypography.headlineLargeMobile.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        routine.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Metrics Capsules
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricCapsule(
                            icon: Icons.format_list_bulleted_rounded,
                            label: '${routine.stepCount} steps',
                          ),
                          _MetricCapsule(
                            icon: Icons.timer_outlined,
                            label: '~${routine.totalMinutes} min total',
                          ),
                          _MetricCapsule(
                            icon: Icons.spa_outlined,
                            label: routine.energyLevel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sequence Roadmap Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SEQUENCE ROADMAP',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Self-Paced',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Roadmap Timeline
                ...List.generate(routine.steps.length, (index) {
                  final step = routine.steps[index];
                  final isLast = index == routine.steps.length - 1;
                  final stepNumber = '${index + 1}'.padLeft(2, '0');

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline Column
                        Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: index == 0 ? accentColor : AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                                boxShadow: index == 0
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                stepNumber,
                                style: AppTypography.labelSmall.copyWith(
                                  color: index == 0
                                      ? AppColors.onPrimary
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Step Content Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.cardPadding),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: AppSpacing.borderRadiusCard,
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.ambientShadow,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          step.subtitle,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: accentColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: AppSpacing.borderRadiusPill,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 12,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${step.durationMinutes} min',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step.title,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (step.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      step.description,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: AppSpacing.borderRadiusPill,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(step.icon, size: 13, color: AppColors.tertiary),
                                        const SizedBox(width: 4),
                                        Text(
                                          step.category,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.tertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Incremental Momentum Helper Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppSpacing.borderRadiusCard,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incremental Momentum',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'If you are pressed for time, completing just Step 01 still counts toward your streak. Showing up is enough.',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom CTA
          Positioned(
            left: AppSpacing.containerMargin,
            right: AppSpacing.containerMargin,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        RouteNames.routineExecution,
                        pathParameters: {'routineId': routine.id},
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: AppColors.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      elevation: 4,
                      shadowColor: accentColor.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'Start Routine',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hands-free guided flow. Auto-syncs to Today.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCapsule extends StatelessWidget {
  const _MetricCapsule({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusPill,
        boxShadow: const [
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
