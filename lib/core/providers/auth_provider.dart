import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/providers/supabase_provider.dart';
import 'package:cashsify_app/core/models/user_state.dart';

// Auth state class
class AppAuthState {
  final UserState? user;
  final bool isLoading;
  final String? error;

  const AppAuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AppAuthState copyWith({
    UserState? user,
    bool? isLoading,
    String? error,
  }) {
    return AppAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth notifier
class AuthProvider extends StateNotifier<AppAuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthProvider(this._supabaseService) : super(const AppAuthState()) {
    _init();
  }

  Future<void> _init() async {
    // Get initial session
    final session = await _supabaseService.getCurrentSession();
    if (session != null) {
      state = state.copyWith(
        user: UserState.fromUser(session.user),
        isLoading: false,
      );
    }

    // Listen to auth state changes
    _authStateSubscription = _supabaseService.onAuthStateChange.listen((event) {
      if (event.session?.user != null) {
        state = state.copyWith(
          user: UserState.fromUser(event.session!.user),
          isLoading: false,
        );
      } else {
        state = const AppAuthState();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Sign in with password
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthError.invalidCredentials();
      }

      if (!mounted) return;
      state = state.copyWith(
        user: UserState.fromUser(response.user!),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      
      if (e is AuthException) {
        rethrow; // Let the UI handle the error message
      } else if (e is AppError) {
        state = state.copyWith(
          error: e.message,
          isLoading: false,
        );
        rethrow;
      } else {
        state = state.copyWith(
          error: 'An unexpected error occurred during login',
          isLoading: false,
        );
        rethrow;
      }
    }
  }

  // Register with referral
  Future<void> registerWithReferral({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? referredCode,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Create auth account
      final response = await _supabaseService.signUpWithPassword(
        email: email,
        password: password,
        displayName: name,
      );

      if (response.user == null) {
        throw AuthError(
          message: 'Registration failed. Please try again.',
          code: 'AUTH_ERROR',
        );
      }

      // Step 2: Create user profile with referral
      await _supabaseService.registerUserWithReferral(
        id: response.user!.id,
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        referredCode: referredCode,
      );

      // Success: Update state with user data
      if (!mounted) return;
      state = state.copyWith(
        user: UserState.fromUser(response.user!),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      AppError error;
      
      if (e is AuthException) {
        error = AuthError.fromSupabase(e);
      } else if (e is AppError) {
        error = e;
      } else {
        error = AuthError(
          message: 'An unexpected error occurred during registration',
          code: 'UNKNOWN_ERROR',
          originalError: e,
        );
      }
      
      state = state.copyWith(
        error: error.message,
        isLoading: false,
      );
      rethrow;
    }
  }

  // Login
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Update last login timestamp
        await _supabaseService.updateLastLogin(response.user!.id);
        
        state = state.copyWith(
          user: UserState.fromUser(response.user!),
          isLoading: false,
        );
      } else {
        throw AuthError(
          message: 'Login failed. Please try again.',
          code: 'AUTH_ERROR',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.signOut();
      if (!mounted) return;
      state = const AppAuthState();
    } catch (e) {
      if (!mounted) return;
      AppError error;
      
      if (e is AuthException) {
        error = AuthError.fromSupabase(e);
      } else if (e is AppError) {
        error = e;
      } else {
        error = AuthError(
          message: 'An unexpected error occurred during sign out',
          code: 'UNKNOWN_ERROR',
          originalError: e,
        );
      }
      
      state = state.copyWith(
        error: error.message,
        isLoading: false,
      );
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.resetPassword(email);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      AppError error;
      
      if (e is AuthException) {
        error = AuthError.fromSupabase(e);
      } else if (e is AppError) {
        error = e;
      } else {
        error = AuthError(
          message: 'An unexpected error occurred during password reset',
          code: 'UNKNOWN_ERROR',
          originalError: e,
        );
      }
      
      state = state.copyWith(
        error: error.message,
        isLoading: false,
      );
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.updatePassword(newPassword);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      if (!mounted) return;
      AppError error;
      
      if (e is AuthException) {
        error = AuthError.fromSupabase(e);
      } else if (e is AppError) {
        error = e;
      } else {
        error = AuthError(
          message: 'An unexpected error occurred during password update',
          code: 'UNKNOWN_ERROR',
          originalError: e,
        );
      }
      
      state = state.copyWith(
        error: error.message,
        isLoading: false,
      );
      rethrow;
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthProvider, AppAuthState>((ref) {
  return AuthProvider(ref.watch(supabaseServiceProvider));
});