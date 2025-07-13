import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_state.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserState?>>((ref) {
  final userService = ref.watch(userServiceProvider);
  return UserNotifier(userService);
});

class UserNotifier extends StateNotifier<AsyncValue<UserState?>> {
  final UserService _userService;
  String? _currentUserId;

  UserNotifier(this._userService) : super(const AsyncValue.loading()) {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      AppLogger.info('Initializing user provider...');
      final currentUser = _userService.supabase.client.auth.currentUser;
      AppLogger.info('Current auth user: ${currentUser?.id}');
      
      if (currentUser == null) {
        AppLogger.info('No current user found, setting state to null');
        _currentUserId = null;
        state = const AsyncValue.data(null);
        return;
      }

      AppLogger.info('Fetching user data for: ${currentUser.id}');
      final userState = await _userService.getUserData(currentUser.id);
      AppLogger.info('User state fetched successfully: ${userState.name}');
      _currentUserId = currentUser.id;
      state = AsyncValue.data(userState);
    } catch (e, stack) {
      AppLogger.error('Error initializing user: $e');
      AppLogger.error('Stack trace: $stack');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refreshUser() async {
    try {
      AppLogger.info('Refreshing user data...');
      final currentUser = _userService.supabase.client.auth.currentUser;
      AppLogger.info('Current auth user during refresh: ${currentUser?.id}');
      
      if (currentUser == null) {
        AppLogger.info('No current user found during refresh, setting state to null');
        _currentUserId = null;
        state = const AsyncValue.data(null);
        return;
      }

      // Check if user ID changed
      if (_currentUserId != currentUser.id) {
        AppLogger.info('User changed from $_currentUserId to ${currentUser.id}');
        _currentUserId = currentUser.id;
      }

      AppLogger.info('Fetching fresh user data for: ${currentUser.id}');
      final userState = await _userService.getUserData(currentUser.id);
      AppLogger.info('User state refreshed successfully: ${userState.name}');
      state = AsyncValue.data(userState);
    } catch (e, stack) {
      AppLogger.error('Error refreshing user: $e');
      AppLogger.error('Stack trace: $stack');
      // Keep previous state if refresh fails
      if (state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> clearUser() async {
    try {
      AppLogger.info('Clearing user state');
      _currentUserId = null;
      state = const AsyncValue.data(null);
    } catch (e) {
      AppLogger.error('Error clearing user: $e');
    }
  }

  String? get currentUserId => _currentUserId;
  bool get hasUser => state.value != null;

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

      // Check and update profile completed status
      await _userService.checkAndUpdateProfileCompleted();

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
      AppLogger.info('User signing out...');
      await _userService.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      AppLogger.info('User signed out successfully, clearing state');
      state = const AsyncValue.data(null);
    } catch (e) {
      AppLogger.error('Error during sign out: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    await _userService.resendVerificationEmail(email);
  }
}

// Provider for current user ID from user provider
final currentUserIdProvider = Provider<String?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.value?.id;
});

// Provider for user authentication status
final isUserAuthenticatedProvider = Provider<bool>((ref) {
  final userState = ref.watch(userProvider);
  return userState.value != null;
});

// Provider for user email
final userEmailProvider = Provider<String?>((ref) {
  final userState = ref.watch(userProvider);
  return userState.value?.email;
}); 