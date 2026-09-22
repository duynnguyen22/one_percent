import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../injection/dependency_injection.dart';

/// Stitch Screen: Offline Screen
/// Project: One Percent Habit Tracker
/// Screen ID: c912a905cb3f45a79c26cdd80af1b697
class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({
    super.key,
    this.flowTitle = 'Add Habit Flow',
    this.lastSyncedText = 'Synced 8:30 AM',
    this.animatePulse = true,
    this.onReconnect,
    this.onContinueOffline,
  });

  /// Contextual header title representing the flow the user was in.
  final String flowTitle;

  /// Human-readable time when local data was last synced.
  final String lastSyncedText;

  /// Whether to loop the pulsing dot animation on the status badge.
  final bool animatePulse;

  /// Optional custom reconnect handler. When null, checks [networkInfoProvider].
  final Future<bool> Function()? onReconnect;

  /// Optional custom continue offline handler. When null, pops or navigates to today.
  final VoidCallback? onContinueOffline;

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isChecking = false;
  bool _showSignalToast = false;
  Timer? _toastTimer;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animatePulse && !_isInTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showFeedbackToast() {
    _toastTimer?.cancel();
    setState(() => _showSignalToast = true);
    _toastTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showSignalToast = false);
      }
    });
  }

  Future<void> _handleReconnect() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _showSignalToast = false;
    });

    bool isOnline = false;
    try {
      if (widget.onReconnect != null) {
        isOnline = await widget.onReconnect!();
      } else {
        final networkInfo = ref.read(networkInfoProvider);
        if (!_isInTest) {
          final results = await Future.wait([
            networkInfo.isConnected,
            Future<void>.delayed(const Duration(milliseconds: 600)),
          ]);
          isOnline = results[0] as bool;
        } else {
          isOnline = await networkInfo.isConnected;
        }
      }
    } catch (_) {
      isOnline = false;
    }

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isOnline) {
      AppToast.success('Connection restored!');
      if (mounted) {
        try {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.today);
          }
        } catch (_) {}
      }
    } else {
      _showFeedbackToast();
    }
  }

  void _handleContinueOffline() {
    if (widget.onContinueOffline != null) {
      widget.onContinueOffline!();
      return;
    }

    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.today);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed / Top Header with Back, Bloom Logo, Title & Avatar
            _buildHeader(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Status Bar: Offline Mode Active & Last Synced
                        _buildStatusBar(),
                        const SizedBox(height: 24),

                        // Hero Visual: Ambient Tactile Disconnect Blossom Badge
                        _buildHeroVisual(),
                        const SizedBox(height: 24),

                        // Typography Hierarchy
                        Text(
                          'Connection Paused',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineLargeMobile.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Your space of calm remains unbroken. Daily rituals and streaks are preserved on your device, quietly ready to sync when you return.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Offline Capabilities Bento Card
                        _buildCapabilitiesCard(),
                        const SizedBox(height: 32),

                        // Action Buttons Stack
                        AppButton(
                          label: _isChecking ? 'Checking connection...' : 'Try Reconnecting',
                          icon: Icons.refresh_rounded,
                          isLoading: _isChecking,
                          onPressed: _handleReconnect,
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: 'Continue in Offline Mode',
                          onPressed: _handleContinueOffline,
                        ),

                        // Reconnection Feedback Toast (Animated pill)
                        AnimatedOpacity(
                          opacity: _showSignalToast ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: AppSpacing.borderRadiusPill,
                                boxShadow: AppSpacing.ambientShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.signal_cellular_nodata_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Still searching for signal. You're safe to proceed offline.",
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerMargin,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x0A000000),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(RouteNames.today);
                    }
                  },
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Image.asset(
                  AppAssets.bloomLogo,
                  height: 26,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.flowTitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // User Avatar
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pulsing Offline Mode Active Capsule
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppSpacing.borderRadiusPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline Mode Active',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Last Synced Timestamp
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: AppColors.outline,
            ),
            const SizedBox(width: 6),
            Text(
              widget.lastSyncedText,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return Center(
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft ambient aura
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

            // Tier 1: Outer base circle
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
                boxShadow: AppSpacing.ambientShadow,
              ),
            ),

            // Tier 2: Inner botanical ring
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),

            // Disconnect Sub-badge at bottom-right
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  boxShadow: AppSpacing.ambientShadow,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusCard,
        boxShadow: AppSpacing.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Always Available Offline',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feature 1
          _buildCapabilityRow(
            icon: Icons.check_rounded,
            title: 'Log mindful habits & check-ins',
            subtitle: 'Your streaks remain continuous and intact.',
          ),
          const SizedBox(height: 14),

          // Feature 2
          _buildCapabilityRow(
            icon: Icons.check_rounded,
            title: 'Access guided timers & notes',
            subtitle: 'Cached audio rings and reflections load instantly.',
          ),
          const SizedBox(height: 14),

          // Feature 3
          _buildCapabilityRow(
            icon: Icons.sync_rounded,
            title: 'Seamless automatic sync',
            subtitle: 'Changes quietly merge once connection resumes.',
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
