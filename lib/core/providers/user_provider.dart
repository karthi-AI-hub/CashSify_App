import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_state.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userStreamProvider = StreamProvider<UserState?>((ref) {
  final userService = ref.watch(userServiceProvider);
  final userId = userService.supabase.client.auth.currentUser?.id;
  if (userId == null) return const Stream.empty();
  return userService.getUserStream(userId);
});

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
      final userState = await _userService.getCurrentUserState();
      state = AsyncValue.data(userState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    await _initializeUser();
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
      // Set loading state
      state = const AsyncValue.loading();

      // Perform the actual update
      await _userService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        dob: dob,
        upiId: upiId,
        bankAccount: bankAccount,
        profileImageUrl: profileImageUrl,
      );

      // Get the latest data
      final userState = await _userService.getCurrentUserState();
      state = AsyncValue.data(userState);
    } catch (e) {
      // Set error state
      state = AsyncValue.error(e, StackTrace.current);
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