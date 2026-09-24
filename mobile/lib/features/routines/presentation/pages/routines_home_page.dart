import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

/// Routines Home screen (Stitch Screen 2 - 4efa2478aaf241b6b0ce465e2a1cc99b).
/// Displays user's guided rituals, flow cards, and motivational wisdom.
class RoutinesHomePage extends ConsumerWidget {
  const RoutinesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Bloom',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                      onPressed: () {},
                      tooltip: 'Filter Routines',
                    ),
                  ],
                ),
              ),
            ),

            // Header Title & Intro
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Routines',
                      style: AppTypography.headlineLargeMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Small steps, done consistently.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mindful Helper Banner: Guided Rituals
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.borderRadiusCard,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ambientShadow,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.onPrimaryFixed,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guided Rituals',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Press Start to be guided through your habits step-by-step with zero friction. Each completed step automatically marks your daily habit done on Today.',
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
            ),

            // Routines List
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
                vertical: 8,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final routine = routines[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoutineCard(routine: routine),
                    );
                  },
                  childCount: routines.length,
                ),
              ),
            ),

            // Create Routine Button & Ritual Wisdom Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  100, // Space for bottom dock
                ),
                child: Column(
                  children: [
                    // Create Routine Action Card
                    Material(
                      color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                      borderRadius: AppSpacing.borderRadiusCard,
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(RouteNames.createRoutine);
                        },
                        borderRadius: AppSpacing.borderRadiusCard,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '+ Create Routine',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ritual Wisdom Placeholder Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: AppSpacing.borderRadiusCard,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ambientShadow,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.format_quote_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ritual Wisdom',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '"We do not rise to the level of our goals. We fall to the level of our systems."',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
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
            ),

            // Bottom clearance for floating bottom navigation dock
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(
      int.parse(routine.accentColorHex.replaceAll('#', '0xFF')),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.borderRadiusCard,
        boxShadow: const [
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed(
              RouteNames.routineDetail,
              pathParameters: {'routineId': routine.id},
            );
          },
          borderRadius: AppSpacing.borderRadiusCard,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cadence Pill & Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.borderRadiusPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _cadenceIcon(routine.cadence),
                                  size: 14,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  routine.cadence,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${routine.stepCount} steps · ~${routine.totalMinutes} min',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _routineHeaderIcon(routine.id),
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Name & Description
                Text(
                  routine.name,
                  style: AppTypography.headlineMedium.copyWith(
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
                const SizedBox(height: 12),

                // Habit Sequence Step Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.steps.map((step) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              step.title,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Bottom Sequence Flow & Start Button (Always Fixed Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Step sequence indicators
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                routine.stepCount.clamp(0, 4),
                                (i) => Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? accentColor.withValues(alpha: 0.25)
                                        : AppColors.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: i == 0 ? accentColor : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sequence flow',
                              maxLines: 1,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Start Action Button (Always fixed right)
                    FilledButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.routineExecution,
                          pathParameters: {'routineId': routine.id},
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      iconAlignment: IconAlignment.end,
                      label: const Text('Start'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _cadenceIcon(String cadence) {
    return switch (cadence.toLowerCase()) {
      'morning' => Icons.light_mode_outlined,
      'afternoon' => Icons.hourglass_top_rounded,
      'evening' => Icons.bedtime_outlined,
      _ => Icons.calendar_month_outlined,
    };
  }

  static IconData _routineHeaderIcon(String id) {
    return switch (id) {
      'morning-ritual' => Icons.energy_savings_leaf_outlined,
      'focus-block' => Icons.center_focus_strong_rounded,
      'wind-down' => Icons.nights_stay_outlined,
      _ => Icons.self_improvement_rounded,
    };
  }
}
