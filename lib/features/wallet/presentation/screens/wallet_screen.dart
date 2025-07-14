import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'withdraw_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/features/wallet/presentation/widgets/transaction_card.dart';
import 'package:cashsify_app/features/wallet/presentation/providers/withdrawal_provider.dart';
import 'package:cashsify_app/theme/app_colors.dart';

class WalletScreen extends HookConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 400;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userProvider.notifier).refreshUser();
          ref.refresh(transactionsStreamProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Enhanced Coin Balance Card
              userAsync.when(
                data: (user) => _EnhancedBalanceCard(balance: user?.coins ?? 0),
                loading: () => const _EnhancedShimmerCard(),
                error: (e, st) => _buildErrorState(context, colorScheme, e.toString()),
              ),
              
              const SizedBox(height: 24),
              
              // Enhanced Withdraw Button
              _buildEnhancedWithdrawButton(context, ref, userAsync, colorScheme),
              
              const SizedBox(height: 20),
              
              // Enhanced Withdrawal Requirements
              _buildEnhancedRequirements(context, ref, userAsync, colorScheme),
              
              const SizedBox(height: 32),
              
              // Enhanced Transaction History Section
              _buildEnhancedTransactionSection(context, colorScheme, transactionsAsync),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedWithdrawButton(BuildContext context, WidgetRef ref, AsyncValue userAsync, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: userAsync.when(
          data: (user) {
            final currentBalance = user?.coins ?? 0;
            final profileComplete = user?.isProfileCompleted ?? false;
            final emailVerified = user?.isEmailVerified ?? false;
            final referralCount = user?.referralCount ?? 0;
            
            // Check if user has any withdrawal history
            final withdrawalsAsync = ref.watch(withdrawalsStreamProvider);
            final withdrawalsFutureAsync = ref.watch(withdrawalsFutureProvider);
            
            final hasWithdrawalHistory = withdrawalsAsync.when(
              data: (withdrawals) => withdrawals.isNotEmpty,
              loading: () => false,
              error: (_, __) => false,
            );
            
            final hasWithdrawalHistoryFuture = withdrawalsFutureAsync.when(
              data: (withdrawals) => withdrawals.isNotEmpty,
              loading: () => false,
              error: (_, __) => false,
            );
            
            // Use either stream or future data
            final hasHistory = hasWithdrawalHistory || hasWithdrawalHistoryFuture;
            
            // If user has withdrawal history, allow access to withdraw screen
            // If no history, check all requirements
            if (hasHistory) {
              return () {
                context.push('/withdraw');
              };
            } else {
              // First time withdrawal - check all requirements
              final allMet = currentBalance >= 15000 &&
                  profileComplete &&
                  emailVerified &&
                  referralCount >= 5;

              return allMet
                  ? () {
                      context.push('/withdraw');
                    }
                  : () {
                      context.push('/withdraw-requirements');
                    };
            }
          },
          loading: () => null, // Disable button while loading user data
          error: (e, st) => null, // Disable button on error
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, size: 20),
        ),
        label: userAsync.when(
          data: (user) {
            final withdrawalsAsync = ref.watch(withdrawalsStreamProvider);
            final withdrawalsFutureAsync = ref.watch(withdrawalsFutureProvider);
            
            final hasWithdrawalHistory = withdrawalsAsync.when(
              data: (withdrawals) => withdrawals.isNotEmpty,
              loading: () => false,
              error: (_, __) => false,
            );
            
            final hasWithdrawalHistoryFuture = withdrawalsFutureAsync.when(
              data: (withdrawals) => withdrawals.isNotEmpty,
              loading: () => false,
              error: (_, __) => false,
            );
            
            // Use either stream or future data
            final hasHistory = hasWithdrawalHistory || hasWithdrawalHistoryFuture;
            
            return Text(
              hasHistory ? 'View Withdrawals' : 'Redeem Coins',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            );
          },
          loading: () => const Text('Redeem Coins'),
          error: (e, st) => const Text('Redeem Coins'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEnhancedRequirements(BuildContext context, WidgetRef ref, AsyncValue userAsync, ColorScheme colorScheme) {
    return userAsync.when(
      data: (user) {
        final currentBalance = user?.coins ?? 0;
        final profileComplete = user?.isProfileCompleted ?? false;
        final emailVerified = user?.isEmailVerified ?? false;
        final referralCount = user?.referralCount ?? 0;

        // Check if user has any withdrawal history
        final withdrawalsAsync = ref.watch(withdrawalsStreamProvider);
        final withdrawalsFutureAsync = ref.watch(withdrawalsFutureProvider);
        
        final hasWithdrawalHistory = withdrawalsAsync.when(
          data: (withdrawals) => withdrawals.isNotEmpty,
          loading: () => false,
          error: (_, __) => false,
        );
        
        final hasWithdrawalHistoryFuture = withdrawalsFutureAsync.when(
          data: (withdrawals) => withdrawals.isNotEmpty,
          loading: () => false,
          error: (_, __) => false,
        );
        
        // Use either stream or future data
        final hasHistory = hasWithdrawalHistory || hasWithdrawalHistoryFuture;

        final requirements = [
          ('Minimum 15,000 coins', currentBalance >= 15000, Icons.monetization_on_rounded),
          ('Profile 100% complete', profileComplete, Icons.person_rounded),
          ('Email verified', emailVerified, Icons.email_rounded),
          ('At least 5 referrals', referralCount >= 5, Icons.people_rounded),
        ];
        final metCount = requirements.where((r) => r.$2).length;
        final allRequirementsMet = metCount == requirements.length;

        // Hide requirements section if all requirements are met OR user has withdrawal history
        if (allRequirementsMet || hasHistory) {
          // Show a helpful message if user has withdrawal history but doesn't meet current requirements
          if (hasHistory && !allRequirementsMet) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdrawal Access Granted',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can access withdrawal history even with insufficient requirements.',
                          style: TextStyle(
                            color: colorScheme.primary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.checklist_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Redeem Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: metCount == requirements.length
                            ? Colors.green.withOpacity(0.1)
                            : colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: metCount == requirements.length
                              ? Colors.green.withOpacity(0.3)
                              : colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$metCount/${requirements.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: metCount == requirements.length
                              ? Colors.green
                              : colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...requirements.map((r) => _EnhancedRequirementRow(r.$1, r.$2, r.$3)),
                const SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: metCount / requirements.length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: metCount == requirements.length
                            ? Colors.green
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildEnhancedTransactionSection(BuildContext context, ColorScheme colorScheme, AsyncValue transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.history_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        transactionsAsync.when(
          loading: () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) => const _EnhancedShimmerCard(),
          ),
          error: (e, st) => _buildErrorState(context, colorScheme, e.toString()),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        color: colorScheme.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Transactions Yet',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your transaction history will appear here once you start earning coins.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            // Only show the last 5 transactions
            final recentTransactions = transactions.take(5).toList();
            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final tx = recentTransactions[i];
                    return _EnhancedTransactionCard(tx: tx);
                  },
                ),
                const SizedBox(height: 16),
                if (transactions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/transaction-history');
                      },
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('View Full Transaction History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme, String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: colorScheme.error.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EnhancedBalanceCard extends StatelessWidget {
  final int balance;
  const _EnhancedBalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$balance Coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Earn more coins to unlock withdrawals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedRequirementRow extends StatelessWidget {
  final String label;
  final bool met;
  final IconData icon;
  const _EnhancedRequirementRow(this.label, this.met, this.icon);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: met 
                  ? Colors.green.withOpacity(0.1)
                  : colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: met ? Colors.green : colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: met ? Colors.green : colorScheme.error,
                fontWeight: met ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: met ? Colors.green : colorScheme.error,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _EnhancedShimmerCard extends StatelessWidget {
  const _EnhancedShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 80,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedTransactionCard extends StatelessWidget {
  final TransactionState tx;
  const _EnhancedTransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final type = tx.type;
    final amount = tx.amount;
    final createdAt = tx.createdAt;
    
    IconData icon;
    Color iconColor;
    String title;
    
    switch (type) {
      case 'ad':
        icon = Icons.play_circle_rounded;
        iconColor = Colors.blue;
        title = 'Ad Watch';
        break;
      case 'withdrawal':
        icon = Icons.arrow_circle_up_rounded;
        iconColor = Colors.red;
        title = 'Withdrawn';
        break;
      case 'referral':
        icon = Icons.people_rounded;
        iconColor = colorScheme.primary;
        title = 'Referral Bonus';
        break;
      default:
        icon = Icons.account_balance_wallet_rounded;
        iconColor = colorScheme.primary;
        title = 'Transaction';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.note ?? title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (type == 'withdrawal' ? Colors.red : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (type == 'withdrawal' ? Colors.red : Colors.green).withOpacity(0.3),
              ),
            ),
            child: Text(
              type == 'withdrawal'
                ? '$amount'
                : '+$amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: type == 'withdrawal' ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}