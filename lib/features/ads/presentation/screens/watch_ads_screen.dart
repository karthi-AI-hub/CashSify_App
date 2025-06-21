import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
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
import 'package:cashsify_app/core/providers/earnings_provider.dart';
import 'package:confetti/confetti.dart';

// State providers for managing UI states
final isAdPlayingProvider = StateProvider<bool>((ref) => false);
final timerSecondsProvider = StateProvider<int>((ref) => 5);
final isLoadingProvider = StateProvider<bool>((ref) => false);

class WatchAdsScreen extends HookConsumerWidget {
  const WatchAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAdPlaying = ref.watch(isAdPlayingProvider);
    final timerSeconds = ref.watch(timerSecondsProvider);
    final earningsState = ref.watch(earningsProvider);
    final adsWatchedToday = earningsState.when(
      data: (earnings) => earnings?.adsWatchedToday ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final progress = adsWatchedToday / 20;
    final isLimit = earningsState.when(
      data: (earnings) => earnings?.hasReachedDailyLimit ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
    final isLoading = ref.watch(isLoadingProvider);
    final loadingState = ref.watch(loadingProvider);

    // For pulse animation
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Confetti controller for celebration
    final confettiController = useMemoized(() => ConfettiController());
    useEffect(() {
      if (isLimit) {
        confettiController.play();
      }
      return null;
    }, [isLimit]);

    // Dispose confetti controller when widget is disposed
    useEffect(() {
      return () {
        confettiController.dispose();
      };
    }, []);

    return Stack(
      children: [
        LoadingOverlay(
          isLoading: loadingState == LoadingState.loading,
          message: loadingState == LoadingState.loading ? 'Loading ads...' : null,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 360;
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(earningsProvider.notifier).loadEarnings();
                  },
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 16 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _AnimatedFadeIn(
                            delay: 0,
                            child: _buildHeader(
                              context,
                              colorScheme,
                              textTheme,
                              progress,
                              isLimit,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _AnimatedFadeIn(
                            delay: 100,
                            child: isLoading
                                ? const _ShimmerLoadingCard()
                                : _buildTimerCard(
                                    context,
                                    colorScheme,
                                    textTheme,
                                    isAdPlaying,
                                    timerSeconds,
                                    ref,
                                    pulseController,
                                    isLimit,
                                    adsWatchedToday,
                                  ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _AnimatedFadeIn(
                            delay: 200,
                            child: _buildProgressCard(
                              context,
                              colorScheme,
                              textTheme,
                              adsWatchedToday,
                              20,
                              progress,
                              isLimit,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          _AnimatedFadeIn(
                            delay: 300,
                            child: _buildInfoSection(context, colorScheme, textTheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Confetti effect when daily limit is reached
        if (isLimit)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              gravity: 0.1,
              emissionFrequency: 0.05,
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double progress,
    bool isLimit,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.9),
            colorScheme.secondary.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: isLimit
                ? Icon(
                    Icons.celebration_rounded,
                    color: colorScheme.onPrimary,
                    size: 42,
                    key: const ValueKey('celebration'),
                  )
                : Icon(
                    Icons.emoji_events_rounded,
                    color: colorScheme.onPrimary,
                    size: 42,
                    key: const ValueKey('trophy'),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            isLimit
                ? "🎉 Congratulations! Daily goal achieved!"
                : progress > 0.5
                    ? 'Keep going! You\'re almost there!'
                    : 'Watch ads, verify and earn coins!',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isLimit) ...[
            const SizedBox(height: 8),
            Text(
              'Complete ${(20 - (progress * 20).toInt())} more ads to earn coins',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
    int adsWatchedToday,
  ) {
    return CustomCard(
      elevation: 6,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: isAdPlaying
                  ? _buildAnimatedTimer(colorScheme, textTheme, timerSeconds, pulseController)
                  : Icon(
                      Icons.play_circle_fill_rounded,
                      color: isLimit ? colorScheme.onSurfaceVariant : colorScheme.primary,
                      size: 80,
                      key: const ValueKey('play'),
                    ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isAdPlaying
                  ? Text(
                      'Preparing your ad...',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      key: const ValueKey('wait'),
                    )
                  : Text(
                      'Ready to watch?',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      key: const ValueKey('tap'),
                    ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isAdPlaying
                  ? const SizedBox(height: 56)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLimit
                              ? colorScheme.surfaceVariant
                              : colorScheme.primary,
                          foregroundColor: isLimit
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: isLimit ? 0 : 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowColor: colorScheme.primary.withOpacity(0.3),
                        ),
                        onPressed: isLimit || isAdPlaying
                            ? null
                            : () => _handleTimerStart(context, ref),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLimit
                                  ? Icons.timer_off_rounded
                                  : Icons.play_arrow_rounded,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isLimit ? 'Come Back Tomorrow' : 'Watch Now',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isLimit 
                                    ? colorScheme.onSurface 
                                    : colorScheme.onPrimary,
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
    );
  }

  Widget _buildAnimatedTimer(
    ColorScheme colorScheme,
    TextTheme textTheme,
    int timerSeconds,
    AnimationController pulseController,
  ) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.05 * pulseController.value;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (5 - timerSeconds) / 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary),
                  backgroundColor: colorScheme.surfaceVariant,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$timerSeconds',
                      style: textTheme.displayMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
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
    int adsWatchedToday,
    int maxDailyAds,
    double progress,
    bool isLimit,
  ) {
    return CustomCard(
      elevation: 4,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLimit ? Icons.verified_rounded : Icons.trending_up_rounded,
                  color: isLimit ? colorScheme.primary : colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isLimit ? 'Mission Complete!' : 'Daily Progress',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            height: 12,
                            width: MediaQuery.of(context).size.width * value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ads watched today',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$adsWatchedToday/$maxDailyAds',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (isLimit) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You've completed today's task. Come back tomorrow for more!",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return CustomCard(
      elevation: 2,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              context,
              '1. Watch the ad',
              Icons.play_circle_outline_rounded,
              colorScheme,
            ),
            _buildInfoItem(
              context,
              '2. Complete the verification',
              Icons.verified_outlined,
              colorScheme,
            ),
            _buildInfoItem(
              context,
              '3. Earn coins after 20 ads',
              Icons.stars,
              colorScheme,
            ),
            _buildInfoItem(
              context,
              'Daily tasks reset at midnight',
              Icons.schedule,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String text,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTimerStart(BuildContext context, WidgetRef ref) async {
    final earningsState = ref.read(earningsProvider);
    if (earningsState.when(
      data: (earnings) => earnings?.hasReachedDailyLimit ?? false,
      loading: () => false,
      error: (_, __) => false,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.timer_off_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              const Text('Daily limit reached. Come back tomorrow!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    ref.read(isAdPlayingProvider.notifier).state = true;
    ref.read(timerSecondsProvider.notifier).state = 5;

    // Countdown animation
    for (int i = 5; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      ref.read(timerSecondsProvider.notifier).state = i - 1;
    }

    if (context.mounted) {
      final result = await context.push<bool>('/verification');

      if (result == true) {
        // After successful verification
        await ref.read(earningsProvider.notifier).loadEarnings();
        
        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Ad verified successfully!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    ref.read(isAdPlayingProvider.notifier).state = false;
    ref.read(timerSecondsProvider.notifier).state = 5;
  }
}

class _ShimmerLoadingCard extends StatelessWidget {
  const _ShimmerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      elevation: 4,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerLoading(
              width: 100,
              height: 100,
              borderRadius: 50,
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

class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedFadeIn({required this.child, required this.delay});

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 1, curve: Curves.easeOut),
      ),
    );

    _translateY = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 1, curve: Curves.easeOutBack),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}