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
    var query = _supabase.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    // Apply type filter if provided
    if (types != null && types.isNotEmpty) {
      // For type filtering, we'll need to handle it in the map function
      return query
          .order('created_at', ascending: false)
          .map((data) {
            var filteredData = data.where((item) => types.contains(item['type'])).toList();
            return filteredData.map((json) => TransactionState.fromJson(json)).toList();
          });
    }

    // Apply date range filter if provided
    if (startDate != null || endDate != null) {
      return query
          .order('created_at', ascending: false)
          .map((data) {
            var filteredData = data.where((item) {
              final createdAt = DateTime.parse(item['created_at']);
              if (startDate != null && createdAt.isBefore(startDate)) return false;
              if (endDate != null && createdAt.isAfter(endDate)) return false;
              return true;
            }).toList();
            return filteredData.map((json) => TransactionState.fromJson(json)).toList();
          });
    }

    // If no filters are applied, return all transactions
    return query
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TransactionState.fromJson(json)).toList());
  }
}