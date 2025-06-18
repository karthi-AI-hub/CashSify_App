import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/providers/loading_provider.dart';
import '../../../../core/widgets/layout/loading_overlay.dart';
import '../providers/referral_providers.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../models/referral_history.dart';

class ReferralHistoryScreen extends HookConsumerWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadingState = ref.watch(loadingProvider);
    final referredUsers = ref.watch(referralHistoryProvider).value ?? [];

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setReferralHistoryScreen();
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: LoadingOverlay(
        isLoading: loadingState == LoadingState.loading,
        message: loadingState == LoadingState.loading ? 'Loading referral history...' : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            final padding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isSmallScreen),
                  SizedBox(height: padding),
                  referredUsers.isEmpty
                      ? _buildEmptyState(context, isSmallScreen)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: referredUsers.length,
                          itemBuilder: (context, index) {
                            final user = referredUsers[index];
                            return _AnimatedFadeIn(
                              delay: 100 * index,
                              child: _buildReferralCard(context, user, isSmallScreen),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.zero,
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
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
          vertical: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.primary,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Referral History',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: AppSpacing.md * 2), // For symmetry
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? AppSpacing.lg : AppSpacing.xl),
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
              Icons.people_outline,
              size: isSmallScreen ? 48 : 64,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No referrals yet',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Share your referral code to start earning rewards!',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(
    BuildContext context,
    ReferralHistory user,
    bool isSmallScreen,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.only(bottom: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                      ),
                      Text(
                        'Joined ${_formatDate(user.date)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    '+${user.coins}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPhaseIndicator(
                  context,
                  title: 'Signup',
                  isCompleted: user.status[0],
                  isSmallScreen: isSmallScreen,
                ),
                _buildPhaseConnector(context, user.status[0], user.status[1]),
                _buildPhaseIndicator(
                  context,
                  title: 'Ad Watch',
                  isCompleted: user.status[1],
                  isSmallScreen: isSmallScreen,
                ),
                _buildPhaseConnector(context, user.status[1], user.status[2]),
                _buildPhaseIndicator(
                  context,
                  title: 'Withdraw',
                  isCompleted: user.status[2],
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(
    BuildContext context, {
    required String title,
    required bool isCompleted,
    bool isSmallScreen = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCompleted
                  ? [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.2),
                    ]
                  : [
                      colorScheme.surfaceVariant,
                      colorScheme.surfaceVariant.withOpacity(0.8),
                    ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: textTheme.bodySmall?.copyWith(
            color: isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseConnector(BuildContext context, bool isCurrentCompleted, bool isNextCompleted) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isCurrentCompleted
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.surfaceVariant,
            isNextCompleted
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.surfaceVariant,
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedFadeIn({required this.child, required this.delay});

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
} 