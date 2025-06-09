import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earnings_state.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';
import '../../features/ads/data/services/ad_service.dart';

class EarningsService {
  final _supabase = SupabaseService();
  final _adService = AdService(SupabaseService().client);
  SupabaseService get supabase => _supabase;
  Stream<EarningsState>? _earningsStream;
  RealtimeChannel? _earningsChannel;

  Future<EarningsState?> getTodayEarnings() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return null;

      // Check if we need to reset daily count
      await _checkAndResetDailyCount(user.id);

      final response = await _supabase.client
          .from('earnings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create new earnings record for user
        final newRecord = await _supabase.client
            .from('earnings')
            .insert({
              'user_id': user.id,
              'ads_watched': 0,
              'coins_earned': 0,
              'date': DateTime.now(),
              'last_updated': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        return EarningsState.fromJson(newRecord);
      }

      return EarningsState.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting earnings: $e');
      return null;
    }
  }

  Stream<EarningsState> getEarningsStream(String userId) {
    if (_earningsStream != null) return _earningsStream!;
    
    // Set up real-time subscription
    _earningsChannel = _supabase.client
        .channel('earnings_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'earnings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            AppLogger.info('Earnings update received: $payload');
          },
        )
        .subscribe();

    // Create the stream that combines real-time updates with initial data
    _earningsStream = _supabase.client
        .from('earnings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) {
            return EarningsState(
              userId: userId,
              adsWatched: 0,
              coinsEarned: 0,
              lastUpdated: DateTime.now(),
            );
          }
          return EarningsState.fromJson(data.first);
        });

    return _earningsStream!;
  }

  Future<void> _checkAndResetDailyCount(String userId) async {
    try {
      final response = await _supabase.client
          .from('earnings')
          .select('last_updated')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final lastUpdated = DateTime.parse(response['last_updated']);
        final now = DateTime.now();
        
        // If last update was before today, reset the count
        if (lastUpdated.year != now.year || 
            lastUpdated.month != now.month || 
            lastUpdated.day != now.day) {
          await _supabase.client
              .from('earnings')
              .update({
                'ads_watched': 0,
                'last_updated': now.toIso8601String(),
              })
              .eq('user_id', userId);
        }
      }
    } catch (e) {
      AppLogger.error('Error checking/resetting daily count: $e');
    }
  }

  Future<bool> processAdWatch(String captchaInput) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return false;

      // Use AdService to process the ad watch
      return await _adService.processAdWatch(user.id, captchaInput);
    } catch (e) {
      AppLogger.error('Error processing ad watch: $e');
      return false;
    }
  }

  Future<bool> canWatchMoreAds(String userId) async {
    try {
      final earnings = await getTodayEarnings();
      return earnings?.canWatchMoreAds ?? false;
    } catch (e) {
      AppLogger.error('Error checking if user can watch more ads: $e');
      return false;
    }
  }

  void dispose() {
    _earningsStream = null;
    _earningsChannel?.unsubscribe();
    _earningsChannel = null;
  }
} 