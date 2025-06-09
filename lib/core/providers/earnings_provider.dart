import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/earnings_state.dart';
import '../services/earnings_service.dart';

final earningsServiceProvider = Provider<EarningsService>((ref) => EarningsService());

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

      // Set up real-time subscription
      _subscription?.cancel();
      _subscription = _earningsService.getEarningsStream(user.id).listen(
        (earnings) {
          if (earnings != null) {
            state = AsyncValue.data(earnings);
          }
        },
        onError: (error, stack) {
          state = AsyncValue.error(error, stack);
        },
      );

      // Get initial data
      final earnings = await _earningsService.getTodayEarnings();
      state = AsyncValue.data(earnings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
      final success = await _earningsService.processAdWatch(captchaInput);
      if (success) {
        await refreshEarnings();
      }
      return success;
    } catch (e) {
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
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
} 