import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track if the user is currently in a password reset flow
/// This helps prevent automatic dashboard redirects during password reset
class PasswordResetNotifier extends StateNotifier<bool> {
  PasswordResetNotifier() : super(false) {
    _initializeState();
  }

  /// Initialize state from SharedPreferences
  Future<void> _initializeState() async {
    final prefs = await SharedPreferences.getInstance();
    final isPasswordReset = prefs.getBool('password_reset_flow') ?? false;
    state = isPasswordReset;
  }

  /// Set the password reset mode
  Future<void> setPasswordResetMode(bool isPasswordReset) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPasswordReset) {
      await prefs.setBool('password_reset_flow', true);
    } else {
      await prefs.remove('password_reset_flow');
    }
    state = isPasswordReset;
  }

  /// Clear the password reset mode
  Future<void> clearPasswordResetMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password_reset_flow');
    state = false;
  }

  /// Check if currently in password reset mode (from SharedPreferences)
  Future<bool> isPasswordResetMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('password_reset_flow') ?? false;
  }
}

final passwordResetProvider =
    StateNotifierProvider<PasswordResetNotifier, bool>(
  (ref) => PasswordResetNotifier(),
);
