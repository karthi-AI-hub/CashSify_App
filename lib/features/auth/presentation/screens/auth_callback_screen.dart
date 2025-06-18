import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';

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

  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.queryParams['type'];
    _handleCallback();
    // TODO: Add analytics/logging here if needed
  }

  Future<void> _handleCallback() async {
    if (_type == 'signup' || _type == 'magiclink') {
      try {
        await Supabase.instance.client.auth.refreshSession();
        final user = Supabase.instance.client.auth.currentUser;
        
        setState(() {
          _checking = false;
          _success = user != null && user.emailConfirmedAt != null;
        });

        if (_success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) context.go('/dashboard');
            });
          }
        }
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
        _error = 'Unknown callback type.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final accessToken = widget.queryParams['access_token'];
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
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
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
              if (_resent)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Email resent! Check your inbox.', style: TextStyle(color: Colors.green)),
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
      return Scaffold(
        body: Center(
          child: Text(_error ?? 'Unknown callback.'),
        ),
      );
    }
  }
}
