import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:convert';

class ReferralService {
  final _supabase = SupabaseService();
  SupabaseService get supabase => _supabase;

  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      AppLogger.info('Fetching referral stats for user: $userId');
      final result = await _supabase.client.rpc(
        'get_referral_stats',
        params: {'p_user_id': userId},
      );
      if (result == null) {
        return {'total_referrals': 0, 'total_earned': 0};
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      if (result is String) {
        final decoded = jsonDecode(result);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      return {'total_referrals': 0, 'total_earned': 0};
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
      AppLogger.info('Fetching referral history for user: $userId');
      
      // Use the correct foreign key relationship for the join
      final response = await _supabase.client
          .from('referral_progress')
          .select('''
            referred_id,
            phase,
            created_at,
            updated_at,
            referred_user:users!referral_progress_referred_id_fkey(
              name,
              email,
              profile_image_url
            )
          ''')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      AppLogger.info('Raw Supabase response: $response');

      if (response == null || response is! List) {
        AppLogger.warning('Invalid response format from Supabase');
        return [];
      }

      return (response as List).map((item) {
        AppLogger.info('Processing item: $item');
        
        final userRaw = item['referred_user'];
        AppLogger.info('Raw user data: $userRaw');
        
        Map<String, dynamic> user = {};
        if (userRaw != null) {
          if (userRaw is Map) {
            user = Map<String, dynamic>.from(userRaw);
            AppLogger.info('Parsed user map: $user');
          } else if (userRaw is String) {
            try {
              user = Map<String, dynamic>.from(jsonDecode(userRaw));
              AppLogger.info('Parsed user from JSON string: $user');
            } catch (e) {
              AppLogger.error('Error parsing user data: $e');
            }
          }
        }

        final int phase = item['phase'] ?? 0;
        final String userName = user['name']?.toString().trim() ?? '';
        AppLogger.info('Extracted user name: $userName');
        
        final result = {
          'name': userName.isNotEmpty ? userName : 'Anonymous User',
          'date': item['created_at'] ?? DateTime.now().toIso8601String(),
          'status': [
            phase >= 1, // Signup
            phase >= 2, // First ad watch
            phase >= 3, // First withdrawal
          ],
          'coins': _calculateReferralCoins(
            phase >= 1,
            phase >= 2,
            phase >= 3,
          ),
        };
        
        AppLogger.info('Final mapped result: $result');
        return result;
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching referral history: $e');
      AppLogger.error('Stack trace: $stackTrace');
      return [];
    }
  }

  int _calculateReferralCoins(bool phase1, bool phase2, bool phase3) {
    int coins = 0;
    if (phase1) coins += 500; // Signup bonus
    if (phase2) coins += 500; // First ad watch bonus
    if (phase3) coins += 1000; // First withdrawal bonus
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