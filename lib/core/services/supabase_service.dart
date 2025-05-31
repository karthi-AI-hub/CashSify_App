import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/error/app_error.dart';

/// A service class that handles all Supabase-related operations.
/// This class is implemented as a singleton to ensure a single instance
/// throughout the application.
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  
  // Factory constructor to return the singleton instance
  factory SupabaseService() => _instance;
  
  // Private constructor
  SupabaseService._internal();

  // Supabase client instance
  late final SupabaseClient _client;

  /// Initialize the Supabase client with the provided URL and anon key.
  /// This should be called before using any other methods.
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      AppLogger.info('Initializing Supabase client...');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      AppLogger.info('Supabase client initialized successfully');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize Supabase client',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get the current Supabase client instance.
  SupabaseClient get client => _client;

  /// Sign up a new user with email and password.
  /// Optionally accepts a referral code to be stored in user metadata.
  /// 
  /// Returns the [AuthResponse] containing the user session and any errors.
  /// Throws [AuthException] if the signup fails.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      AppLogger.info('Attempting to sign up user: $email');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // If signup is successful and referral code is provided, store it
      if (response.user != null && referralCode != null) {
        AppLogger.info('Storing referral code for user: ${response.user!.id}');
        await _client.from('user_metadata').upsert({
          'user_id': response.user!.id,
          'referral_code': referralCode,
        });
      }

      AppLogger.info('User signed up successfully: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      AppLogger.error('Sign up failed', e);
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign up', e, stackTrace);
      throw AuthError(
        message: 'An unexpected error occurred during sign up',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Sign in a user with email and password.
  /// 
  /// Returns the [AuthResponse] containing the user session and any errors.
  /// Throws [AuthException] if the sign in fails.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting to sign in user: $email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info('User signed in successfully: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      AppLogger.error('Sign in failed', e);
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign in', e, stackTrace);
      throw AuthError(
        message: 'An unexpected error occurred during sign in',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Sign out the current user.
  /// 
  /// Returns void if successful.
  /// Throws [AuthException] if the sign out fails.
  Future<void> signOut() async {
    try {
      AppLogger.info('Attempting to sign out user: ${currentUser?.id}');
      await _client.auth.signOut();
      AppLogger.info('User signed out successfully');
    } on AuthException catch (e) {
      AppLogger.error('Sign out failed', e);
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign out', e, stackTrace);
      throw AuthError(
        message: 'An unexpected error occurred during sign out',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Get the current user's information.
  /// 
  /// Returns the [User] object if a user is signed in, null otherwise.
  User? get currentUser => _client.auth.currentUser;

  /// Check if a user is currently signed in.
  /// 
  /// Returns true if a user is signed in, false otherwise.
  bool get isSignedIn => currentUser != null;

  /// Get the current user's session.
  /// 
  /// Returns the [Session] object if a user is signed in, null otherwise.
  Session? get currentSession => _client.auth.currentSession;

  /// Reset password for a given email address.
  /// 
  /// Returns void if successful.
  /// Throws [AuthException] if the password reset fails.
  Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('Attempting to reset password for: $email');
      await _client.auth.resetPasswordForEmail(email);
      AppLogger.info('Password reset email sent successfully');
    } on AuthException catch (e) {
      AppLogger.error('Password reset failed', e);
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during password reset', e, stackTrace);
      throw AuthError(
        message: 'An unexpected error occurred during password reset',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Update the current user's password.
  /// 
  /// Returns void if successful.
  /// Throws [AuthException] if the password update fails.
  Future<void> updatePassword(String newPassword) async {
    try {
      AppLogger.info('Attempting to update password for user: ${currentUser?.id}');
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLogger.info('Password updated successfully');
    } on AuthException catch (e) {
      AppLogger.error('Password update failed', e);
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during password update', e, stackTrace);
      throw AuthError(
        message: 'An unexpected error occurred during password update',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  // Generate referral code from phone number
  String generateReferralCode(String phoneNumber) {
    // Take last 6 digits of phone number and add a random 4-digit suffix
    final lastSixDigits = phoneNumber.substring(phoneNumber.length - 6);
    final randomSuffix = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'REF$lastSixDigits$randomSuffix';
  }

  // Register user with Supabase Auth
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('Attempting to sign up user: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (response.user == null) {
        throw AuthError(message: 'Failed to create user account', code: 'AUTH_ERROR');
      }

      AppLogger.info('Successfully signed up user: ${response.user?.id}');
      return response;
    } catch (e) {
      AppLogger.error('Error signing up user: $e');
      throw AuthError(message: e.toString(), code: 'AUTH_ERROR');
    }
  }

  // Register user profile with referral logic
  Future<void> registerUserWithReferral({
    required String id,
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? referredCode,
  }) async {
    try {
      AppLogger.info('Attempting to register user profile: $id');

      final referralCode = generateReferralCode(phoneNumber);

      final response = await _client.rpc(
        'register_user_with_referral',
        params: {
          'id': id,
          'email': email,
          'password': password,
          'name': name,
          'phone_number': phoneNumber,
          'referral_code': referralCode,
          'referred_code': referredCode,
        },
      );

      if (response == null) {
        throw AuthError(message: 'Failed to create user profile', code: 'RPC_ERROR');
      }

      AppLogger.info('Successfully registered user profile: $id');
    } catch (e) {
      AppLogger.error('Error registering user profile: $e');
      throw AuthError(message: e.toString(), code: 'RPC_ERROR');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      AppLogger.info('Fetching user profile: $userId');

      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      AppLogger.info('Successfully fetched user profile: $userId');
      return response;
    } catch (e) {
      AppLogger.error('Error fetching user profile: $e');
      throw AuthError(message: e.toString(), code: 'PROFILE_ERROR');
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      AppLogger.info('Updating last login for user: $userId');

      await _client
          .from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', userId);

      AppLogger.info('Successfully updated last login: $userId');
    } catch (e) {
      AppLogger.error('Error updating last login: $e');
      throw AuthError(message: e.toString(), code: 'UPDATE_ERROR');
    }
  }
} 