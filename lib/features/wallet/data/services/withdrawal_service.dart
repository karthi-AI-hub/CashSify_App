import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class WithdrawalService {
  final _supabase = SupabaseService();

  SupabaseService get supabase => _supabase;

  // Get withdrawals stream for a user
  Stream<List<Map<String, dynamic>>> getWithdrawalsStream(String userId) {
    return _supabase.client
        .from('withdrawals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('requested_at', ascending: false)
        .map((events) => events);
  }

  // Request a new withdrawal
  Future<Map<String, dynamic>?> requestWithdrawal({
    required String userId,
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      // Validate input
      if (method == 'upi' && (upiId == null || upiId.isEmpty)) {
        throw Exception('UPI ID is required for UPI withdrawals');
      }
      if (method == 'bank' && (bankDetails == null || bankDetails.isEmpty)) {
        throw Exception('Bank details are required for bank withdrawals');
      }

      // Create withdrawal record
      final response = await _supabase.client.from('withdrawals').insert({
        'user_id': userId,
        'method': method,
        'upi_id': upiId,
        'bank_account': bankDetails,
        'amount': amount,
        'status': 'pending',
      }).select().single();

      AppLogger.info('Withdrawal request created successfully: ${response['id']}');
      return response;
    } catch (e) {
      AppLogger.error('Error creating withdrawal request: $e');
      rethrow;
    }
  }

  // Get withdrawal history for a user
  Future<List<Map<String, dynamic>>> getWithdrawalHistory(String userId) async {
    try {
      final response = await _supabase.client
          .from('withdrawals')
          .select()
          .eq('user_id', userId)
          .order('requested_at', ascending: false);

      return response;
    } catch (e) {
      AppLogger.error('Error fetching withdrawal history: $e');
      rethrow;
    }
  }
} 