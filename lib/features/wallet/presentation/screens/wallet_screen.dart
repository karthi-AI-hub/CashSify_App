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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            // Header
            Text(
              'My Wallet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Track your rewards and redemptions',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            // Coin Balance Card
            userAsync.when(
              data: (user) => _BalanceCard(balance: user?.coins ?? 0),
              loading: () => const _ShimmerCard(),
              error: (e, st) => Center(child: Text('Error loading balance')),
            ),
            const SizedBox(height: 18),
            // Withdraw Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: userAsync.when(
                  data: (user) {
                    final currentBalance = user?.coins ?? 0;
                    final profileComplete = user?.isProfileCompleted ?? false;
                    final emailVerified = user?.isEmailVerified ?? false;
                    final referralCount = user?.referralCount ?? 0;
                    final allMet = currentBalance >= 15000 &&
                        profileComplete &&
                        emailVerified &&
                        referralCount >= 5;

                    return allMet
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WithdrawScreen()),
                            );
                          }
                        : () {
                            CustomToast.show(
                              context,
                              message: 'Please complete all requirements to withdraw.',
                              type: ToastType.warning,
                              duration: const Duration(seconds: 3),
                            );
                          };
                  },
                  loading: () => null, // Disable button while loading user data
                  error: (e, st) => null, // Disable button on error
                ),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  elevation: 2,
                  shadowColor: colorScheme.primary.withOpacity(0.15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Withdrawal Requirements
            userAsync.when(
              data: (user) {
                final currentBalance = user?.coins ?? 0;
                final profileComplete = user?.isProfileCompleted ?? false;
                final emailVerified = user?.isEmailVerified ?? false;
                final referralCount = user?.referralCount ?? 0;

                final requirements = [
                  ('Minimum 15,000 coins', currentBalance >= 15000),
                  ('Profile 100% complete', profileComplete),
                  ('Email verified', emailVerified),
                  ('At least 5 referrals', referralCount >= 5),
                ];
                final metCount = requirements.where((r) => r.$2).length;

                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceVariant.withOpacity(0.7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Withdrawal Requirements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$metCount/${requirements.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: metCount == requirements.length
                                    ? Colors.green
                                    : colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...requirements.map((r) => _RequirementRow(r.$1, r.$2)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: metCount / requirements.length,
                          backgroundColor: colorScheme.surface,
                          color: metCount == requirements.length
                              ? Colors.green
                              : colorScheme.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            // Transaction History
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Transactions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            transactionsAsync.when(
              loading: () => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => const _ShimmerCard(),
              ),
              error: (e, st) => Center(child: Text('Error loading transactions')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(Icons.hourglass_empty_rounded, color: colorScheme.primary, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No Transactions Yet',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final tx = transactions[i];
                    return TransactionCard(tx: tx);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isNotEmpty) {
                  return CustomButton(
                    onPressed: () {
                      context.go('/transaction-history');
                    },
                    text: 'View Full Transaction History',
                    isFullWidth: true,
                    backgroundColor: colorScheme.surfaceVariant,
                    textColor: colorScheme.onSurfaceVariant,
                    icon: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
                  );
                }
                return const SizedBox.shrink(); // Hide button if no transactions
              },
              loading: () => const SizedBox.shrink(), // Hide button while loading
              error: (e, st) => const SizedBox.shrink(), // Hide button on error
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated coin icon or shimmer
          Icon(Icons.monetization_on_rounded, color: colorScheme.primary, size: 48),
          const SizedBox(height: 12),
          Text(
            '$balance Coins',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;
  const _RequirementRow(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: met ? Colors.green : colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: met ? Colors.green : colorScheme.error,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              color: colorScheme.onSurface.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 16,
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}