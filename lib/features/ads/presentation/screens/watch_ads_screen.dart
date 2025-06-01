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

// State providers for managing UI states
final isAdPlayingProvider = StateProvider<bool>((ref) => false);
final timerSecondsProvider = StateProvider<int>((ref) => 5);
final dailyProgressProvider = StateProvider<int>((ref) =>19); // Current ads watched today
final maxDailyAdsProvider = StateProvider<int>((ref) => 20); // Maximum ads per day
final rewardAmountProvider = StateProvider<int>((ref) => 10); // Base reward amount

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

    // For pulse animation
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 900),
      initialValue: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(context, colorScheme, textTheme, progress),
              const SizedBox(height: 32),
              _buildTimerCard(context, colorScheme, textTheme, isAdPlaying, timerSeconds, ref, pulseController, isLimit),
              const SizedBox(height: 32),
              _buildProgressCard(context, colorScheme, textTheme, dailyProgress, maxDailyAds, progress, isLimit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: colorScheme.onPrimary, size: 40),
          const SizedBox(height: 12),
          Text(
            'Earn Rewards by Watching Ads',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            progress < 1.0
                ? 'Watch ads, verify, and collect coins!'
                : "You have reached today's limit. Come back tomorrow!",
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.85),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isAdPlaying
                  ? _buildAnimatedTimer(colorScheme, textTheme, timerSeconds, pulseController)
                  : Icon(Icons.play_circle_outline, color: colorScheme.primary, size: 64, key: const ValueKey('play')),
            ),
            const SizedBox(height: 24),
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
                  : Text(
                      isLimit ? 'Daily limit reached' : 'Tap below to start',
                      style: textTheme.titleMedium?.copyWith(
                        color: isLimit ? colorScheme.error : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      key: const ValueKey('tap'),
                    ),
            ),
            const SizedBox(height: 32),




            
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isAdPlaying
                  ? const SizedBox(height: 56)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.play_arrow_rounded, color: colorScheme.onPrimary),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            isLimit ? 'Come Back Tomorrow' : 'Watch Now',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLimit ? colorScheme.surfaceVariant : colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: isLimit ? 0 : 4,
                        ),
                        onPressed: isLimit || isAdPlaying
                            ? null
                            : () => _handleTimerStart(context, ref),
                      ),
                    ),
            ),
          ],
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
            width: 90,
            height: 90,
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLimit ? Icons.celebration : Icons.trending_up,
                  color: isLimit ? colorScheme.primary : colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isLimit ? 'All Done!' : 'Daily Progress',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            Text(
              '$dailyProgress / $maxDailyAds ads completed',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isLimit)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "You've reached today's limit. Great job! 🎉",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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