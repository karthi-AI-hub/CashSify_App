import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/features/wallet/presentation/providers/withdrawal_provider.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/models/user_state.dart';
// import 'package:lottie/lottie.dart'; // Uncomment if you have a Lottie asset

final userBalanceProvider = StateProvider<int>((ref) => 15300);
final withdrawalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    {
      'amount': 15000,
      'method': 'UPI',
      'upi': 'user@upi',
      'status': 'approved',
      'requested_at': DateTime.now().subtract(const Duration(days: 1)),
      'processed_at': DateTime.now().subtract(const Duration(hours: 12)),
    },
    {
      'amount': 20000,
      'method': 'Bank',
      'bank': 'XXXXXX1234',
      'status': 'pending',
      'requested_at': DateTime.now().subtract(const Duration(days: 2)),
      'processed_at': null,
    },
    {
      'amount': 15000,
      'method': 'UPI',
      'upi': 'user@upi',
      'status': 'rejected',
      'requested_at': DateTime.now().subtract(const Duration(days: 4)),
      'processed_at': DateTime.now().subtract(const Duration(days: 3, hours: 20)),
    },
  ];
});

enum WithdrawMethod { upi, bank }

class WithdrawScreen extends HookConsumerWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProvider);
    final tabController = useTabController(initialLength: 2);
    final loadingState = ref.watch(loadingProvider);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading,
      message: loadingState == LoadingState.loading ? 'Processing withdrawal...' : null,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with Back Button and Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Redeem Rewards',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Improved TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.primary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Redeem Rewards'),
                      Tab(text: 'Transaction History'),
                    ],
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    userAsync.when(
                      data: (user) => _WithdrawCoinsTab(balance: user?.coins ?? 0),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                    const _WithdrawHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawCoinsTab extends HookConsumerWidget {
  final int balance;
  const _WithdrawCoinsTab({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final formKey = useMemoized(() => GlobalKey<FormState>(), []);
    final coinsController = useTextEditingController();
    final upiController = useTextEditingController();
    final bankNameController = useTextEditingController();
    final bankAccountController = useTextEditingController();
    final bankIfscController = useTextEditingController();
    final method = useState(WithdrawMethod.upi);
    final isSubmitting = useState(false);
    final coinsError = useState<String?>(null);
    final withdrawalAsync = ref.watch(withdrawalProvider);

    int coins = int.tryParse(coinsController.text) ?? 0;
    bool coinsValid = coins >= 15000 && coins <= balance;
    bool upiValid = upiController.text.isNotEmpty && RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upiController.text);
    bool bankValid = bankNameController.text.isNotEmpty &&
        bankAccountController.text.length >= 8 &&
        RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(bankIfscController.text.toUpperCase());
    bool canSubmit = coinsValid && ((method.value == WithdrawMethod.upi && upiValid) || (method.value == WithdrawMethod.bank && bankValid)) && !isSubmitting.value;

    void processWithdrawal() async {
      if (!canSubmit) return;
      isSubmitting.value = true;

      try {
        final withdrawalNotifier = ref.read(withdrawalProvider.notifier);
        await withdrawalNotifier.requestWithdrawal(
          amount: coins,
          method: method.value == WithdrawMethod.upi ? 'upi' : 'bank',
          upiId: method.value == WithdrawMethod.upi ? upiController.text : null,
          bankDetails: method.value == WithdrawMethod.bank
              ? {
                  'name': bankNameController.text,
                  'account_no': bankAccountController.text,
                  'ifsc': bankIfscController.text.toUpperCase(),
                }
              : null,
        );

        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Withdrawal request submitted successfully!',
            type: ToastType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Error submitting withdrawal request: $e',
            type: ToastType.error,
          );
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Balance & Instruction
            Text(
              'Your Balance: $balance points',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum 15,000 points required to redeem',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Input Form
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextFormField(
                      controller: coinsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Coins to Withdraw',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        errorText: coinsError.value,
                        prefixIcon: const Icon(Icons.monetization_on_rounded),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      onChanged: (val) {
                        final value = int.tryParse(val) ?? 0;
                        if (value < 15000) {
                          coinsError.value = 'Minimum 15,000 coins required';
                        } else if (value > balance) {
                          coinsError.value = 'Cannot withdraw more than your balance';
                        } else {
                          coinsError.value = null;
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${int.tryParse(coinsController.text) ?? 0} coins = ₹${((int.tryParse(coinsController.text) ?? 0) / 1000).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Method Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PillButton(
                          label: 'UPI',
                          selected: method.value == WithdrawMethod.upi,
                          onTap: () => method.value = WithdrawMethod.upi,
                        ),
                        const SizedBox(width: 12),
                        _PillButton(
                          label: 'Bank',
                          selected: method.value == WithdrawMethod.bank,
                          onTap: () => method.value = WithdrawMethod.bank,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Conditional Fields
                    if (method.value == WithdrawMethod.upi)
                      TextFormField(
                        controller: upiController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Enter UPI ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter your UPI ID';
                          if (!RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(val)) return 'Invalid UPI ID';
                          return null;
                        },
                      )
                    else ...[
                      TextFormField(
                        controller: bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Account Holder Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Enter account holder name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bankAccountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        validator: (val) => val == null || val.length < 8 ? 'Enter valid account number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bankIfscController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'IFSC Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.code),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter IFSC code';
                          if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(val.toUpperCase())) return 'Invalid IFSC code';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? () {
                                if (!formKey.currentState!.validate()) return;
                                processWithdrawal();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        child: isSubmitting.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Request Withdrawal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawHistoryTab extends HookConsumerWidget {
  const _WithdrawHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final withdrawalsAsync = ref.watch(withdrawalsStreamProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: withdrawalsAsync.when(
        loading: () => ListView.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ShimmerCard(),
        ),
        error: (e, st) => Center(child: Text('Error loading history: $e')),
        data: (withdrawals) {
          if (withdrawals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 64, color: colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No Withdrawals Yet',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: withdrawals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final wd = withdrawals[i];
              return _WithdrawHistoryCard(wd: wd);
            },
          );
        },
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(selected ? 0.0 : 0.2)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onPrimary : colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _WithdrawHistoryCard extends StatelessWidget {
  final Map<String, dynamic> wd;
  const _WithdrawHistoryCard({required this.wd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = wd['status'] as String;
    Color chipColor;
    IconData chipIcon;
    String chipText;
    switch (status) {
      case 'approved':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        chipText = 'Approved';
        break;
      case 'pending':
        chipColor = Colors.amber;
        chipIcon = Icons.hourglass_top_rounded;
        chipText = 'Pending';
        break;
      case 'rejected':
      default:
        chipColor = Colors.redAccent;
        chipIcon = Icons.cancel_rounded;
        chipText = 'Rejected';
    }

    final method = wd['method'] as String;
    String methodText;
    if (method == 'upi') {
      methodText = wd['upi_id'] as String;
    } else {
      final bankDetails = wd['bank_details'] as Map<String, dynamic>;
      methodText = 'A/C ${bankDetails['account_no']}';
    }

    final amount = wd['amount'] as int;
    final requested = DateTime.parse(wd['requested_at'] as String);
    final processed = wd['processed_at'] != null ? DateTime.parse(wd['processed_at'] as String) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$amount Coins',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, color: chipColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      chipText,
                      style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Method: $methodText',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Requested: ${_formatDate(requested)}',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
          ),
          if (processed != null)
            Text(
              'Processed: ${_formatDate(processed)}',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
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