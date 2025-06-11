import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/earnings_state.dart';
import '../services/earnings_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

final transactionServiceProvider = Provider((ref) => TransactionService());
final userServiceProvider = Provider((ref) => UserService());

final earningsServiceProvider = Provider<EarningsService>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  final userService = ref.watch(userServiceProvider);
  return EarningsService(transactionService, userService);
});

final earningsStreamProvider = StreamProvider<EarningsState?>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  final userId = earningsService.supabase.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();
  return earningsService.getEarningsStream(userId);
});

final earningsProvider = StateNotifierProvider<EarningsNotifier, AsyncValue<EarningsState?>>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return EarningsNotifier(earningsService);
});

class EarningsNotifier extends StateNotifier<AsyncValue<EarningsState?>> {
  final EarningsService _earningsService;
  StreamSubscription<EarningsState?>? _subscription;
  String? _currentUserId;

  EarningsNotifier(this._earningsService) : super(const AsyncValue.loading()) {
    _initializeEarnings();
  }

  Future<void> _initializeEarnings() async {
    try {
      final user = _earningsService.supabase.client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Only set up new subscription if user ID changed
      if (_currentUserId != user.id) {
        await _cleanupSubscription();
        _currentUserId = user.id;
        
        // Create new subscription
        _subscription = _earningsService.getEarningsStream(user.id).listen(
          (earnings) {
            if (earnings != null) {
              state = AsyncValue.data(earnings);
            } else {
              state = const AsyncValue.data(null);
            }
          },
          onError: (error, stack) {
            AppLogger.error('Error in earnings stream: $error');
            state = AsyncValue.error(error, stack);
          },
        );
      }

      // Get initial data
      final earnings = await _earningsService.getTodayEarnings();
      if (earnings != null) {
        state = AsyncValue.data(earnings);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      AppLogger.error('Error initializing earnings: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _cleanupSubscription() async {
    try {
      await _subscription?.cancel();
    } catch (e) {
      AppLogger.error('Error cleaning up subscription: $e');
    } finally {
      _subscription = null;
    }
  }

  Future<void> refreshEarnings() async {
    state = const AsyncValue.loading();
    await _initializeEarnings();
  }

  Future<void> loadEarnings() async {
    await refreshEarnings();
  }

  Future<bool> processAdWatch(String captchaInput) async {
    try {
      state = const AsyncValue.loading();
      final success = await _earningsService.processAdWatch(captchaInput);
      
      if (success) {
        // Refresh earnings state after successful ad watch
        await refreshEarnings();
        return true;
      } else {
        state = AsyncValue.error('Failed to process ad watch', StackTrace.current);
        return false;
      }
    } catch (e) {
      AppLogger.error('Error processing ad watch: $e');
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> canWatchMoreAds() async {
    try {
      final user = _earningsService.supabase.client.auth.currentUser;
      if (user == null) return false;
      return await _earningsService.canWatchMoreAds(user.id);
    } catch (e) {
      AppLogger.error('Error checking if user can watch more ads: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _cleanupSubscription();
    _currentUserId = null;
    super.dispose();
  }
} 