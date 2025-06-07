import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' as math;
import '../../../../theme/app_theme.dart';
import 'package:cashsify_app/features/ads/presentation/screens/verification_screen.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/widgets/optimized_image.dart';
import 'package:cashsify_app/core/widgets/layout/custom_card.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/widgets/feedback/shimmer_loading.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_tooltip.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';

// State providers for managing UI states
final isAdPlayingProvider = StateProvider<bool>((ref) => false);
final timerSecondsProvider = StateProvider<int>((ref) => 5);
final dailyProgressProvider = StateProvider<int>((ref) =>19); // Current ads watched today
final maxDailyAdsProvider = StateProvider<int>((ref) => 20); // Maximum ads per day
final rewardAmountProvider = StateProvider<int>((ref) => 10); // Base reward amount
final isLoadingProvider = StateProvider<bool>((ref) => false);

class WatchAdsScreen extends HookConsumerWidget {
  const WatchAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAdPlaying = ref.watch(isAdPlayingProvider);
    final timerSeconds = ref.watch(timerSecondsProvider);
    final dailyProgress = ref.watch(dailyProgressProvider);
    final maxDailyAds = ref.watch(maxDailyAdsProvider);
    final progress = dailyProgress / maxDailyAds;
    final isLimit = dailyProgress >= maxDailyAds;
    final isLoading = ref.watch(isLoadingProvider);
    final loadingState = ref.watch(loadingProvider);

    // For pulse animation
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 900),
      initialValue: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading,
      message: loadingState == LoadingState.loading ? 'Loading ads...' : null,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeader(context, colorScheme, textTheme, progress),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    if (isLoading)
                      const _ShimmerLoadingCard()
                    else
                      _buildTimerCard(
                        context,
                        colorScheme,
                        textTheme,
                        isAdPlaying,
                        timerSeconds,
                        ref,
                        pulseController,
                        isLimit,
                      ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildProgressCard(
                      context,
                      colorScheme,
                      textTheme,
                      dailyProgress,
                      maxDailyAds,
                      progress,
                      isLimit,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85), colorScheme.secondary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: colorScheme.onPrimary, size: 38),
          // const SizedBox(height: 16),
          // Removed header text for a more compact screen
          // Text(
          //   'Earn Rewards by Watching Ads',
          //   style: textTheme.headlineSmall?.copyWith(
          //     color: colorScheme.onPrimary,
          //     fontWeight: FontWeight.w900,
          //     fontSize: 22,
          //     letterSpacing: 0.5,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
          const SizedBox(height: 10),
          Text(
            progress < 1.0
                ? 'Watch ads, verify, and collect coins!'
                : "🎉 You have reached today's limit!",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.92),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isAdPlaying,
    int timerSeconds,
    WidgetRef ref,
    AnimationController pulseController,
    bool isLimit,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isAdPlaying
                    ? _buildAnimatedTimer(colorScheme, textTheme, timerSeconds, pulseController)
                    : Icon(
                        Icons.play_circle_fill_rounded,
                        color: colorScheme.primary,
                        size: 72,
                        key: const ValueKey('play'),
                      ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isAdPlaying
                    ? Text(
                        'Please wait... ',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        key: const ValueKey('wait'),
                      )
                    : isLimit
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Daily limit reached',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          )
                        : Text(
                            'Tap below to start',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            key: const ValueKey('tap'),
                          ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isAdPlaying
                    ? const SizedBox(height: 56)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.play_arrow_rounded,
                                color: colorScheme.onPrimary,
                              ),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  isLimit ? 'Come Back Tomorrow' : 'Watch Now',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLimit ? colorScheme.surfaceVariant : colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: isLimit ? 0 : 6,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: isLimit || isAdPlaying
                                  ? null
                                  : () => _handleTimerStart(context, ref),
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

  Widget _buildAnimatedTimer(ColorScheme colorScheme, TextTheme textTheme, int timerSeconds, AnimationController pulseController) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.08 * pulseController.value;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (5 - timerSeconds) / 5,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  backgroundColor: colorScheme.surfaceVariant,
                  strokeWidth: 7,
                ),
                Text(
                  '$timerSeconds',
                  style: textTheme.displayMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    int dailyProgress,
    int maxDailyAds,
    double progress,
    bool isLimit,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLimit ? Icons.celebration : Icons.trending_up,
                  color: isLimit ? colorScheme.primary : colorScheme.secondary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Text(
                  isLimit ? 'All Done!' : 'Daily Progress',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$dailyProgress / $maxDailyAds ads completed',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (isLimit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "You've reached today's limit. Great job! 🎉",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTimerStart(BuildContext context, WidgetRef ref) async {
    final dailyProgress = ref.read(dailyProgressProvider);
    final maxDailyAds = ref.read(maxDailyAdsProvider);

    if (dailyProgress >= maxDailyAds) {
      CustomToast.show(
        context,
        message: 'Daily limit reached. Come back tomorrow!',
        type: ToastType.warning,
      );
      return;
    }

    ref.read(isAdPlayingProvider.notifier).state = true;
    ref.read(timerSecondsProvider.notifier).state = 5;

    for (int i = 5; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      ref.read(timerSecondsProvider.notifier).state = i - 1;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationScreen(),
        ),
      ).then((verified) {
        if (verified == true) {
          ref.read(dailyProgressProvider.notifier).state++;
          CustomToast.show(
            context,
            message: 'Ad verified! Coins added to your balance.',
            type: ToastType.success,
            duration: const Duration(seconds: 2),
            showCloseButton: true,
          );
        }
        ref.read(isAdPlayingProvider.notifier).state = false;
        ref.read(timerSecondsProvider.notifier).state = 5;
      });
    } else {
      ref.read(isAdPlayingProvider.notifier).state = false;
      ref.read(timerSecondsProvider.notifier).state = 5;
    }
  }
}

class _ShimmerLoadingCard extends StatelessWidget {
  const _ShimmerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerLoading(
              width: 90,
              height: 90,
              borderRadius: 45,
            ),
            const SizedBox(height: 24),
            ShimmerLoading(
              width: 200,
              height: 24,
              borderRadius: 12,
            ),
            const SizedBox(height: 32),
            ShimmerLoading(
              width: double.infinity,
              height: 56,
              borderRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}