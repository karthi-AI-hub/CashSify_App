import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'withdraw_screen.dart';

final userBalanceProvider = StateProvider<int>((ref) => 15300);
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    {
      'type': 'ad',
      'note': 'Daily Task Reward',
      'amount': 100,
      'created_at': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'type': 'referral',
      'note': 'Referral Bonus',
      'amount': 500,
      'created_at': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'type': 'withdraw',
      'note': 'Withdrawal',
      'amount': -15000,
      'created_at': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'type': 'ad',
      'note': 'Watched Ad',
      'amount': 50,
      'created_at': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];
});

class WalletScreen extends HookConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = ref.watch(userBalanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
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
              'Track your earnings and spendings',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            // Coin Balance Card
            _BalanceCard(balance: balance),
            const SizedBox(height: 18),
            // Withdraw Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WithdrawScreen()),
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
                ),
              ),
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
                itemBuilder: (context, i) => _ShimmerCard(),
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
                    return _TransactionCard(tx: tx);
                  },
                );
              },
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
          Text(
            '≈ ₹${(balance / 1000).toStringAsFixed(2)}',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amount = tx['amount'] as int;
    final type = tx['type'] as String;
    final note = tx['note'] as String;
    final createdAt = tx['created_at'] as DateTime;
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'ad':
        icon = Icons.play_circle_outline;
        iconColor = Colors.blueAccent;
        break;
      case 'referral':
        icon = Icons.card_giftcard;
        iconColor = Colors.purple;
        break;
      case 'withdraw':
        icon = Icons.account_balance_wallet_outlined;
        iconColor = Colors.redAccent;
        break;
      default:
        icon = Icons.monetization_on_rounded;
        iconColor = colorScheme.primary;
    }
    return Container(
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount > 0 ? '+$amount' : '$amount',
            style: TextStyle(
              color: amount > 0 ? Colors.green : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
} 