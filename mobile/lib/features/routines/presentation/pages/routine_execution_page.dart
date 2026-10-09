import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/routine.dart';
import '../providers/routines_provider.dart';

/// Routine Execution Player (Stitch Screens 5 & 6 - 3c3e8b254cf84f48bf9d146472f04843 & ccd38dc4317d43768539f0d34c1bd475).
/// Guided step-by-step player with timer, breathing cadence, and auto-sync notice.
class RoutineExecutionPage extends ConsumerStatefulWidget {
  const RoutineExecutionPage({
    super.key,
    required this.routine,
    this.initialStepIndex = 0,
  });

  final Routine routine;
  final int initialStepIndex;

  @override
  ConsumerState<RoutineExecutionPage> createState() =>
      _RoutineExecutionPageState();
}

class _RoutineExecutionPageState extends ConsumerState<RoutineExecutionPage> {
  late int _currentStepIndex;
  late int _secondsRemaining;
  Timer? _ticker;
  bool _isPaused = false;
  bool _isSoundEnabled = true;

  /// Indexes of steps finished with "Done", as opposed to skipped.
  final Set<int> _logged = {};

  bool get _hasSteps => widget.routine.steps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasSteps) return;
    _currentStepIndex = widget.initialStepIndex.clamp(
      0,
      widget.routine.steps.length - 1,
    );
    _resetTimerForCurrentStep();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _resetTimerForCurrentStep() {
    _secondsRemaining = _currentStep.durationMinutes * 60;
  }

  void _tick() {
    if (_isPaused || _secondsRemaining <= 0) return;
    setState(() => _secondsRemaining--);
  }

  double get _progress {
    final total = _currentStep.durationMinutes * 60;
    return total == 0 ? 0 : _secondsRemaining / total;
  }

  RoutineStep get _currentStep => widget.routine.steps[_currentStepIndex];
  bool get _hasNextStep => _currentStepIndex < widget.routine.steps.length - 1;

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _toggleSound() {
    setState(() => _isSoundEnabled = !_isSoundEnabled);
  }

  /// Checks the current step's habit off on Today, then moves on without
  /// waiting: the player should not stall on a round trip.
  void _onDoneAndNext() {
    final step = _currentStep;
    _logged.add(_currentStepIndex);
    if (!step.isCompleted) {
      // Read now: the page may be gone by the time the request finishes.
      final notifier = ref.read(routinesProvider.notifier);
      notifier.completeStep(widget.routine.id, step.habitId).then((failure) {
        if (failure != null) {
          AppToast.error('Could not log ${step.title}: ${failure.message}');
        }
      });
    }
    _advance();
  }

  void _advance() {
    if (_hasNextStep) {
      setState(() {
        _currentStepIndex++;
        _resetTimerForCurrentStep();
        _isPaused = false;
      });
    } else {
      // Completed all steps! Go through the router: a raw Navigator route
      // would sit outside go_router and survive every later `goNamed`.
      context.pushReplacementNamed(
        RouteNames.routineCompleted,
        pathParameters: {'routineId': widget.routine.id},
      );
    }
  }

  void _onSkip() => _advance();

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSteps) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
        body: const AppError(
          title: 'No active habits in this routine',
          message: 'Its habits were archived. Edit the routine to add some.',
          icon: Icons.spa_outlined,
        ),
      );
    }

    final accentColor = Color(
      int.parse(widget.routine.accentColorHex.replaceAll('#', '0xFF')),
    );
    final step = _currentStep;
    final totalSteps = widget.routine.steps.length;

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
              // Top Step Logged Toast Banner (When on step 2+)
              if (_logged.contains(_currentStepIndex - 1)) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.6),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Step $_currentStepIndex logged to Today (+${widget.routine.steps[_currentStepIndex - 1].durationMinutes} min) · +1%',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Header Bar: Close (X), Routine Title & Step, Sound Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.onSurface,
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.routine.name.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step ${_currentStepIndex + 1} of $totalSteps',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSoundEnabled
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_off_rounded,
                        size: 20,
                        color: _isSoundEnabled
                            ? accentColor
                            : AppColors.outline,
                      ),
                      onPressed: _toggleSound,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step Progress Indicators
              if (_currentStepIndex == 0) ...[
                // Dots indicator on step 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) {
                    final isActive = i == _currentStepIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? accentColor
                            : AppColors.surfaceContainerHigh,
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                    );
                  }),
                ),
              ] else ...[
                // Segmented progress bar on step 2+
                Row(
                  children: List.generate(totalSteps, (i) {
                    final isComplete = i < _currentStepIndex;
                    final isActive = i == _currentStepIndex;

                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isComplete || isActive
                              ? accentColor
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),

              // Notification Pill / Ambient Audio badge (Step 2+)
              if (_currentStepIndex > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(step.icon, color: accentColor, size: 24),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Soft bell every 60s',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Circular Countdown Timer
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular background track
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceContainerLow,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStepIndex == 0) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 18,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            _formatTime(_secondsRemaining),
                            style: AppTypography.display.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            _currentStepIndex == 0 ? 'REMAINING' : 'IN FLOW',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.outline,
                              letterSpacing: 1.2,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Breathing cadence (for stretch/meditation)
              if (_currentStepIndex > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Flexible(
                      child: Text(
                        'Inhale 4s · Exhale 6s',
                        style: AppTypography.labelSmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Habit Title & Description
              Text(
                step.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  step.description.isNotEmpty
                      ? step.description
                      : 'Take this time to align with your ritual and breathe calmly.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 1 Specific Cards: Mindful Intention & Portion Goal
              if (_currentStepIndex == 0) ...[
                // Mindful Intention Card
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.eco_outlined,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mindful Intention',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.mindfulIntention.isNotEmpty
                                  ? step.mindfulIntention
                                  : 'Take small, deliberate sips. Feel the coolness soothe your throat as your senses gently arrive.',
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
                const SizedBox(height: 12),

                // Portion Goal Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_cafe_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portion Goal',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                            Text(
                              step.portionGoal.isNotEmpty
                                  ? step.portionGoal
                                  : '1 tall ceramic glass (250ml)',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          '+1% today',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // The current step's sub-moves, with the one now playing marked.
              if (step.guides.isNotEmpty) ...[
                _GuidedSequence(
                  guides: step.guides,
                  activeIndex: step.activeGuideIndex(
                    step.durationMinutes * 60 - _secondsRemaining,
                  ),
                  accentColor: accentColor,
                ),
                const SizedBox(height: 16),
              ],

              // The routine's own steps, so the user sees where they are.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.borderRadiusCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR SEQUENCE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    for (final (i, step) in widget.routine.steps.indexed) ...[
                      SizedBox(height: i == 0 ? 12 : 8),
                      _SequenceStepItem(
                        key: ValueKey('sequence-step-${step.habitId}'),
                        number: '${i + 1}',
                        title: step.title,
                        badge: i == _currentStepIndex
                            ? 'Active · ${step.durationMinutes}m'
                            : _logged.contains(i) || step.isCompleted
                            ? 'Done'
                            : '${step.durationMinutes} min',
                        isActive: i == _currentStepIndex,
                        isDone: _logged.contains(i) || step.isCompleted,
                        accentColor: accentColor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Done & Next Primary Button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: _onDoneAndNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.onPrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  iconAlignment: IconAlignment.end,
                  label: Text(
                    _hasNextStep ? 'Done & Next' : 'Complete Routine',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pause & Skip Controls
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: TextButton.icon(
                        onPressed: _togglePause,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 18,
                          color: AppColors.onSurface,
                        ),
                        label: Text(
                          _isPaused ? 'Resume' : 'Pause',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip Step',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Auto-sync / Up next Footer Note
              if (_currentStepIndex == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_box_outlined,
                      size: 14,
                      color: AppColors.outline,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Completing this automatically checks off ${step.title} on Today',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.outline,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_hasNextStep) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.outline,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Up next: ${widget.routine.steps[_currentStepIndex + 1].title} (${widget.routine.steps[_currentStepIndex + 1].durationMinutes} min)',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.outline,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidedSequence extends StatelessWidget {
  const _GuidedSequence({
    required this.guides,
    required this.activeIndex,
    required this.accentColor,
  });

  final List<RoutineGuide> guides;
  final int? activeIndex;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('guided-sequence'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GUIDED SEQUENCE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          for (final (i, guide) in guides.indexed) ...[
            SizedBox(height: i == 0 ? 12 : 8),
            _SequenceStepItem(
              key: ValueKey('guide-$i'),
              number: '${i + 1}',
              title: guide.title,
              badge: i == activeIndex
                  ? 'Active · ${guide.compactLabel}'
                  : guide.durationLabel,
              isActive: i == activeIndex,
              isDone: activeIndex != null && i < activeIndex!,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _SequenceStepItem extends StatelessWidget {
  const _SequenceStepItem({
    super.key,
    required this.number,
    required this.title,
    required this.badge,
    required this.isActive,
    required this.isDone,
    required this.accentColor,
  });

  final String number;
  final String title;
  final String badge;
  final bool isActive;
  final bool isDone;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceContainerLowest : Colors.transparent,
        borderRadius: AppSpacing.borderRadiusCard,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? accentColor : AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone && !isActive
                ? Icon(Icons.check_rounded, size: 14, color: accentColor)
                : Text(
                    number,
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: isDone && !isActive
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                decoration: isDone && !isActive
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            badge,
            style: AppTypography.labelSmall.copyWith(
              color: isActive || isDone ? accentColor : AppColors.outline,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
