import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/withdrawal_service.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/services/storage_service.dart';

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Provider for WithdrawalService
final withdrawalServiceProvider = Provider<WithdrawalService>((ref) {
  return WithdrawalService();
});

// StreamProvider for withdrawal history - now depends on user
final withdrawalsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  
  // Watch user provider to refresh when user changes
  final userAsync = ref.watch(userProvider);
  
  return userAsync.when(
    data: (user) {
      final userId = user?.id;
      if (userId == null) return const Stream.empty();
      
      return withdrawalService.getWithdrawalsStream(userId);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// FutureProvider as fallback for withdrawal history - now depends on user
final withdrawalsFutureProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  
  // Watch user provider to refresh when user changes
  final userAsync = ref.watch(userProvider);
  
  return userAsync.when(
    data: (user) async {
      final userId = user?.id;
      if (userId == null) return [];
      
      return await withdrawalService.getWithdrawalHistory(userId);
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

// Provider for withdrawal history - depends on user
final withdrawalHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  final userAsync = ref.watch(userProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return [];
      return await withdrawalService.getWithdrawalHistory(user.id);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// StateNotifier for withdrawal requests
class WithdrawalNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final WithdrawalService _withdrawalService;

  WithdrawalNotifier(this._withdrawalService) : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>?> requestWithdrawal({
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
    required String userId, // Accept userId as parameter
  }) async {
    try {
      // Validate inputs
      if (amount < 15000) {
        throw Exception('Minimum withdrawal amount is 15,000 coins');
      }
      
      if (method.isEmpty || (method != 'upi' && method != 'bank')) {
        throw Exception('Invalid withdrawal method. Must be "upi" or "bank"');
      }
      
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }
      
      // Validate method-specific details
      if (method == 'upi' && (upiId == null || upiId.isEmpty)) {
        throw Exception('UPI ID is required for UPI withdrawals');
      }
      
      if (method == 'bank' && (bankDetails == null || bankDetails.isEmpty)) {
        throw Exception('Bank details are required for bank withdrawals');
      }
      
      state = const AsyncValue.loading();

      final response = await _withdrawalService.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: method,
        upiId: upiId,
        bankDetails: bankDetails,
      );

      if (response == null) {
        throw Exception('Failed to create withdrawal request');
      }

      state = AsyncValue.data(response);
      return response;
    } catch (e) {
      final error = e is Exception ? e.toString() : 'An unexpected error occurred';
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  /// Reset the withdrawal state
  void reset() {
    state = const AsyncValue.data(null);
  }

  /// Clear any errors
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

final withdrawalProvider = StateNotifierProvider<WithdrawalNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  return WithdrawalNotifier(withdrawalService);
}); 