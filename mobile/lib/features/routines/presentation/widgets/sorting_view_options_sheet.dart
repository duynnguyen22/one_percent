import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/routine_view_preferences_provider.dart';
import '../providers/routines_provider.dart';

/// Modal bottom sheet for configuring routine sort order, view density,
/// and ritual time filters (Stitch Screen 1aac48406f664255a9ba0a3f61c58b36).
class SortingViewOptionsSheet extends ConsumerStatefulWidget {
  const SortingViewOptionsSheet({super.key});

  /// Displays the modal sheet on top of the current screen.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => const SortingViewOptionsSheet(),
    );
  }

  @override
  ConsumerState<SortingViewOptionsSheet> createState() =>
      _SortingViewOptionsSheetState();
}

class _SortingViewOptionsSheetState
    extends ConsumerState<SortingViewOptionsSheet> {
  late RoutineSortOption _selectedSort;
  late RoutineViewDensity _selectedDensity;
  late RitualTimeFilter _selectedFilter;
  bool _isSavedFeedback = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    final current = ref.read(routineViewPreferencesProvider);
    _selectedSort = current.sortOption;
    _selectedDensity = current.viewDensity;
    _selectedFilter = current.timeFilter;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _applyPreferences() {
    ref
        .read(routineViewPreferencesProvider.notifier)
        .update(
          sortOption: _selectedSort,
          viewDensity: _selectedDensity,
          timeFilter: _selectedFilter,
        );

    setState(() {
      _isSavedFeedback = true;
    });

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _resetDefaults() {
    setState(() {
      _selectedSort = RoutineSortOption.priority;
      _selectedDensity = RoutineViewDensity.expanded;
      _selectedFilter = RitualTimeFilter.all;
    });
    ref.read(routineViewPreferencesProvider.notifier).resetToDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesProvider).value ?? const [];
    final activeCount = routines.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber Handle — pinned at the top for intuitive pull-down dismissal
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),

            // Header Section — pinned below grabber handle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
              ),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Sort & Reorder
                    _buildSection1Sort(),
                    const SizedBox(height: 28),

                    // SECTION 2: Display & Card View
                    _buildSection2Density(),
                    const SizedBox(height: 28),

                    // SECTION 3: Filter by Ritual Time
                    _buildSection3Filter(activeCount),
                    const SizedBox(height: 24),

                    // Routine Context Preview Banner
                    _buildContextBanner(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.onSurface,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sorting & View Options',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customize how your rituals and habits appear',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.surfaceContainerLow,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection1Sort() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sort & Reorder Routines',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ARRANGEMENT',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Reorder routine cards by impact, scheduled time, or custom manual positioning.',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _buildSortCard(
          option: RoutineSortOption.priority,
          icon: Icons.bolt_rounded,
          badge: 'Recommended',
        ),
        const SizedBox(height: 10),
        _buildSortCard(
          option: RoutineSortOption.scheduledTime,
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 10),
        _buildSortCard(
          option: RoutineSortOption.manual,
          icon: Icons.drag_indicator_rounded,
          extraIcon: Icons.touch_app_outlined,
        ),
      ],
    );
  }

  Widget _buildSortCard({
    required RoutineSortOption option,
    required IconData icon,
    String? badge,
    IconData? extraIcon,
  }) {
    final isSelected = _selectedSort == option;

    return Material(
      color: isSelected
          ? AppColors.surfaceContainerLow
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSort = option;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.onPrimaryFixed
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.label,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (extraIcon != null) ...[
                          const SizedBox(width: 6),
                          Icon(extraIcon, size: 15, color: AppColors.outline),
                        ],
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Check Indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection2Density() {
    final isExpanded = _selectedDensity == RoutineViewDensity.expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Display & Card View',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PREVIEW DENSITY',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Toggle between compact overview and rich card view with step previews.',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Density Grid (Side-by-side)
        Row(
          children: [
            Expanded(
              child: _buildDensityCard(
                density: RoutineViewDensity.compact,
                icon: Icons.view_agenda_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDensityCard(
                density: RoutineViewDensity.expanded,
                icon: Icons.space_dashboard_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Live Preview Callout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpanded
                          ? 'Displaying steps inline'
                          : 'Displaying compact overview',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isExpanded
                          ? "Shows '01 Drink water', '02 Gentle stretch', '03 Meditate'"
                          : 'Hides step breakdowns for high-density habit overview',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDensityCard({
    required RoutineViewDensity density,
    required IconData icon,
  }) {
    final isSelected = _selectedDensity == density;
    final isCompact = density == RoutineViewDensity.compact;

    return Material(
      color: isSelected
          ? AppColors.surfaceContainerLow
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDensity = density;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryFixed
                          : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.onPrimaryFixed
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.onPrimary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                density.label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                density.description,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Miniature visual wireframe matching Stitch mockup
              if (isCompact)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildMiniCompactRow(28, 14),
                      const SizedBox(height: 4),
                      _buildMiniCompactRow(36, 10),
                      const SizedBox(height: 4),
                      _buildMiniCompactRow(22, 14, isDarkAccent: true),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.ambientShadow,
                        blurRadius: 6,
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
                          Container(
                            width: 40,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 3),
                      FractionallySizedBox(
                        widthFactor: 0.75,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCompactRow(
    double leftWidth,
    double rightWidth, {
    bool isDarkAccent = false,
  }) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: leftWidth,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: rightWidth,
            height: 3,
            decoration: BoxDecoration(
              color: isDarkAccent ? AppColors.primary : AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection3Filter(int activeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter by Ritual Time',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$activeCount Active',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              filter: RitualTimeFilter.all,
              label: 'All ($activeCount)',
              icon: Icons.check_rounded,
            ),
            _buildFilterChip(
              filter: RitualTimeFilter.morning,
              label: 'Morning',
              icon: Icons.wb_sunny_rounded,
            ),
            _buildFilterChip(
              filter: RitualTimeFilter.afternoon,
              label: 'Afternoon',
              icon: Icons.wb_twilight_rounded,
            ),
            _buildFilterChip(
              filter: RitualTimeFilter.evening,
              label: 'Evening',
              icon: Icons.bedtime_rounded,
            ),
            _buildFilterChip(
              filter: RitualTimeFilter.custom,
              label: 'Custom',
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required RitualTimeFilter filter,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;

    return Material(
      color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.onPrimary : AppColors.outline,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Small steps, done consistently',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Preferences automatically sync with your daily habit log',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Apply Button
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: FilledButton(
            onPressed: _applyPreferences,
            style: FilledButton.styleFrom(
              backgroundColor: _isSavedFeedback
                  ? AppColors.primaryContainer
                  : AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSavedFeedback ? 'Saved & Updated' : 'Apply Preferences',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isSavedFeedback
                      ? Icons.done_all_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Reset to Default View Text Button
        TextButton(
          onPressed: _resetDefaults,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          child: Text(
            'Reset to Default View',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
