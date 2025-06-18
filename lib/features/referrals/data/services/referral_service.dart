import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class ReferralService {
  final _supabase = SupabaseService();
  SupabaseService get supabase => _supabase;

  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final response = await _supabase.client.rpc(
        'get_referral_stats',
        params: {'p_user_id': userId},
      );

      if (response.error != null) {
        throw response.error!;
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error fetching referral stats: $e');
      return {
        'total_referrals': 0,
        'total_earned': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getReferralHistory(String userId) async {
    try {
      final response = await _supabase.client
          .from('referral_progress')
          .select('''
            referred_id,
            phase_1_done,
            phase_2_done,
            phase_3_done,
            created_at,
            updated_at,
            users!referred_id (
              name,
              email,
              profile_image_url
            )
          ''')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      if (response == null) {
        return [];
      }

      return (response as List).map((item) {
        final user = item['users'] as Map<String, dynamic>;
        return {
          'name': user['name'] ?? 'Anonymous User',
          'date': item['created_at'],
          'status': [
            item['phase_1_done'] ?? false,
            item['phase_2_done'] ?? false,
            item['phase_3_done'] ?? false,
          ],
          'coins': _calculateReferralCoins(
            item['phase_1_done'] ?? false,
            item['phase_2_done'] ?? false,
            item['phase_3_done'] ?? false,
          ),
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching referral history: $e');
      return [];
    }
  }

  int _calculateReferralCoins(bool phase1, bool phase2, bool phase3) {
    int coins = 0;
    if (phase1) coins += 500; // Signup bonus
    if (phase2) coins += 500; // First ad watch bonus
    if (phase3) coins += 500; // First withdrawal bonus
    return coins;
  }

  Future<String?> getReferralCode(String userId) async {
    try {
      final response = await _supabase.client
          .from('users')
          .select('referral_code')
          .eq('id', userId)
          .single();

      if (response == null) {
        return null;
      }

      return response['referral_code'] as String?;
    } catch (e) {
      AppLogger.error('Error fetching referral code: $e');
      return null;
    }
  }

  Future<void> updateReferralPhase(String referrerId, String referredId, int phase) async {
    try {
      await _supabase.client.rpc(
        'update_referral_phase',
        params: {
          'p_referrer_id': referrerId,
          'p_referred_id': referredId,
          'p_phase': phase,
        },
      );
    } catch (e) {
      AppLogger.error('Error updating referral phase: $e');
      rethrow;
    }
  }
} 