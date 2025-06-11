import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/earnings_state.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';
import '../../features/ads/data/services/ad_service.dart';
import 'package:cashsify_app/core/services/transaction_service.dart';
import 'package:cashsify_app/core/models/transaction_state.dart';
import 'package:cashsify_app/core/services/user_service.dart';

class EarningsService {
  final _supabase = SupabaseService();
  final _adService = AdService(SupabaseService().client);
  final TransactionService _transactionService;
  final UserService _userService;
  Stream<EarningsState>? _earningsStream;
  RealtimeChannel? _earningsChannel;
  String? _currentUserId;
  bool _isDisposed = false;
  bool _isSubscribed = false;
  bool _isInitialized = false;

  EarningsService(this._transactionService, this._userService);

  SupabaseService get supabase => _supabase;

  Future<EarningsState?> getTodayEarnings() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('earnings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        try {
          final newRecord = await _supabase.client
              .from('earnings')
              .insert({
                'user_id': user.id,
                'ads_watched': 0,
                'coins_earned': 0,
                'last_updated': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          return EarningsState.fromJson(newRecord);
        } catch (e) {
          AppLogger.error('Error creating new earnings record: $e');
          return null;
        }
      }

      return EarningsState.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting earnings: $e');
      return null;
    }
  }

  Stream<EarningsState> getEarningsStream(String userId) {
    if (_isDisposed) {
      _reset();
    }

    // If we already have a stream for this user, return it
    if (_earningsStream != null && _currentUserId == userId && _isSubscribed && _isInitialized) {
      return _earningsStream!;
    }

    // Clean up existing subscription if user changed
    if (_currentUserId != userId) {
      _cleanup();
      _currentUserId = userId;
    }
    
    try {
      // Create a new stream first
      _earningsStream = _supabase.client
          .from('earnings')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId)
          .map((data) {
            AppLogger.debug('Type of stream data: ${data.runtimeType}');
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

      // Then set up the realtime channel
      final channelName = 'earnings_changes_$userId';
      _earningsChannel = _supabase.client
          .channel(channelName)
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
              if (!_isDisposed) {
                AppLogger.info('Earnings update received for user $userId: $payload');
                _isInitialized = true;
              }
            },
          )
          .subscribe((status, err) {
            if (err != null) {
              AppLogger.error('Error subscribing to earnings changes for user $userId: $err');
              _isSubscribed = false;
              _isInitialized = false;
            } else {
              AppLogger.info('Successfully subscribed to earnings changes for user $userId');
              _isSubscribed = true;
              _isInitialized = true;
            }
          });
    } catch (e) {
      AppLogger.error('Error setting up earnings stream for user $userId: $e');
      _isSubscribed = false;
      _isInitialized = false;
      _cleanup();
    }

    return _earningsStream!;
  }

  void _reset() {
    _isDisposed = false;
    _earningsStream = null;
    _earningsChannel = null;
    _currentUserId = null;
    _isSubscribed = false;
    _isInitialized = false;
  }

  void _cleanup() {
    try {
      if (_earningsChannel != null) {
        _earningsChannel!.unsubscribe();
        _earningsChannel = null;
      }
      _earningsStream = null;
      _isSubscribed = false;
      _isInitialized = false;
    } catch (e) {
      AppLogger.error('Error cleaning up earnings stream: $e');
    }
  }

  Future<bool> processAdWatch(String captchaInput) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return false;

      // Call the RPC function directly. The RPC will now handle daily limits from ads_watched.
      final response = await _supabase.client.rpc(
        'process_ad_watch',
        params: {
          'p_user_id': user.id,
          'captcha_input': captchaInput,
        },
      );

      AppLogger.info('Ad watch processed successfully');
      return response as bool;
    } catch (e) {
      AppLogger.error('Error processing ad watch: $e');
      return false;
    }
  }

  Future<bool> canWatchMoreAds(String userId) async {
    try {
      // This still needs to check daily limits, so we'll query the RPC or ads_watched directly.
      // For simplicity and consistency with RPC, we'll let the RPC handle the main processing.
      // The front-end can check the daily limit via an RPC or a dedicated method if needed.
      return true; // The RPC will enforce the limit, this is a placeholder for now.
    } catch (e) {
      AppLogger.error('Error checking if user can watch more ads: $e');
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _cleanup();
  }
} 