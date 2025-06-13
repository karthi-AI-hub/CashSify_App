import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/features/wallet/data/services/withdrawal_service.dart';

// Provider for WithdrawalService
final withdrawalServiceProvider = Provider((ref) => WithdrawalService());

// StreamProvider for withdrawal history
final withdrawalsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  final userId = withdrawalService.supabase.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();
  
  return withdrawalService.getWithdrawalsStream(userId);
});

// StateNotifier for withdrawal requests
class WithdrawalNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final WithdrawalService _withdrawalService;

  WithdrawalNotifier(this._withdrawalService) : super(const AsyncValue.data(null));

  Future<void> requestWithdrawal({
    required int amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      state = const AsyncValue.loading();
      final userId = _withdrawalService.supabase.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _withdrawalService.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: method,
        upiId: upiId,
        bankDetails: bankDetails,
      );

      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final withdrawalProvider = StateNotifierProvider<WithdrawalNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final withdrawalService = ref.watch(withdrawalServiceProvider);
  return WithdrawalNotifier(withdrawalService);
}); 