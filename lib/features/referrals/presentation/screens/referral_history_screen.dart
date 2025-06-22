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
import '../../../../core/widgets/layout/custom_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';

class ReferralHistoryScreen extends HookConsumerWidget {
  const ReferralHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadingState = ref.watch(loadingProvider);
    final referredUsers = ref.watch(referralHistoryProvider).value ?? [];
    final isRefreshing = useState(false);
    final scrollController = useScrollController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setReferralHistoryScreen();
      });
      return null;
    }, []);

    return WillPopScope(
      onWillPop: () async {
        context.go('/referrals');
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: CustomAppBar(
          title: 'Referral History',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.go('/referrals'),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                isRefreshing.value = true;
                await ref.refresh(referralHistoryProvider.future);
                isRefreshing.value = false;
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: loadingState == LoadingState.loading,
          message: loadingState == LoadingState.loading ? 'Loading history...' : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final padding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;

              return RefreshIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                onRefresh: () async {
                  isRefreshing.value = true;
                  try {
                    await ref.refresh(referralHistoryProvider.future);
                    await ref.refresh(referralStatsProvider.future);
                    await ref.read(userProvider.notifier).refreshUser();
                    
                    if (context.mounted) {
                      final updatedUsers = ref.read(referralHistoryProvider).value ?? [];
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Refreshed! ${updatedUsers.length} referral${updatedUsers.length == 1 ? '' : 's'} found',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    }
                  } finally {
                    isRefreshing.value = false;
                  }
                },
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(padding),
                      sliver: referredUsers.isEmpty
                          ? SliverFillRemaining(
                              child: _buildEmptyState(context, isSmallScreen),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final user = referredUsers[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: isSmallScreen ? AppSpacing.md : AppSpacing.lg),
                                    child: _ReferralCard(
                                      user: user,
                                      isSmallScreen: isSmallScreen,
                                      onTap: () => _showReferralDetails(context, user, isSmallScreen),
                                    ),
                                  );
                                },
                                childCount: referredUsers.length,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isSmallScreen ? 120 : 150,
          height: isSmallScreen ? 120 : 150,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.2),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.people_alt_outlined,
            size: isSmallScreen ? 48 : 60,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'No Referrals Yet',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),
          child: Text(
            'Share your referral code with friends and start earning rewards when they join!',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => context.go('/referrals'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Invite Friends',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showReferralDetails(BuildContext context, ReferralHistory user, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _ProfileAvatar(user: user, size: isSmallScreen ? 48 : 56),
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
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: colorScheme.primary),
                        onPressed: () => _remindReferral(context, user),
                        tooltip: 'Remind',
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _ProgressSection(user: user, isSmallScreen: isSmallScreen),
                  SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _RewardDetailItem(
                          icon: Icons.people,
                          title: 'Referred On',
                          value: _formatDate(user.date),
                          isSmallScreen: isSmallScreen,
                        ),
                        _RewardDetailItem(
                          icon: Icons.monetization_on,
                          title: 'Total Earned',
                          value: '${user.coins} coins',
                          isSmallScreen: isSmallScreen,
                          isHighlighted: true,
                        ),
                        if (user.status[0])
                          _RewardDetailItem(
                            icon: Icons.check_circle,
                            title: 'Signup Bonus',
                            value: '+500 coins',
                            isSmallScreen: isSmallScreen,
                          ),
                        if (user.status[1])
                          _RewardDetailItem(
                            icon: Icons.check_circle,
                            title: 'First Task',
                            value: '+500 coins',
                            isSmallScreen: isSmallScreen,
                          ),
                        if (user.status[2])
                          _RewardDetailItem(
                            icon: Icons.check_circle,
                            title: 'First Withdrawal',
                            value: '+1000 coins',
                            isSmallScreen: isSmallScreen,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _remindReferral(BuildContext context, ReferralHistory user) async {
    final nextPhase = getNextPendingPhase(user.status);
    final message = nextPhase.isNotEmpty
        ? "Hey ${user.name}, don't forget to complete the next step: $nextPhase in CashSify and unlock more rewards!"
        : "Hey ${user.name}, you've completed all referral steps in CashSify!";
    await Share.share(message);
  }

  String getNextPendingPhase(List<bool> status) {
    final phases = ['Signup', 'Ad Watch', 'Withdraw'];
    for (int i = 0; i < status.length; i++) {
      if (!status[i]) return phases[i];
    }
    return '';
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

class _ReferralCard extends StatelessWidget {
  final ReferralHistory user;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _ReferralCard({
    required this.user,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
          child: Row(
            children: [
              _ProfileAvatar(user: user, size: isSmallScreen ? 44 : 52),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Joined ${_formatDate(user.date)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${user.coins}',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.day} ${_getMonthName(dateTime.month)}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _ProfileAvatar extends StatelessWidget {
  final ReferralHistory user;
  final double size;

  const _ProfileAvatar({
    required this.user,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (user.profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.profileImageUrl),
        backgroundColor: Colors.transparent,
      );
    } else {
      final initials = user.name.isNotEmpty
          ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
          : '?';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        ),
      );
    }
  }
}

class _ProgressSection extends StatelessWidget {
  final ReferralHistory user;
  final bool isSmallScreen;

  const _ProgressSection({
    required this.user,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completedCount = user.status.where((s) => s).length;
    final totalCount = user.status.length;
    final progress = completedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Referral Progress',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$completedCount/$totalCount completed',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: progress,
          minHeight: isSmallScreen ? 8 : 10,
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ProgressChip(
              label: 'Signup',
              isCompleted: user.status[0],
              isSmallScreen: isSmallScreen,
            ),
            _ProgressChip(
              label: 'First Task',
              isCompleted: user.status[1],
              isSmallScreen: isSmallScreen,
            ),
            _ProgressChip(
              label: 'Withdrawal',
              isCompleted: user.status[2],
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isSmallScreen;

  const _ProgressChip({
    required this.label,
    required this.isCompleted,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isCompleted ? colorScheme.primary : colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: isSmallScreen ? 16 : 18,
            color: isCompleted ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isCompleted ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardDetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isSmallScreen;
  final bool isHighlighted;

  const _RewardDetailItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.isSmallScreen,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? colorScheme.primary.withOpacity(0.1)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}