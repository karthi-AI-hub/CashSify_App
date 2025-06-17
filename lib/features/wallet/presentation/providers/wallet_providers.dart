import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/services/transaction_service.dart';
import 'package:cashsify_app/features/wallet/data/services/wallet_service.dart';

// Provider for WalletService
final transactionServiceProvider = Provider((ref) => TransactionService());
final walletServiceProvider = Provider<WalletService>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return WalletService(transactionService);
});

// StreamProvider for transaction history
final transactionsStreamProvider = StreamProvider<List<TransactionState>>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  final userId = transactionService.supabase.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();
  
  return transactionService.getTransactionsStream(userId, limit: 10);
}); 