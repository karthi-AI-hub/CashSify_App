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
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Transaction History',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: Center(
          child: _buildErrorState(context, colorScheme, 'Please login to view transaction history'),
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

    // --- EXPANDABLE INLINE FILTER PANEL ---
    final filterPanelExpanded = useState(false);
    final tempSelectedTypes = useState<List<String>>(List.from(selectedTypes.value));
    final tempSelectedDateRange = useState<String>(selectedDateRange.value);
    final tempCustomStartDate = useState<DateTime?>(customStartDate.value);
    final tempCustomEndDate = useState<DateTime?>(customEndDate.value);

    Widget filterSummaryChips = Wrap(
      spacing: 8,
      runSpacing: 0,
      children: [
        if (selectedTypes.value.isNotEmpty)
          Chip(
            label: Text(selectedTypes.value.join(', ').toUpperCase()),
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            labelStyle: TextStyle(color: colorScheme.primary, fontSize: 12),
          ),
        if (selectedDateRange.value != 'All time')
          Chip(
            label: Text(selectedDateRange.value),
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            labelStyle: TextStyle(color: colorScheme.primary, fontSize: 12),
          ),
      ],
    );

    Widget filterButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: Icon(filterPanelExpanded.value ? Icons.close : Icons.filter_list_rounded, size: 18),
            label: Text(filterPanelExpanded.value ? 'Close Filter' : 'Filter'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: colorScheme.surfaceVariant,
              foregroundColor: colorScheme.primary,
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onPressed: () {
              if (filterPanelExpanded.value) {
                // Cancel: revert temp values
                tempSelectedTypes.value = List.from(selectedTypes.value);
                tempSelectedDateRange.value = selectedDateRange.value;
                tempCustomStartDate.value = customStartDate.value;
                tempCustomEndDate.value = customEndDate.value;
              }
              filterPanelExpanded.value = !filterPanelExpanded.value;
            },
          ),
          const SizedBox(width: 12),
          Expanded(child: filterSummaryChips),
        ],
      ),
    );

    Widget filterPanel = AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: filterPanelExpanded.value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Builder(
        builder: (context) {
          Future<void> _pickTempDate(bool isStart) async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: isStart ? tempCustomStartDate.value ?? DateTime.now() : tempCustomEndDate.value ?? DateTime.now(),
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
                tempCustomStartDate.value = picked;
              } else {
                tempCustomEndDate.value = picked;
              }
            }
          }
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnhancedFilterSection(
                  context,
                  colorScheme,
                  textTheme,
                  tempSelectedTypes,
                  tempSelectedDateRange,
                  tempCustomStartDate,
                  tempCustomEndDate,
                  transactionTypes,
                  dateRangeOptions,
                  _pickTempDate,
                ),
                if (tempSelectedDateRange.value == 'Custom Date' && (tempCustomStartDate.value == null || tempCustomEndDate.value == null))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      'Please select both start and end dates.',
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Cancel: revert temp values and collapse
                        tempSelectedTypes.value = List.from(selectedTypes.value);
                        tempSelectedDateRange.value = selectedDateRange.value;
                        tempCustomStartDate.value = customStartDate.value;
                        tempCustomEndDate.value = customEndDate.value;
                        filterPanelExpanded.value = false;
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (tempSelectedDateRange.value == 'Custom Date' && (tempCustomStartDate.value == null || tempCustomEndDate.value == null))
                          ? null
                          : () {
                              // Apply: copy temp values to real
                              selectedTypes.value = List.from(tempSelectedTypes.value);
                              selectedDateRange.value = tempSelectedDateRange.value;
                              customStartDate.value = tempCustomStartDate.value;
                              customEndDate.value = tempCustomEndDate.value;
                              filterPanelExpanded.value = false;
                            },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      secondChild: const SizedBox.shrink(),
    );

    // --- COMPACT STATS BAR ---
    Widget compactStatsBar(List transactions) {
      final total = transactions.length;
      final totalEarned = transactions.where((t) => t.type != 'withdrawal').fold<num>(0, (sum, t) => sum + t.amount).toInt();
      final totalSpent = transactions.where((t) => t.type == 'withdrawal').fold<num>(0, (sum, t) => sum + t.amount).toInt();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$total', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text('+$totalEarned', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.trending_down_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 4),
                Text('$totalSpent', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
              filterButton,
              filterPanel,
              allTransactionsAsync.when(
                data: (transactions) => compactStatsBar(transactions),
                loading: () => const SizedBox(height: 8),
                error: (e, st) => const SizedBox(height: 8),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: allTransactionsAsync.when(
                    loading: () => _buildEnhancedLoadingShimmer(context, colorScheme),
                    error: (e, st) => _buildScrollableEmptyState(context, colorScheme, textTheme, isError: true),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return _buildScrollableEmptyState(context, colorScheme, textTheme);
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.refresh(filteredTransactionsStreamProvider((
                            userId: userId,
                            types: selectedTypes.value.isEmpty ? null : selectedTypes.value,
                            startDate: effectiveStartDate,
                            endDate: effectiveEndDate,
                          )));
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: ListView.separated(
                            key: ValueKey('${transactions.length}-${transactions.hashCode}'),
                            padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final tx = transactions[i];
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    child: _EnhancedTransactionCard(tx: tx),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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

  Widget _buildEnhancedFilterSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ValueNotifier<List<String>> selectedTypes,
    ValueNotifier<String> selectedDateRange,
    ValueNotifier<DateTime?> customStartDate,
    ValueNotifier<DateTime?> customEndDate,
    List<String> transactionTypes,
    List<String> dateRangeOptions,
    Future<void> Function(bool) _pickDate,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Type Filter
          Text(
            'Transaction Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: transactionTypes.map((type) {
              final isSelected = selectedTypes.value.contains(type) ||
                  (type == 'all' && selectedTypes.value.isEmpty);
              return GestureDetector(
                onTap: () {
                  if (type == 'all') {
                    selectedTypes.value = [];
                  } else {
                    var updated = [...selectedTypes.value];
                    updated.remove('all');
                    if (isSelected) {
                      updated.remove(type);
                    } else {
                      updated.add(type);
                    }
                    selectedTypes.value = updated;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Date Filter
          Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedDateRange.value,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
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
          
          // Custom Date Picker
          if (selectedDateRange.value == 'Custom Date') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _EnhancedDatePickerButton(
                    label: customStartDate.value == null
                        ? 'Select Start Date'
                        : 'From: ${_formatDate(customStartDate.value!)}',
                    onPressed: () => _pickDate(true),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EnhancedDatePickerButton(
                    label: customEndDate.value == null
                        ? 'Select End Date'
                        : 'To: ${_formatDate(customEndDate.value!)}',
                    onPressed: () => _pickDate(false),
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedLoadingShimmer(BuildContext context, ColorScheme colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => const _EnhancedShimmerCard(),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.error.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.error.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- ENHANCED: Improved empty state with illustration and friendlier text ---
  Widget _buildScrollableEmptyState(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, {bool isError = false}) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isError ? colorScheme.errorContainer : colorScheme.surface,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isError ? colorScheme.error.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isError ? Icons.error_outline_rounded : Icons.receipt_long_outlined,
                    size: 48,
                    color: isError ? colorScheme.error : colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isError ? 'Failed to load transactions' : 'No Transactions Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isError
                      ? 'Something went wrong. Please try again later or pull to refresh.'
                      : 'Try adjusting your filters or check back later for new transactions.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EnhancedDatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const _EnhancedDatePickerButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
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