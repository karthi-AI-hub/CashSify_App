import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';

class TransactionCard extends StatelessWidget {
  final TransactionState tx;
  const TransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amount = tx.amount;
    final type = tx.type;
    final note = tx.note;
    final createdAt = tx.createdAt;
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
      case 'withdrawal':
        icon = Icons.payments;
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
                  tx.type == 'withdrawal'
                      ? 'Withdrawal'
                      : note ?? 'N/A',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount > 0 ? '+' : ''} $amount Coins',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: amount > 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 