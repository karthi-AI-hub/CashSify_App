import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'dart:async';
import 'package:cashsify_app/core/services/user_service.dart';

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
    // Merge query and fragment parameters for robust handling
    final mergedParams = <String, String>{};
    mergedParams.addAll(widget.queryParams);
    // If fragment contains params, parse and merge
    final fragment = Uri.base.fragment;
    if (fragment.isNotEmpty) {
      try {
        mergedParams.addAll(Uri.splitQueryString(fragment));
      } catch (_) {}
    }
    _type = mergedParams['type'];
    // Handle Supabase error cases
    if (mergedParams['error'] != null) {
      setState(() {
        _checking = false;
        _error = mergedParams['error_description'] ?? 'An unknown error occurred.';
      });
    } else {
      _handleCallback(mergedParams);
    }
  }

  Future<void> _handleCallback(Map<String, String> params) async {
    if (_type == 'signup' || _type == 'magiclink') {
      try {
        await Supabase.instance.client.auth.refreshSession()
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
          await UserService().checkAndUpdateEmailVerified();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _navigated) {
              context.go('/dashboard');
            }
          });
        }
      } on TimeoutException {
        setState(() {
          _checking = false;
          _error = 'Verification timed out. Please try again.';
        });
      } catch (e) {
        setState(() {
          _checking = false;
          _error = 'Failed to verify email. Please try again.';
        });
      }
    } else if (_type == 'recovery') {
      setState(() {
        _checking = false;
        _success = false;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated! Please log in.')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email resent!')),
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
      return Scaffold(
        appBar: AppBar(title: const Text('Callback Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 24),
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
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 64)
                    : const Icon(Icons.mark_email_unread, color: Colors.orange, size: 64),
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
                const Text('Email resent! Check your inbox.', style: TextStyle(color: Colors.green)),
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
          child: Text('Unknown callback. Please try again.', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  }
}
