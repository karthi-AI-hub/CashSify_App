import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class TransactionService {
  final _supabase = SupabaseService();
  SupabaseService get supabase => _supabase;

  Future<void> addTransaction(TransactionState transaction) async {
    try {
      await _supabase.client.from('transactions').insert(transaction.toJson());
      AppLogger.info('Transaction added successfully: ${transaction.type}');
    } catch (e) {
      AppLogger.error('Error adding transaction: $e');
      rethrow;
    }
  }

  Stream<List<TransactionState>> getTransactionsStream(String userId) {
    return _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TransactionState.fromJson(json)).toList());
  }

  Future<List<TransactionState>> getTransactions(String userId) async {
    try {
      final response = await _supabase.client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response.map((json) => TransactionState.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error fetching transactions: $e');
      return [];
    }
  }
} 