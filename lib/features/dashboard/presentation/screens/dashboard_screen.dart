import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../theme/app_spacing.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/widgets/feedback/shimmer_loading.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/providers/earnings_provider.dart';
import 'package:cashsify_app/core/models/user_state.dart';
import 'package:cashsify_app/core/models/earnings_state.dart';
import 'package:cashsify_app/core/services/earnings_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? serverTime;
  DateTime? deviceTimeAtFetch;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchServerTime);
  }

  Future<void> _fetchServerTime() async {
    try {
      if (!mounted) return;
      ref.read(loadingProvider.notifier).startLoading();
      
      final fetched = await SupabaseService().getServerTime();
      
      if (!mounted) return;
      setState(() {
        serverTime = fetched;
        deviceTimeAtFetch = DateTime.now();
        isLoading = false;
      });
      if (!mounted) return;
      ref.read(loadingProvider.notifier).finishLoading();
    } catch (e) {
      if (!mounted) return;
      setState(() { isLoading = false; });
      if (!mounted) return;
      ref.read(loadingProvider.notifier).setError();
    }
  }

  DateTime getTrustedNow() {
    if (serverTime == null || deviceTimeAtFetch == null) return DateTime.now();
    final elapsed = DateTime.now().difference(deviceTimeAtFetch!);
    return serverTime!.add(elapsed);
  }

  Future<void> _onWatchAdPressed() async {
    final canWatch = await ref.read(earningsProvider.notifier).canWatchMoreAds();
    if (!canWatch) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily ad limit reached. Try again tomorrow!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushNamed(context, '/ad');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadingState = ref.watch(loadingProvider);
    final userState = ref.watch(userProvider);
    final earningsState = ref.watch(earningsProvider);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading,
      message: loadingState == LoadingState.loading ? 'Loading dashboard...' : null,
      child: isLoading
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(userProvider.notifier).refreshUser();
                await ref.read(earningsProvider.notifier).loadEarnings();
              },
              child: _buildDashboardContent(context, userState, earningsState),
            ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    AsyncValue<UserState?> userState,
    AsyncValue<EarningsState?> earningsState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? AppSpacing.md : AppSpacing.xl;
    final verticalPadding = isSmallScreen ? AppSpacing.lg : AppSpacing.xxl;
    final cardSpacing = isSmallScreen ? AppSpacing.md : AppSpacing.xl;
    final cardFontSize = isSmallScreen ? 18.0 : null;
    final trustedNow = getTrustedNow();
    final todayDate = DateFormat('dd/MM/yyyy').format(trustedNow);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        children: [
          // Welcome Header
          _AnimatedFadeIn(
            delay: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${userState.when(
                      data: (user) => user?.name ?? 'User',
                      loading: () => '...',
                      error: (_, __) => 'User',
                    )}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: cardFontSize != null ? cardFontSize + 2 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    "Let's earn coins today!",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: cardFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          // Coin Summary Cards
          _AnimatedFadeIn(
            delay: 100,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  // Stack vertically on very small screens
                  return Column(
                    children: [
                      _CoinCard(
                        title: 'Total Coins',
                        value: userState.when(
                          data: (user) => user?.coins ?? 0,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                        label: 'Available in Wallet',
                        color: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                        icon: Icons.stars,
                        animate: true,
                        isSmall: true,
                      ),
                      SizedBox(height: cardSpacing),
                      _CoinCard(
                        title: "Today's Coins ($todayDate)",
                        value: earningsState.when(
                          data: (earnings) => earnings?.coinsEarned ?? 0,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                        label: 'Since midnight',
                        color: colorScheme.surface,
                        textColor: colorScheme.onSurface,
                        icon: Icons.stars,
                        animate: true,
                        isSmall: true,
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _CoinCard(
                          title: 'Total Coins',
                          value: userState.when(
                            data: (user) => user?.coins ?? 0,
                            loading: () => 0,
                            error: (_, __) => 0,
                          ),
                          label: 'Lifetime earnings',
                          color: colorScheme.primary,
                          textColor: colorScheme.onPrimary,
                          icon: Icons.stars,
                          animate: true,
                          isSmall: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _CoinCard(
                          title: "Today's Coins ($todayDate)",
                          value: earningsState.when(
                            data: (earnings) => earnings?.coinsEarned ?? 0,
                            loading: () => 0,
                            error: (_, __) => 0,
                          ),
                          label: 'Since midnight',
                          color: colorScheme.surface,
                          textColor: colorScheme.onSurface,
                          icon: Icons.stars,
                          animate: true,
                          isSmall: isSmallScreen,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          // Tasks Section
          _AnimatedFadeIn(
            delay: 300,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Today's Tasks",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: cardFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${earningsState.when(
                            data: (earnings) => earnings?.adsWatchedToday ?? 0,
                            loading: () => 0,
                            error: (_, __) => 0,
                          )}/20 Completed',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: cardFontSize != null ? cardFontSize - 2 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '${20 - (earningsState.when(
                      data: (earnings) => earnings?.adsWatchedToday ?? 0,
                      loading: () => 0,
                      error: (_, __) => 0,
                    ))} tasks remaining today',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: cardFontSize != null ? cardFontSize - 4 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Divider(thickness: 1, color: colorScheme.surfaceVariant),
                  SizedBox(height: AppSpacing.md),
                  _TaskCard(
                    isSmall: isSmallScreen,
                    adsWatched: earningsState.when(
                      data: (earnings) => earnings?.adsWatchedToday ?? 0,
                      loading: () => 0,
                      error: (_, __) => 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _CoinCard extends StatelessWidget {
  final String title;
  final int value;
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final bool animate;
  final bool isSmall;
  const _CoinCard({
    required this.title,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    this.animate = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double iconSize = isSmall ? 22 : 28;
    final double? titleFontSize = isSmall ? 14 : null;
    final double? valueFontSize = isSmall ? 22 : null;
    final double? labelFontSize = isSmall ? 11 : null;
    final double cardPadding = isSmall ? AppSpacing.md : AppSpacing.lg;
    final isTodayCoins = title.startsWith("Today's Coins");
    final todayDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String displayTitle = title;
    if (isTodayCoins) {
      displayTitle = "Today's Coins ($todayDate)";
    }
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      color: color,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: textTheme.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: titleFontSize),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(icon, color: textColor, size: iconSize),
                SizedBox(width: AppSpacing.sm),
                Text(
                  value.toString(),
                  style: textTheme.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: valueFontSize),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.8), fontSize: labelFontSize),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final bool isSmall;
  final int adsWatched;
  
  const _TaskCard({
    this.isSmall = false,
    required this.adsWatched,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double cardPadding = isSmall ? AppSpacing.md : AppSpacing.lg;
    final double? titleFontSize = isSmall ? 14 : null;
    final double? labelFontSize = isSmall ? 11 : null;
    final double? statusFontSize = isSmall ? 11 : null;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.play_arrow, color: colorScheme.primary, size: isSmall ? 18 : 24),
                  radius: isSmall ? 16 : 20,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Task',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    adsWatched >= 20 ? 'Completed' : 'In Progress',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: statusFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: adsWatched / 20),
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: isSmall ? 6 : 8,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$adsWatched/20 ads watched',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: labelFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        _ResetCountdown(
                          isSmall: isSmall,
                          textColor: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetCountdown extends StatefulWidget {
  final bool isSmall;
  final Color textColor;
  
  const _ResetCountdown({
    required this.isSmall,
    required this.textColor,
  });

  @override
  State<_ResetCountdown> createState() => _ResetCountdownState();
}

class _ResetCountdownState extends State<_ResetCountdown> {
  late Timer _timer;
  late Duration _timeUntilMidnight;
  late TextTheme textTheme;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateTimeUntilMidnight();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textTheme = Theme.of(context).textTheme;
  }

  void _calculateTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeUntilMidnight = midnight.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return 'Reset in ${hours}h:${minutes}m:${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_timeUntilMidnight),
      style: textTheme.bodySmall?.copyWith(
        color: widget.textColor,
        fontSize: widget.isSmall ? 11 : null,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Animated fade-in widget for section transitions
class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedFadeIn({required this.child, required this.delay});

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn> with SingleTickerProviderStateMixin {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() {
          _opacity = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _opacity == 1 ? Offset.zero : const Offset(0, 0.1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}