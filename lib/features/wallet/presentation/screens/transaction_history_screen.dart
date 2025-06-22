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
import 'package:cashsify_app/theme/app_colors.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/theme/app_text_styles.dart';

class TransactionHistoryScreen extends HookConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: Center(
          child: Text(
            'Please login to view transaction history',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
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
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: colorScheme.primary,
                onPrimary: colorScheme.onPrimary,
                surface: colorScheme.surface,
                onSurface: colorScheme.onSurface,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
            child: child!,
          );
        },
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
        context.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: CustomAppBar(
          title: 'Transaction History',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FILTER TRANSACTIONS',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Type Filter
                    Text(
                      'Transaction Type',
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: transactionTypes.map((type) {
                        final isSelected = selectedTypes.value.contains(type) ||
                            (type == 'all' && selectedTypes.value.isEmpty);
                        return ChoiceChip(
                          label: Text(
                            type.toUpperCase(),
                            style: textTheme.labelLarge?.copyWith(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (type == 'all') {
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
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Date Filter
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Range',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedDateRange.value,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface),
                                  underline: const SizedBox(),
                                  style: textTheme.bodyMedium,
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Custom Date Picker
                    if (selectedDateRange.value == 'Custom Date') ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerButton(
                              label: customStartDate.value == null
                                  ? 'Select Start Date'
                                  : 'From: ${_formatDate(customStartDate.value!)}',
                              onPressed: () => _pickDate(true),
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _DatePickerButton(
                              label: customEndDate.value == null
                                  ? 'Select End Date'
                                  : 'To: ${_formatDate(customEndDate.value!)}',
                              onPressed: () => _pickDate(false),
                              icon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Transaction List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: allTransactionsAsync.when(
                    loading: () => _buildLoadingShimmer(context),
                    error: (e, st) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Failed to load transactions',
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Please try again later',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: () => ref.refresh(filteredTransactionsStreamProvider((
                              userId: userId,
                              types: selectedTypes.value.isEmpty ? null : selectedTypes.value,
                              startDate: effectiveStartDate,
                              endDate: effectiveEndDate,
                            ))),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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

  Widget _buildLoadingShimmer(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => const _ShimmerCard(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No Transactions Found',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Try adjusting your filters or check back later for new transactions.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _DatePickerButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      label: Text(
        label,
        style: textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
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
      height: 72,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
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
              color: colorScheme.onSurface.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}