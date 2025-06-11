import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/models/earnings_state.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/services/transaction_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class WalletService {
  final _supabase = SupabaseService();
  final TransactionService _transactionService;

  WalletService(this._transactionService);

  SupabaseService get supabase => _supabase;

  // Process a withdrawal
  Future<bool> processWithdrawal({
    required String userId,
    required int amount,
    String? method,
    String? details,
  }) async {
    try {
      // Fetch current earnings
      final response = await _supabase.client
          .from('earnings')
          .select('coins_earned')
          .eq('user_id', userId)
          .single();

      final currentCoins = response['coins_earned'] as int;

      if (currentCoins < amount) {
        AppLogger.warning('Insufficient coins for withdrawal: $currentCoins < $amount');
        return false; // Insufficient funds
      }

      // Deduct coins from earnings
      final newCoins = currentCoins - amount;
      await _supabase.client
          .from('earnings')
          .update({'coins_earned': newCoins})
          .eq('user_id', userId);

      // Add transaction record for withdrawal
      await _transactionService.addTransaction(
        TransactionState(
          id: userId + DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
          userId: userId,
          type: 'withdraw',
          amount: -amount, // Negative amount for withdrawal
          note: 'Withdrawal via ${method ?? 'N/A'}' + (details != null ? ' ($details)' : ''),
          createdAt: DateTime.now(),
        ),
      );

      AppLogger.info('Withdrawal processed successfully for user $userId, amount $amount');
      return true;
    } catch (e) {
      AppLogger.error('Error processing withdrawal: $e');
      return false;
    }
  }
} 