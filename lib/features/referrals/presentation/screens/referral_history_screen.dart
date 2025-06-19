import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: colorScheme.primary.withOpacity(0.08),
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
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: AppSpacing.md * 2), // For symmetry
        ],
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

    return GestureDetector(
      onTap: () => _showReferralDetails(context, user, isSmallScreen),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? AppSpacing.sm : AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
            vertical: isSmallScreen ? AppSpacing.md : AppSpacing.lg,
          ),
          child: Row(
            children: [
              _buildProfileImage(user, isSmallScreen),
              SizedBox(width: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 15 : 18,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Text(
                  '+${user.coins}',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(ReferralHistory user, bool isSmallScreen) {
    if (user.profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: isSmallScreen ? 22 : 28,
        backgroundImage: NetworkImage(user.profileImageUrl),
        backgroundColor: Colors.transparent,
      );
    } else {
      final initials = user.name.isNotEmpty
          ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
          : '?';
      return CircleAvatar(
        radius: isSmallScreen ? 22 : 28,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
      );
    }
  }

  Widget _buildStatusBadges(BuildContext context, List<bool> status, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final phases = ['Signup', 'Ad Watch', 'Withdraw'];
    final completedIcons = [Icons.check_circle, Icons.check_circle, Icons.check_circle];
    final pendingIcons = [Icons.radio_button_unchecked, Icons.radio_button_unchecked, Icons.radio_button_unchecked];
    return Wrap(
      spacing: isSmallScreen ? 4 : 8,
      runSpacing: isSmallScreen ? 2 : 4,
      children: List.generate(3, (i) {
        final isCompleted = status[i];
        return Chip(
          avatar: Icon(
            isCompleted ? completedIcons[i] : pendingIcons[i],
            color: isCompleted ? colorScheme.primary : colorScheme.outline,
            size: isSmallScreen ? 16 : 20,
          ),
          label: Text(
            phases[i],
            style: textTheme.bodySmall?.copyWith(
              color: isCompleted ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 11 : 14,
            ),
          ),
          backgroundColor: isCompleted
              ? colorScheme.primary
              : colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8)),
          side: isCompleted
              ? BorderSide.none
              : BorderSide(color: colorScheme.outline.withOpacity(0.5), width: 1),
        );
      }),
    );
  }

  Widget _buildAnimatedProgressBar(BuildContext context, double progress, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          minHeight: isSmallScreen ? 6 : 10,
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        );
      },
    );
  }

  // Helper to get the next pending phase
  String getNextPendingPhase(List<bool> status) {
    final phases = ['Signup', 'Ad Watch', 'Withdraw'];
    for (int i = 0; i < status.length; i++) {
      if (!status[i]) return phases[i];
    }
    return '';
  }

  void _remindReferral(BuildContext context, ReferralHistory user) async {
    final nextPhase = getNextPendingPhase(user.status);
    final message = nextPhase.isNotEmpty
        ? "Hey ${user.name}, don't forget to complete the next step: $nextPhase in CashSify and unlock more rewards!"
        : "Hey ${user.name}, you've completed all referral steps in CashSify!";
    await Share.share(message);
  }

  void _showReferralDetails(BuildContext context, ReferralHistory user, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProfileImage(user, isSmallScreen),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.email.isNotEmpty)
                          Text(
                            user.email,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          'Joined ${_formatDate(user.date)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Referral Progress',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.notifications_active, color: colorScheme.primary, size: 22),
                    label: Text('Remind ${user.name.split(' ').first}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceVariant,
                      foregroundColor: colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: textTheme.labelLarge,
                    ),
                    onPressed: () => _remindReferral(context, user),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              _buildStatusBadges(context, user.status, isSmallScreen),
              SizedBox(height: AppSpacing.md),
              _buildAnimatedProgressBar(context, user.status.where((s) => s).length / user.status.length, isSmallScreen),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.monetization_on, color: colorScheme.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '+${user.coins} coins earned',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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