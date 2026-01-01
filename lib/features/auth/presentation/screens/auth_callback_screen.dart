import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:async';
import 'package:cashsify_app/core/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final Map<String, String> queryParams;
  const AuthCallbackScreen({super.key, required this.queryParams});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _checking = true;
  bool _success = false;
  String? _error;
  String? _type;
  bool _resending = false;
  bool _resent = false;
  bool _navigated = false;

  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCallback();
  }

  Future<void> _initializeCallback() async {
    // Use the parameters passed from the router (which now includes both query and fragment)
    final params = widget.queryParams;
    _type = params['type'];

    // Debug logging to see what parameters we receive
    AppLogger.info('AuthCallback received parameters: $params');
    AppLogger.info('AuthCallback type: $_type');

    // Check if this is a password reset callback by looking at stored preferences
    final prefs = await SharedPreferences.getInstance();
    final isPasswordResetFlow = prefs.getBool('password_reset_flow') ?? false;

    if (isPasswordResetFlow) {
      AppLogger.info('Detected password reset flow from preferences');
      _type = 'recovery'; // Override type for password reset
      // Clear the flag since we're now handling the reset
      await prefs.remove('password_reset_flow');
    }

    // Handle Supabase error cases first
    if (params['error'] != null) {
      final errorCode = params['error'];
      final errorDescription = params['error_description'];
      final errorCodeParam =
          params['error_code']; // Additional error code parameter

      AppLogger.warning(
          'AuthCallback error detected - Code: $errorCode, Description: $errorDescription, ErrorCode: $errorCodeParam');

      setState(() {
        _checking = false;
        // Provide user-friendly error messages based on specific error types
        if (errorCode == 'access_denied' && errorCodeParam == 'otp_expired') {
          _error = 'This email link has expired. Please request a new one.';
        } else if (errorCode == 'access_denied' &&
            errorDescription?.contains('expired') == true) {
          _error = 'This email link has expired. Please request a new one.';
        } else if (errorCode == 'access_denied') {
          _error =
              'Email verification was cancelled or failed. Please try again.';
        } else if (errorDescription?.isNotEmpty == true) {
          _error = errorDescription!;
        } else {
          _error = 'An authentication error occurred. Please try again.';
        }
      });
    } else {
      _handleCallback(params);
    }
  }

  Future<void> _handleCallback(Map<String, String> params) async {
    if (_type == 'signup' || _type == 'magiclink') {
      try {
        await Supabase.instance.client.auth
            .refreshSession()
            .timeout(const Duration(seconds: 30));
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          setState(() {
            _checking = false;
            _error = 'Session expired. Please try the link again.';
          });
          return;
        }
        setState(() {
          _checking = false;
          _success = user.emailConfirmedAt != null;
        });
        if (_success && mounted && !_navigated) {
          _navigated = true;
          try {
            // Update email verification status in database
            await UserService().checkAndUpdateEmailVerified();

            if (mounted) {
              final colorScheme = Theme.of(context).colorScheme;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.surface),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Email verified successfully!'),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colorScheme.primary,
                ),
              );
            }

            // Give user time to see the success message
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _navigated) {
                context.go('/dashboard');
              }
            });
          } catch (e) {
            // Even if database update fails, still redirect (user is verified in auth)
            AppLogger.warning('Failed to update email verification status: $e');
            if (mounted && _navigated) {
              context.go('/dashboard');
            }
          }
        }
      } on TimeoutException {
        AppLogger.warning('Email verification timed out');
        setState(() {
          _checking = false;
          _error =
              'Email verification timed out. Please check your connection and try again.';
        });
      } catch (e) {
        AppLogger.error('Email verification failed: $e');
        setState(() {
          _checking = false;
          if (e.toString().contains('expired')) {
            _error = 'This email link has expired. Please request a new one.';
          } else if (e.toString().contains('AuthException')) {
            _error =
                'Authentication failed. Please try again or request a new verification email.';
          } else {
            _error = 'Failed to verify email. Please try again.';
          }
        });
      }
    } else if (_type == 'recovery') {
      // Handle password recovery - navigate directly to reset password screen
      // Supabase should have already processed the session from the callback URL
      try {
        setState(() {
          _checking = true;
        });

        AppLogger.info(
            'Processing password recovery callback, navigating to reset password screen');

        // Navigate to password reset screen immediately
        // The router now allows authenticated users to access the reset password screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/auth/reset-password');
          }
        });
      } catch (e) {
        AppLogger.error('Password recovery error: $e');
        setState(() {
          _checking = false;
          _error = 'Password reset link expired. Please request a new one.';
        });
      }
    } else {
      setState(() {
        _checking = false;
        _error = 'Unknown or unsupported callback type.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() => _checking = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      setState(() {
        _checking = false;
        _success = true;
        _error = null;
      });
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.surface),
                SizedBox(width: 12),
                Text('Password updated! Please log in.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.primary,
          ),
        );
        GoRouter.of(context).go('/auth/login');
      }
    } catch (e) {
      setState(() {
        _checking = false;
        _error = 'Failed to update password: ${e.toString()}';
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _resent = false;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        if (_type == 'signup') {
          await Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: user.email!,
          );
        } else if (_type == 'magiclink') {
          await Supabase.instance.client.auth.resend(
            type: OtpType.magiclink,
            email: user.email!,
          );
        }
        setState(() {
          _resent = true;
        });
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.surface),
                  SizedBox(width: 12),
                  Text('Verification email resent!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to resend email: ${e.toString()}';
      });
    } finally {
      setState(() {
        _resending = false;
      });
    }
  }

  void _clearErrorsAndNavigate(String route) {
    ref.read(errorProvider.notifier).clearError();
    GoRouter.of(context).go(route);
  }

  @override
  void dispose() {
    _navigated = false;
    _passwordController.dispose();
    ref.read(errorProvider.notifier).clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Error state
    if (_error != null) {
      final isExpiredLink = _error!.contains('expired');
      return Scaffold(
        appBar: AppBar(title: const Text('Callback Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isExpiredLink ? Icons.access_time : Icons.error_outline,
                    color: isExpiredLink ? Colors.orange : Colors.red,
                    size: 64),
                const SizedBox(height: 16),
                Text(_error!,
                    style: TextStyle(
                        color: isExpiredLink ? Colors.orange : Colors.red,
                        fontSize: 18),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (isExpiredLink && _type == 'recovery') ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        _clearErrorsAndNavigate('/auth/forgot-password'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Request New Reset Link'),
                  ),
                  const SizedBox(height: 12),
                ] else if (isExpiredLink &&
                    (_type == 'signup' || _type == 'magiclink')) ...[
                  ElevatedButton.icon(
                    onPressed: () => _clearErrorsAndNavigate('/auth/register'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Request New Verification Email'),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: () => _clearErrorsAndNavigate('/auth/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Email verification
    if (_type == 'signup' || _type == 'magiclink') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _success
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 64)
                    : const Icon(Icons.mark_email_unread,
                        color: Colors.orange, size: 64),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _success
                    ? const Text('Email verified! Redirecting...')
                    : const Text('Email not yet verified. Please try again.'),
              ),
              const SizedBox(height: 8),
              if (_resent)
                const Text('Email resent! Check your inbox.',
                    style: TextStyle(color: Colors.green)),
              const SizedBox(height: 24),
              if (!_success)
                ElevatedButton.icon(
                  onPressed: _resending ? null : _resendEmail,
                  icon: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_resending ? 'Resending...' : 'Resend Email'),
                ),
              TextButton(
                onPressed: () => _clearErrorsAndNavigate('/auth/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    } else if (_type == 'recovery') {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enter your new password:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resetPassword,
                  child: const Text('Set New Password'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => _clearErrorsAndNavigate('/auth/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Fallback for unknown callback types
      return Scaffold(
        appBar: AppBar(title: const Text('Callback')),
        body: Center(
          child: Text('Unknown callback. Please try again.',
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  }
}
