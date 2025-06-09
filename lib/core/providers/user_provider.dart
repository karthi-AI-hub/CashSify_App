import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_state.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserState?>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserNotifier(userService);
});

class UserNotifier extends StateNotifier<AsyncValue<UserState?>> {
  final UserService _userService;

  UserNotifier(this._userService) : super(const AsyncValue.loading()) {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final currentUser = _userService.supabase.client.auth.currentUser;
      if (currentUser == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final userState = await _userService.getUserData(currentUser.id);
      state = AsyncValue.data(userState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshUser() async {
    try {
      final currentUser = _userService.supabase.client.auth.currentUser;
      if (currentUser == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final userState = await _userService.getUserData(currentUser.id);
      state = AsyncValue.data(userState);
    } catch (e, stack) {
      // Keep previous state if refresh fails
      if (state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dob,
    String? upiId,
    Map<String, dynamic>? bankAccount,
    String? profileImageUrl,
  }) async {
    try {
      final currentUser = _userService.supabase.client.auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (gender != null) updates['gender'] = gender;
      if (dob != null) updates['dob'] = dob.toIso8601String();
      if (upiId != null) updates['upi_id'] = upiId;
      if (bankAccount != null) updates['bank_account'] = bankAccount;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      if (updates.isEmpty) return;

      await _userService.supabase.client
          .from('users')
          .update(updates)
          .eq('id', currentUser.id);

      // Force refresh user data immediately
      await refreshUser();
    } catch (e) {
      AppLogger.error('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      await _userService.updatePhoneNumber(phoneNumber);
      await refreshUser();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateEmail(String email) async {
    try {
      await _userService.updateEmail(email);
      await refreshUser();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _userService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      await _userService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
} 