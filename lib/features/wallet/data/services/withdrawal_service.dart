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

      // Step 1: Get user's current coins
      final user = await _supabase.client
          .from('users')
          .select('coins')
          .eq('id', userId)
          .single();

      final currentCoins = user['coins'] as int;

      // Step 2: Check sufficient balance
      if (currentCoins < amount) {
        throw Exception('Insufficient coins for withdrawal.');
      }

      // Step 3: Insert into transactions table (debit)
      final transactionResponse = await _supabase.client.from('transactions').insert({
        'user_id': userId,
        'type': 'withdrawal', // Ensure this type is defined in your schema
        'amount': -amount, // Amount for debit
        'note': 'Withdrawal request of $amount coins via $method',
      }).select('id').single();

      final transactionId = transactionResponse['id'] as String;

      // Step 4: Update users table (decrement coins)
      await _supabase.client.from('users').update({
        'coins': currentCoins - amount,
      }).eq('id', userId);

      // Step 5: Create withdrawal record, linking to transaction_id
      final withdrawalResponse = await _supabase.client.from('withdrawals').insert({
        'user_id': userId,
        'method': method,
        'upi_id': upiId,
        'bank_account': bankDetails,
        'amount': amount,
        'status': 'pending',
        'transaction_id': transactionId, // Link to the newly created transaction
      }).select().single();

      // Step 6: Check if this is the user's first withdrawal and update referral progress (Phase-3)
      final withdrawals = await _supabase.client
          .from('withdrawals')
          .select('id')
          .eq('user_id', userId);

      if (withdrawals != null && withdrawals.length == 1) {
        // Get the referrer_id from referral_progress
        final referralProgress = await _supabase.client
            .from('referral_progress')
            .select('referrer_id')
            .eq('referred_id', userId)
            .maybeSingle();

        if (referralProgress != null) {
          final referrerId = referralProgress['referrer_id'] as String;
          // Mark Phase-3 as done
          await _supabase.client.rpc('update_referral_phase', params: {
            'p_referrer_id': referrerId,
            'p_referred_id': userId,
            'p_phase': 3,
          });
        }
      }

      AppLogger.info('Withdrawal request created successfully: ${withdrawalResponse['id']} with transaction ID: $transactionId');
      return withdrawalResponse;
    } catch (e) {
      AppLogger.error('Error creating withdrawal request: $e');
      // IMPORTANT: For true atomicity (all or nothing), this entire process
      // (checking balance, updating coins, creating transaction, creating withdrawal)
      // should ideally be wrapped in a single database transaction using a Supabase Edge Function
      // or a PostgreSQL function to prevent data inconsistencies if an error occurs mid-way.
      // This client-side approach is sequential.
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