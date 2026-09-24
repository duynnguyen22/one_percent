import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/routine.dart';

/// Calm Routine Completed Screen (Stitch Screen 7 - 3ef548383cfc42fdaa0dc035266f6d70).
/// Celebrates completion, updates streaks, and provides mindful closure.
class RoutineCompletedPage extends ConsumerWidget {
  const RoutineCompletedPage({
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: 12,
          ),
          child: Column(
            children: [
              // Top Action Bar: Bloom icon and Close (X)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_rounded, color: accentColor, size: 20),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.onSurface,
                      onPressed: () => context.goNamed(RouteNames.today),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Concentric Celebration Medallion
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 3,
                          ),
                        ),
                      ),
                      // Inner circle
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.all_inclusive_rounded,
                          size: 48,
                          color: accentColor,
                        ),
                      ),
                      // +1.0% Pill
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: AppSpacing.borderRadiusPill,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '+1.0%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Subtitle
              Text(
                'CONSISTENCY UNLOCKED',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${routine.name} Complete',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLargeMobile.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Nice work. You showed up for yourself today and built 1% momentum.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Completed Steps Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.borderRadiusCard,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ambientShadow,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${routine.stepCount} of ${routine.stepCount} steps completed',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: AppSpacing.borderRadiusPill,
                          ),
                          child: Text(
                            '${routine.totalMinutes} mins',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Step check-off rows
                    ...routine.steps.map((step) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: AppSpacing.borderRadiusCard,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${step.durationMinutes} mins',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Auto-marked banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.4),
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'All ${routine.stepCount} habits marked completed on Today',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Compound Effect Quote Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.borderRadiusCard,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMPOUND EFFECT',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.outline,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"Small daily rituals compound into profound long-term change."',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurface,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily Streak Maintained Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.85),
                      accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppSpacing.borderRadiusCard,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Daily streak maintained - Day 14',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Done Primary Button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: () => context.goNamed(RouteNames.today),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.onPrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Back to Routines Secondary Button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(RouteNames.routines);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                  child: Text(
                    'Back to Routines',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // View Today's Progress Link
              TextButton(
                onPressed: () => context.goNamed(RouteNames.today),
                child: Text(
                  'View Today\'s Progress ->',
                  style: AppTypography.labelMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
