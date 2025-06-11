import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/ad_service.dart';
import '../../domain/models/ad_earnings_model.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';

class EarningsState {
  final int adsWatched;
  final bool isLoading;
  final String? error;

  EarningsState({
    this.adsWatched = 0,
    this.isLoading = false,
    this.error,
  });

  int get adsWatchedToday => adsWatched;
  bool get hasReachedDailyLimit => adsWatched >= 20;

  EarningsState copyWith({
    int? adsWatched,
    bool? isLoading,
    String? error,
  }) {
    return EarningsState(
      adsWatched: adsWatched ?? this.adsWatched,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  final AdService _adService;
  final SupabaseClient _supabase;

  EarningsNotifier(this._adService, this._supabase) : super(EarningsState()) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final earnings = await _adService.getTodayEarnings(userId);
      state = state.copyWith(
        adsWatched: earnings.adsWatched,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> processAdWatch(String captchaInput) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final success = await _adService.processAdWatch(userId, captchaInput);
      if (success) {
        await loadEarnings();
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }
}

final earningsProvider = StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  final supabase = SupabaseService().client;
  final adService = AdService(supabase);
  return EarningsNotifier(adService, supabase);
}); 