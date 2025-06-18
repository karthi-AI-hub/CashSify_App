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
    
    // Get real data from provider
    final referredUsers = ref.watch(referralHistoryProvider).value ?? [];

    // Set the screen title
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).setReferralHistoryScreen();
      });
      return null;
    }, []);

    return LoadingOverlay(
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
                _buildReferralList(context, ref, referredUsers, isSmallScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onSurface,
        ),
      ),
      title: Text(
        'Referral History',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildReferralList(
    BuildContext context,
    WidgetRef ref,
    List<ReferralHistory> referredUsers,
    bool isSmallScreen,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (referredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No referrals yet',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: referredUsers.length,
      itemBuilder: (context, index) {
        final user = referredUsers[index];
        return _buildReferralCard(context, user, isSmallScreen);
      },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
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
                    user.name[0],
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

            // Progress Tracker
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