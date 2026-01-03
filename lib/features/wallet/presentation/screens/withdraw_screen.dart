import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/features/wallet/presentation/providers/withdrawal_provider.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/utils/pdf_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/services/storage_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/theme/app_colors.dart';
// import 'package:lottie/lottie.dart'; // Uncomment if you have a Lottie asset
import 'package:cashsify_app/core/services/analytics_service.dart';

enum WithdrawMethod { upi, bank }

class WithdrawScreen extends HookConsumerWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProvider);
    final tabController = useTabController(initialLength: 2);
    final loadingState = ref.watch(loadingProvider);
    final currentIndex = useState(0);

    // Listen to tab changes for animations
    useEffect(() {
      void listener() {
        currentIndex.value = tabController.index;
      }
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false; // Prevent default back behavior
      },
      child: LoadingOverlay(
        isLoading: loadingState == LoadingState.loading,
        message: loadingState == LoadingState.loading ? 'Processing withdrawal...' : null,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: userAsync.when(
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
                
                return hasHistory ? 'Withdrawals' : 'Redeem Coins';
              },
              loading: () => 'Redeem Coins',
              error: (e, st) => 'Redeem Coins',
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
              color: colorScheme.onPrimary,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: () => _showDownloadedPdfs(context),
                color: Theme.of(context).colorScheme.onPrimary,
                tooltip: 'Manage Downloaded PDFs',
              ),
            ],
          ),
          body: Column(
            children: [
              // Enhanced Balance Card
              userAsync.when(
                data: (user) => _buildBalanceCard(context, user?.coins ?? 0, colorScheme),
                loading: () => _buildBalanceCard(context, 0, colorScheme, isLoading: true),
                error: (e, st) => _buildBalanceCard(context, 0, colorScheme, hasError: true),
              ),
              
              // Enhanced TabBar with animations
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text('Redeem'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text('History'),
                          ],
                        ),
                      ),
                    ],
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // TabBarView with enhanced content
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    userAsync.when(
                      data: (user) => _WithdrawCoinsTab(balance: user?.coins ?? 0),
                      loading: () => _buildLoadingState(context, colorScheme),
                      error: (e, st) => _buildErrorState(context, colorScheme, e.toString()),
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

  Widget _buildBalanceCard(BuildContext context, int balance, ColorScheme colorScheme, {bool isLoading = false, bool hasError = false}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
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
                    if (isLoading)
                      Container(
                        width: 100,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )
                    else if (hasError)
                      Text(
                        'Error loading balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        '${balance.toStringAsFixed(0)} Coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLoading && !hasError) ...[
            const SizedBox(height: 16),
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
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Minimum 15,000 coins required',
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
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: colorScheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your balance...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(20),
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
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showDownloadedPdfs(BuildContext context) async {
    try {
      final storageService = StorageService();
      final pdfFiles = await storageService.listDownloadedPdfs();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Downloaded PDFs'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: pdfFiles.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No downloaded PDFs found'),
                            SizedBox(height: 8),
                            Text(
                              'Download PDFs using the Download button in withdrawal history',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pdfFiles.length,
                        itemBuilder: (context, index) {
                          final file = pdfFiles[index] as File;
                          final fileName = file.path.split('/').last;
                          final fileSize = file.lengthSync();
                          final modified = file.lastModifiedSync();
                          
                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${(fileSize / 1024).toStringAsFixed(1)} KB • ${_formatDate(modified)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'open') {
                                  try {
                                    await OpenFilex.open(file.path);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error opening file: $e')),
                                      );
                                    }
                                  }
                                } else if (value == 'share') {
                                  try {
                                    await Share.shareXFiles([XFile(file.path)]);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error sharing file: $e')),
                                      );
                                    }
                                  }
                                } else if (value == 'delete') {
                                  try {
                                    await file.delete();
                                    Navigator.of(dialogContext).pop();
                                    _showDownloadedPdfs(context); // Refresh the dialog
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error deleting file: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new, size: 16),
                                      SizedBox(width: 8),
                                      Text('Open'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, size: 16),
                                      SizedBox(width: 8),
                                      Text('Share'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                if (pdfFiles.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: dialogContext,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All PDFs'),
                          content: const Text('Are you sure you want to delete all downloaded PDFs?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        final success = await storageService.clearDownloadedPdfs();
                        if (context.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'All PDFs cleared' : 'Error clearing PDFs'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading downloaded PDFs: $e')),
        );
      }
    }
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

class _WithdrawCoinsTab extends HookConsumerWidget {
  final int balance;
  const _WithdrawCoinsTab({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final formKey = useMemoized(() => GlobalKey<FormState>(), []);
    final coinsController = useTextEditingController();
    final method = useState(WithdrawMethod.upi);
    final isSubmitting = useState(false);
    final coinsError = useState<String?>(null);
    final withdrawalAsync = ref.watch(withdrawalProvider);
    final user = ref.watch(userProvider).value; // Get the user data

    int coins = int.tryParse(coinsController.text) ?? 0;
    bool coinsValid = coins >= 15000 && coins <= balance;
    
    // Check if UPI/Bank details exist in UserState
    bool upiDetailsExist = user?.upiId != null && user!.upiId!.isNotEmpty;
    bool bankDetailsExist = user?.bankAccount != null && 
                            (user!.bankAccount!['account_no'] as String? ?? '').isNotEmpty &&
                            (user.bankAccount!['ifsc'] as String? ?? '').isNotEmpty;

    bool canSubmit = coinsValid && 
                     ((method.value == WithdrawMethod.upi && upiDetailsExist) || 
                      (method.value == WithdrawMethod.bank && bankDetailsExist)) && 
                     !isSubmitting.value &&
                     balance >= 15000;

    void processWithdrawal() async {
      if (!canSubmit) {
        if (method.value == WithdrawMethod.upi && !upiDetailsExist) {
          CustomToast.show(context, message: 'Please add your UPI ID in Profile.', type: ToastType.error);
        } else if (method.value == WithdrawMethod.bank && !bankDetailsExist) {
          CustomToast.show(context, message: 'Please add your Bank Account details in Profile.', type: ToastType.error);
        }
        return;
      }
      isSubmitting.value = true;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirm Redemption',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to redeem ',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  '$coins coins',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Via:',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 5),
                if (method.value == WithdrawMethod.upi && upiDetailsExist)
                  _buildConfirmationDetailRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'UPI ID',
                    value: user!.upiId!,
                    colorScheme: colorScheme,
                  ),
                if (method.value == WithdrawMethod.bank && bankDetailsExist) ...[
                  _buildConfirmationDetailRow(
                    icon: Icons.person_outline,
                    label: 'Account Holder',
                    value: user!.bankAccount!['name'],
                    colorScheme: colorScheme,
                  ),
                  _buildConfirmationDetailRow(
                    icon: Icons.account_balance,
                    label: 'Account No',
                    value: user.bankAccount!['account_no'],
                    colorScheme: colorScheme,
                  ),
                  _buildConfirmationDetailRow(
                    icon: Icons.code,
                    label: 'IFSC Code',
                    value: user.bankAccount!['ifsc'],
                    colorScheme: colorScheme,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to proceed?',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          );
        },
      ) ?? false; // Default to false if dialog is dismissed

      if (!confirmed) {
        isSubmitting.value = false;
        return;
      }
      
      try {
        final withdrawalNotifier = ref.read(withdrawalProvider.notifier);
        final response = await withdrawalNotifier.requestWithdrawal(
          amount: coins,
          method: method.value == WithdrawMethod.upi ? 'upi' : 'bank',
          upiId: method.value == WithdrawMethod.upi ? user?.upiId : null,
          bankDetails: method.value == WithdrawMethod.bank ? user?.bankAccount : null,
          userId: user?.id ?? '', // Pass the user ID
        );

        final analytics = AnalyticsService();
        await analytics.logWithdrawalRequested(
          coins.toDouble(),
          method.value == WithdrawMethod.upi ? 'upi' : 'bank',
        );

        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Withdrawal submitted! PDF generated and uploaded. Check History tab for latest PDF.',
            duration: const Duration(seconds: 4),
            showCloseButton: true,
            type: ToastType.success,
          );
          
          // Generate PDF summary and save to storage
          final pdfPath = await PdfUtils.generateWithdrawalPdf(
            amount: coins,
            method: method.value == WithdrawMethod.upi ? 'upi' : 'bank',
            upiId: method.value == WithdrawMethod.upi ? user?.upiId : null,
            bankDetails: method.value == WithdrawMethod.bank ? user?.bankAccount : null,
            status: 'pending', // Newly submitted withdrawal will be pending
            requestedAt: DateTime.now(),
            withdrawalId: response?['id'], // Pass the actual ID from Supabase
            userId: user?.id, // Pass userId for Supabase storage
          );
          
          if (pdfPath != null) {
            AppLogger.info('PDF generated and saved successfully: $pdfPath');
            
            // Refresh withdrawal data to get the latest PDF URLs
            ref.refresh(withdrawalsStreamProvider);
            ref.refresh(withdrawalsFutureProvider);
            
            // Show success message with PDF info
            if (context.mounted) {
              CustomToast.show(
                context,
                message: 'PDF generated and uploaded successfully! Check History tab to download.',
                duration: const Duration(seconds: 4),
                showCloseButton: true,
                type: ToastType.success,
              );
            }
          } else {
            AppLogger.error('Failed to generate or save PDF');
            if (context.mounted) {
              CustomToast.show(
                context,
                message: 'PDF generation failed, but withdrawal was submitted successfully.',
                type: ToastType.warning,
              );
            }
          }
          
          context.pop();
        }
      } catch (e) {
        AppLogger.error('Error processing withdrawal: $e');
        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Error submitting withdrawal request: ${e.toString()}',
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
            // Enhanced insufficient balance warning
            if (balance < 15000) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insufficient Balance',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You need at least 15,000 coins to make a withdrawal. You can still view your withdrawal history in the History tab.',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                'Minimum 15,000 points required to redeem',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Enhanced Withdrawal Form Card
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Withdrawal Details',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Amount Input
                    TextFormField(
                      controller: coinsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount to Withdraw',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        errorText: coinsError.value,
                        prefixIcon: Icon(
                          Icons.monetization_on_rounded,
                          color: colorScheme.primary,
                        ),
                        suffixText: 'coins',
                        suffixStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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
                    
                    const SizedBox(height: 20),
                    
                    // Method Selection
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodButton(
                            context,
                            'UPI',
                            method.value == WithdrawMethod.upi,
                            upiDetailsExist,
                            () => method.value = WithdrawMethod.upi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMethodButton(
                            context,
                            'Bank',
                            method.value == WithdrawMethod.bank,
                            bankDetailsExist,
                            () => method.value = WithdrawMethod.bank,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Payment Details Display
                    _buildPaymentDetailsDisplay(
                      context,
                      method.value,
                      user,
                      upiDetailsExist,
                      bankDetailsExist,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? () {
                                if (!formKey.currentState!.validate()) return;
                                processWithdrawal();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSubmitting.value
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                balance < 15000 
                                    ? 'Insufficient Balance' 
                                    : 'Request Withdrawal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
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

  Widget _buildMethodButton(
    BuildContext context,
    String label,
    bool isSelected,
    bool isConfigured,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isConfigured 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isConfigured ? '✓ Set' : '! Not Set',
                style: TextStyle(
                  color: isConfigured ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsDisplay(
    BuildContext context,
    WithdrawMethod method,
    dynamic user,
    bool upiDetailsExist,
    bool bankDetailsExist,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (method == WithdrawMethod.upi)
            _buildDetailRow(
              context,
              Icons.account_balance_wallet_rounded,
              'UPI ID',
              user?.upiId ?? 'Not configured',
              upiDetailsExist,
            )
          else ...[
            _buildDetailRow(
              context,
              Icons.person_outline_rounded,
              'Account Holder',
              user?.bankAccount?['name'] ?? 'Not configured',
              bankDetailsExist,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              Icons.account_balance_rounded,
              'Account Number',
              user?.bankAccount?['account_no'] ?? 'Not configured',
              bankDetailsExist,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              Icons.code_rounded,
              'IFSC Code',
              user?.bankAccount?['ifsc'] ?? 'Not configured',
              bankDetailsExist,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isConfigured,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.onSurfaceVariant,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isConfigured ? colorScheme.onSurface : colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        if (!isConfigured)
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 18,
          ),
      ],
    );
  }

  // New helper widget for confirmation dialog details
  Widget _buildConfirmationDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    final user = ref.watch(userProvider).value;
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(withdrawalsStreamProvider);
      },
      child: Column(
        children: [
          // Header with Fix All PDFs button
          withdrawalsAsync.when(
            data: (withdrawals) {
              final withdrawalsWithMissingPdfs = withdrawals.where((wd) {
                final pdfUrl = wd['pdf_url'] as String?;
                return pdfUrl == null || pdfUrl.isEmpty;
              }).toList();
              
              if (withdrawalsWithMissingPdfs.isNotEmpty && user != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${withdrawalsWithMissingPdfs.length} withdrawal(s) missing PDF',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _fixAllMissingPdfUrls(context, ref, user.id),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Fix All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Withdrawals list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: withdrawalsAsync.when(
                loading: () => ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _EnhancedShimmerCard(),
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
                      return _EnhancedWithdrawHistoryCard(wd: wd);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fixAllMissingPdfUrls(BuildContext context, WidgetRef ref, String userId) async {
    try {
      final storageService = StorageService();
      
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Fixing missing PDF URLs...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Fix all missing PDF URLs
      final fixedCount = await storageService.fixMissingPdfUrls(userId: userId);
      
      if (context.mounted) {
        if (fixedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully fixed $fixedCount PDF URL(s)! Refresh to see updates.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the withdrawal data
          ref.refresh(withdrawalsStreamProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No missing PDF URLs found to fix.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing PDF URLs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EnhancedShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 60,
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

class _EnhancedWithdrawHistoryCard extends StatelessWidget {
  final Map<String, dynamic> wd;
  const _EnhancedWithdrawHistoryCard({required this.wd});

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
      final bankDetails = wd['bank_account'];
      if (bankDetails is Map<String, dynamic>) {
        methodText = 'A/C ${bankDetails['account_no']}';
      } else {
        methodText = 'Bank details not available';
      }
    }

    final amount = wd['amount'] as int;
    final requested = DateTime.parse(wd['requested_at'] as String);
    final processed = wd['processed_at'] != null ? DateTime.parse(wd['processed_at'] as String) : null;
    final withdrawalId = wd['id'] as String;
    final userId = wd['user_id'] as String;
    final pdfUrl = wd['pdf_url'] as String?;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$amount Coins',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Method: $methodText',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested: ${_formatDate(requested)}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    if (processed != null)
                      Text(
                        'Processed: ${_formatDate(processed)}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chipColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chipIcon, color: chipColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      chipText,
                      style: TextStyle(
                        color: chipColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Enhanced PDF Actions Section
          _buildEnhancedPdfActionsSection(
            context,
            colorScheme,
            userId,
            withdrawalId,
            pdfUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPdfActionsSection(
    BuildContext context,
    ColorScheme colorScheme,
    String userId,
    String withdrawalId,
    String? pdfUrl,
  ) {
    if (pdfUrl == null || pdfUrl.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No PDF Available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF will be generated automatically when withdrawal status is updated.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _fixMissingPdfUrl(context, userId, withdrawalId),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Check for PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal Summary PDF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View and download your complete withdrawal summary with status timeline.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewPdf(context, userId, withdrawalId),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadPdfToDevice(context, userId, withdrawalId),
                  icon: const Icon(Icons.download, size: 14),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sharePdf(context, userId, withdrawalId),
              icon: const Icon(Icons.share, size: 14),
              label: const Text('Share PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary.withOpacity(0.1),
                foregroundColor: colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colorScheme.secondary.withOpacity(0.3)),
                ),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for PDF actions
  Future<void> _viewPdf(BuildContext context, String userId, String withdrawalId) async {
    // Implementation for viewing PDF
  }

  Future<void> _downloadPdfToDevice(BuildContext context, String userId, String withdrawalId) async {
    // Implementation for downloading PDF
  }

  Future<void> _sharePdf(BuildContext context, String userId, String withdrawalId) async {
    // Implementation for sharing PDF
  }

  Future<void> _fixMissingPdfUrl(BuildContext context, String userId, String withdrawalId) async {
    // Implementation for fixing missing PDF URL
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