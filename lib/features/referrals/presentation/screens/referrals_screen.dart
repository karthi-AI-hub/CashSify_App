import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/widgets/form/custom_button.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import 'referral_history_screen.dart';
import '../../../../core/providers/loading_provider.dart';
import '../../../../core/widgets/layout/loading_overlay.dart';
import '../providers/referral_providers.dart';
import '../../../../core/config/app_config.dart';

class ReferralsScreen extends HookConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadingState = ref.watch(loadingProvider);
    
    final referralStats = ref.watch(referralStatsProvider);
    final referralCode = ref.watch(referralCodeProvider);
    final referralHistory = ref.watch(referralHistoryProvider);
    
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setReferralsScreen();
      });
      controller.forward();
      return null;
    }, []);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading,
      message: loadingState == LoadingState.loading ? 'Loading referrals...' : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final padding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;
          final horizontalPadding = isSmallScreen ? AppSpacing.sm : AppSpacing.lg;

          return RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () async {
              ref.refresh(referralStatsProvider);
              ref.refresh(referralCodeProvider);
              ref.refresh(referralHistoryProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: padding),
                  _AnimatedFadeIn(
                    delay: 0,
                    child: _buildReferralCodeSection(context, ref, isSmallScreen, horizontalPadding),
                  ),
                  SizedBox(height: padding),
                  _AnimatedFadeIn(
                    delay: 100,
                    child: _buildHowItWorksSection(context, isSmallScreen),
                  ),
                  SizedBox(height: padding),
                  _AnimatedFadeIn(
                    delay: 200,
                    child: _buildStatsSection(context, ref, isSmallScreen),
                  ),
                  SizedBox(height: padding),
                  _AnimatedFadeIn(
                    delay: 300,
                    child: _buildTipsSection(context, isSmallScreen),
                  ),
                  SizedBox(height: padding),
                  _AnimatedFadeIn(
                    delay: 400,
                    child: _buildBottomCTAs(context, ref, isSmallScreen),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferralCodeSection(
    BuildContext context,
    WidgetRef ref,
    bool isSmallScreen,
    double horizontalPadding,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final referralCode = ref.watch(referralCodeProvider);

    return CustomCard(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: colorScheme.primary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Your CashSify Code',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.copy,
                      tooltip: 'Copy code',
                      onPressed: () async {
                        final code = ref.read(referralCodeProvider).maybeWhen(
                          data: (c) => c,
                          orElse: () => null,
                        );
                        if (code != null && code.isNotEmpty && code != 'No code available') {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: colorScheme.surface),
                                    SizedBox(width: AppSpacing.sm),
                                    Text('Code copied to clipboard!'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    SizedBox(width: AppSpacing.sm),
                    _buildActionButton(
                      context,
                      icon: Icons.share,
                      tooltip: 'Share code',
                      onPressed: () => _shareReferral(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: referralCode.when(
                  loading: () => CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  error: (_, __) => Text(
                    'Error loading code',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  data: (code) => Text(
                    code ?? 'No code available',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Share your code with friends and earn when they join',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            CustomButton(
              onPressed: () => _shareReferral(context, ref),
              text: 'Invite Friends',
              isFullWidth: true,
              icon: Icon(Icons.share, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomCard(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'How It Works',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: isSmallScreen ? 1 : 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: isSmallScreen ? 3.5 : 1,
              children: [
                _buildRewardStep(
                  context,
                  icon: Icons.person_add,
                  title: 'Sign Up',
                  description: 'Friend signs up using your code',
                  reward: '500 coins',
                  isSmallScreen: isSmallScreen,
                ),
                _buildRewardStep(
                  context,
                  icon: Icons.play_arrow,
                  title: 'First Task',
                  description: 'Friend completes first activity',
                  reward: '500 coins',
                  isSmallScreen: isSmallScreen,
                ),
                _buildRewardStep(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'First Cashout',
                  description: 'Friend makes first withdrawal',
                  reward: '1000 coins',
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String reward,
    bool isSmallScreen = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.all(isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 2 : AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: isSmallScreen ? 18 : 22,
            ),
          ),
          SizedBox(width: isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: isSmallScreen ? 2 : AppSpacing.xs),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                SizedBox(height: isSmallScreen ? 2 : AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 4 : AppSpacing.xs,
                    vertical: isSmallScreen ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    WidgetRef ref,
    bool isSmallScreen,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(referralStatsProvider);

    return CustomCard(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: stats.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
          error: (err, stack) => Text(
            'Error loading stats',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.error,
            ),
          ),
          data: (data) {
            final statItems = [
              _buildStatItem(
                context,
                label: 'Total Referrals',
                value: '${data?['total_referrals'] ?? 0}',
                icon: Icons.people_alt_outlined,
              ),
              _buildStatItem(
                context,
                label: 'Total Earned',
                value: '${data?['total_earned'] ?? 0}',
                icon: Icons.stars_rounded,
                isCoins: true,
              ),
            ];
            return Column(
              children: [
                isSmallScreen
                    ? Column(
                        children: [
                          ...statItems,
                          SizedBox(height: AppSpacing.md),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: statItems,
                      ),
                SizedBox(height: AppSpacing.lg),
                CustomButton(
                  onPressed: () => context.push('/referral-history'),
                  text: 'View History',
                  isFullWidth: true,
                  backgroundColor: colorScheme.surfaceVariant,
                  textColor: colorScheme.onSurfaceVariant,
                  icon: Icon(
                    Icons.history,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isCoins = false,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    int? intValue = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                intValue != null
                    ? TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: intValue),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, val, child) => Text(
                          isCoins ? '$val coins' : '$val',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      )
                    : Text(
                        isCoins ? '$value coins' : value,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomCard(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'Tips & Rules',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            _buildTipItem(
              context,
              icon: Icons.check_circle,
              text: 'Rewards are credited instantly',
            ),
            _buildTipItem(
              context,
              icon: Icons.link,
              text: 'Code must be used during signup',
            ),
            _buildTipItem(
              context,
              icon: Icons.warning,
              text: 'Fraudulent activity will be banned',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTAs(BuildContext context, WidgetRef ref, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CustomButton(
          onPressed: () => _shareReferral(context, ref),
          text: 'Invite Friends',
          isFullWidth: true,
          icon: Icon(Icons.share, color: colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: colorScheme.primary,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _shareReferral(BuildContext context, WidgetRef ref) async {
    final code = ref.read(referralCodeProvider).maybeWhen(
      data: (c) => c,
      orElse: () => null,
    );
    
    if (code == null || code.isEmpty || code == 'No code available') {
      final playStoreBase = AppConfig.playStoreUrl;
      final message = "🎉 Join me on CashSify and start earning rewards for watching ads, referring friends, and more! Download now: $playStoreBase and let's both win! 🚀";
      await Share.share(message);
      return;
    }

    final universalInviteLink = "${AppConfig.playStoreUrl}&referrer=utm_source%3Dinvite%26utm_medium%3Dreferral%26utm_content%3D$code";
    
    final message = """🎉 Join me on CashSify and start earning rewards!

💰 Use my referral code: $code

🚀 Click this magic link to join:
$universalInviteLink

✨ This link will:
• Open CashSify app if you have it installed
• Take you to Play Store to download if you don't
• Auto-fill my referral code for you!

Let's both Earn! 🚀""";

    await Share.share(message);
  }
}

class _AnimatedFadeIn extends StatelessWidget {
  final Widget child;
  final int delay;
  
  const _AnimatedFadeIn({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}