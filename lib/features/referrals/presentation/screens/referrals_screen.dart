import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/widgets/form/custom_button.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/providers/navigation_provider.dart';
import 'referral_history_screen.dart';
import '../../../../core/providers/loading_provider.dart';
import '../../../../core/widgets/layout/loading_overlay.dart';

class ReferralsScreen extends HookConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadingState = ref.watch(loadingProvider);
    
    // Set up the animation controller
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    
    // Create the animation
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    // Mock data for referred users
    final referredUsers = [
      {
        'name': 'John Doe',
        'date': '2024-03-15',
        'status': [true, true, false],
        'coins': 1000,
      },
      {
        'name': 'Jane Smith',
        'date': '2024-03-14',
        'status': [true, true, true],
        'coins': 1500,
      },
    ];

    // Set the screen title and start animation
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

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: FadeTransition(
              opacity: animation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferralCodeSection(context, isSmallScreen, horizontalPadding),
                  SizedBox(height: padding),
                  _buildHowItWorksSection(context, isSmallScreen),
                  SizedBox(height: padding),
                  _buildTipsSection(context, isSmallScreen),
                  SizedBox(height: padding),
                  _buildStatsSection(context, isSmallScreen),
                  SizedBox(height: padding),
                  _buildBottomCTAs(context, isSmallScreen),
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
    bool isSmallScreen,
    double horizontalPadding,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomCard(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.15),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
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
                          borderRadius: BorderRadius.circular(12),
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
                          'Your Referral Code',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.copy,
                      onPressed: () async {
                        await Clipboard.setData(const ClipboardData(text: 'CASH123'));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: colorScheme.surface),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Text('Referral code copied!'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: colorScheme.primary,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildActionButton(
                      context,
                      icon: Icons.share,
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CASH123',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: isSmallScreen ? 24 : 32,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Share this code with friends to earn bonus rewards',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            CustomButton(
              onPressed: () {
                // TODO: Implement invite friends
              },
              text: '🎁 Invite Friends Now',
              isFullWidth: true,
              icon: Icon(Icons.person_add, color: colorScheme.onPrimary),
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedFadeIn(
              delay: 0,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.primary.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: colorScheme.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'How It Works',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _buildPhaseCard(
                    context,
                    icon: Icons.person_add_outlined,
                    title: 'Signup',
                    description: 'Friend signs up using your code',
                    reward: 500,
                    isSmallScreen: isSmallScreen,
                    delay: 100,
                  ),
                  _buildPhaseCard(
                    context,
                    icon: Icons.play_circle_outline,
                    title: 'First Ad Watch',
                    description: 'Friend watches their first ad',
                    reward: 500,
                    isSmallScreen: isSmallScreen,
                    delay: 200,
                  ),
                  _buildPhaseCard(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'First Withdrawal',
                    description: 'Friend makes a withdrawal',
                    reward: 500,
                    isSmallScreen: isSmallScreen,
                    delay: 300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int reward,
    bool isSmallScreen = false,
    required int delay,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _AnimatedFadeIn(
      delay: delay,
      child: Container(
        height: isSmallScreen ? null : 280,
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primary.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: isSmallScreen ? 24 : 32,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 16 : 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$reward coins',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomCard(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? AppSpacing.xs : AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'Referral Rules',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: isSmallScreen ? 18 : 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            _buildRuleItem(
              context,
              icon: Icons.check_circle_outline,
              text: 'One-time rewards per friend',
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: AppSpacing.md),
            _buildRuleItem(
              context,
              icon: Icons.shield_outlined,
              text: 'Coins credited automatically via system',
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: AppSpacing.md),
            _buildRuleItem(
              context,
              icon: Icons.link,
              text: 'Code must be entered during signup only',
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: AppSpacing.md),
            _buildRuleItem(
              context,
              icon: Icons.warning_amber_outlined,
              text: 'Fraud attempts lead to ban',
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool isSmallScreen = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: isSmallScreen ? 20 : 24,
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomCard(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Friends',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '2',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 24 : 32,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Earned',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '3000 coins',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 24 : 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            CustomButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReferralHistoryScreen(),
                  ),
                );
              },
              text: '📄 View Referral History',
              isFullWidth: true,
              backgroundColor: colorScheme.surfaceVariant,
              textColor: colorScheme.onSurfaceVariant,
              icon: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTAs(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CustomButton(
          onPressed: () {
            // TODO: Implement invite more friends
          },
          text: '📤 Invite More Friends',
          isFullWidth: true,
          icon: Icon(Icons.person_add, color: colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
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