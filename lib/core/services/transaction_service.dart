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

  Future<List<TransactionState>> getTransactions(
    String userId, {
    int? limit,
    List<String>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.client.rpc(
        'get_transactions',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          'p_types': types,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      if (response.error != null) {
        throw response.error!;
      }

      return (response.data as List)
          .map((json) => TransactionState.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching transactions: $e');
      return [];
    }
  }

  Stream<List<TransactionState>> getTransactionsStream(
    String userId, {
    int? limit,
    List<String>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // For streams, we'll use the Supabase realtime API
    return _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TransactionState.fromJson(json)).toList());
  }
}