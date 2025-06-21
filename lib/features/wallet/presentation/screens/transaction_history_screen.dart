import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:cashsify_app/features/wallet/presentation/widgets/transaction_card.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/services/transaction_service.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';

class TransactionHistoryScreen extends HookConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactionService = ref.watch(transactionServiceProvider);
    final userId = transactionService.supabase.client.auth.currentUser?.id;

    // State for filters
    final selectedTypes = useState<List<String>>([]);
    final selectedDateRange = useState<String>('All time');
    final customStartDate = useState<DateTime?>(null);
    final customEndDate = useState<DateTime?>(null);

    // Calculate effective start and end dates based on selectedDateRange
    final DateTime? effectiveStartDate;
    final DateTime? effectiveEndDate;

    switch (selectedDateRange.value) {
      case 'This month':
        effectiveStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        effectiveEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
        break;
      case 'Last month':
        effectiveStartDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        effectiveEndDate = DateTime(DateTime.now().year, DateTime.now().month, 0, 23, 59, 59);
        break;
      case 'Last 3 months':
        effectiveStartDate = DateTime(DateTime.now().year, DateTime.now().month - 3, 1);
        effectiveEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
        break;
      case 'Last 6 months':
        effectiveStartDate = DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
        effectiveEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
        break;
      case 'This year':
        effectiveStartDate = DateTime(DateTime.now().year, 1, 1);
        effectiveEndDate = DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
        break;
      case 'Last year':
        effectiveStartDate = DateTime(DateTime.now().year - 1, 1, 1);
        effectiveEndDate = DateTime(DateTime.now().year - 1, 12, 31, 23, 59, 59);
        break;
      case 'Custom Date':
        effectiveStartDate = customStartDate.value;
        effectiveEndDate = customEndDate.value?.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        break;
      case 'All time':
      default:
        effectiveStartDate = null;
        effectiveEndDate = null;
        break;
    }

    if (userId == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Transaction History',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: Center(
          child: Text(
            'User not logged in.',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      );
    }

    final allTransactionsAsync = ref.watch(filteredTransactionsStreamProvider((
      userId: userId,
      types: selectedTypes.value.isEmpty ? null : selectedTypes.value,
      startDate: effectiveStartDate,
      endDate: effectiveEndDate,
    )));

    final List<String> transactionTypes = ['all', 'ad', 'withdrawal', 'referral'];
    final List<String> dateRangeOptions = [
      'All time',
      'This month',
      'Last month',
      'Last 3 months',
      'Last 6 months',
      'This year',
      'Last year',
      'Custom Date',
    ];

    Future<void> _pickDate(bool isStart) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: isStart ? customStartDate.value ?? DateTime.now() : customEndDate.value ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        if (isStart) {
          customStartDate.value = picked;
        } else {
          customEndDate.value = picked;
        }
      }
    }

    return WillPopScope(
      onWillPop: () async {
        context.go('/wallet');
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Transaction History',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/wallet'),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: transactionTypes.map((type) {
                        final isSelected = selectedTypes.value.contains(type) ||
                            (type == 'all' && selectedTypes.value.isEmpty);
                        return FilterChip(
                          label: Text(type.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (type == 'all') {
                              // Reset to show all
                              selectedTypes.value = [];
                            } else {
                              var updated = [...selectedTypes.value];
                              updated.remove('all');
                              if (selected) {
                                updated.add(type);
                              } else {
                                updated.remove(type);
                              }
                              selectedTypes.value = updated;
                            }
                          },
                          selectedColor: colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Filter by Date:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedDateRange.value,
                              onChanged: (String? newValue) {
                                selectedDateRange.value = newValue!;
                                if (newValue != 'Custom Date') {
                                  customStartDate.value = null;
                                  customEndDate.value = null;
                                }
                              },
                              items: dateRangeOptions.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              underline: const SizedBox(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedDateRange.value == 'Custom Date') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _pickDate(true),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                customStartDate.value == null
                                    ? 'Select Start Date'
                                    : 'Start: ${customStartDate.value!.toLocal().toString().split(' ')[0]}',
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: colorScheme.surfaceVariant,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _pickDate(false),
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                customEndDate.value == null
                                    ? 'Select End Date'
                                    : 'End: ${customEndDate.value!.toLocal().toString().split(' ')[0]}',
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: colorScheme.surfaceVariant,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: allTransactionsAsync.when(
                    loading: () => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => const _ShimmerCard(),
                    ),
                    error: (e, st) => Center(child: Text('Error loading transactions: ${e.toString()}')),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty_rounded, color: colorScheme.primary, size: 80),
                            const SizedBox(height: 24),
                            Text(
                              'No Transactions Found',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Adjust your filters or check back later.',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final tx = transactions[i];
                          return TransactionCard(tx: tx);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer card adapted for TransactionHistoryScreen
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