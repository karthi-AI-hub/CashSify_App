import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ad_watch_model.dart';
import '../../domain/models/ad_earnings_model.dart';

class AdService {
  final SupabaseClient _supabase;

  AdService(this._supabase);

  Future<bool> processAdWatch(String userId, String captchaInput) async {
    try {
      if (userId != _supabase.auth.currentUser?.id) {
        throw Exception('Unauthorized: User ID mismatch');
      }

      if (captchaInput.isEmpty || captchaInput.length < 4) {
        throw Exception('Invalid CAPTCHA input');
      }

      final response = await _supabase.rpc(
        'process_ad_watch',
        params: {
          'p_user_id': userId,
          'captcha_input': captchaInput,
        },
      );
      return response as bool;
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == 'P0001') {
          // Handle specific error messages from the function
          if (e.message.contains('Daily ad limit reached')) {
            throw Exception('You have reached your daily ad limit');
          } else if (e.message.contains('Invalid CAPTCHA input')) {
            throw Exception('Invalid CAPTCHA code. Please try again');
          }
        }
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to process ad watch: $e');
    }
  }

  Future<AdEarningsModel> getTodayEarnings(String userId) async {
    try {
      if (userId != _supabase.auth.currentUser?.id) {
        throw Exception('Unauthorized: User ID mismatch');
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Attempt to fetch the current earnings record
      final response = await _supabase
          .from('earnings')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      if (response == null) {
        // If no record exists for today, create one with 0 ads watched
        final newRecord = await _supabase
            .from('earnings')
            .insert({
              'user_id': userId,
              'date': today,
              'ads_watched': 0,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        return AdEarningsModel.fromJson(newRecord);
      }

      // If a record exists, return it
      return AdEarningsModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      throw Exception('Failed to get earnings: $e');
    }
  }

  Stream<AdEarningsModel> watchTodayEarnings(String userId) {
    try {
      if (userId != _supabase.auth.currentUser?.id) {
        throw Exception('Unauthorized: User ID mismatch');
      }

      return _supabase
          .from('earnings')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId)
          .map((data) => data.isEmpty
              ? AdEarningsModel(
                  userId: userId,
                  date: DateTime.now(),
                  adsWatched: 0,
                  lastUpdated: DateTime.now(),
                )
              : AdEarningsModel.fromJson(data.first));
    } catch (e) {
      throw Exception('Failed to watch earnings: $e');
    }
  }

  Future<List<AdWatchModel>> getAdWatchHistory(String userId) async {
    try {
      if (userId != _supabase.auth.currentUser?.id) {
        throw Exception('Unauthorized: User ID mismatch');
      }

      final response = await _supabase
          .from('ads_watched')
          .select()
          .eq('user_id', userId)
          .order('watched_at', ascending: false);

      return response.map((json) => AdWatchModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get ad watch history: $e');
    }
  }
} 