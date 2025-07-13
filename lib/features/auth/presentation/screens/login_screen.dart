import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  static String? _staticErrorMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = _staticErrorMessage;
  }

  @override
  void dispose() {
    _staticErrorMessage = _errorMessage;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user == null) {
        throw AuthException('Invalid login credentials', code: 'invalid_credentials');
      }
      if (response.user!.emailConfirmedAt == null) {
        setState(() {
          _errorMessage = 'Please verify your email before logging in.';
          _isLoading = false;
        });
        _staticErrorMessage = _errorMessage;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return _VerifyEmailGuide(
              email: _emailController.text.trim(),
              onResend: () async {
                try {
                  await UserService().resendVerificationEmail(_emailController.text.trim());
                  if (context.mounted) {
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
                } catch (e) {
                  if (context.mounted) {
                    final colorScheme = Theme.of(context).colorScheme;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: colorScheme.surface),
                            SizedBox(width: 12),
                            Text('Failed to resend email: $e'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  }
                }
              },
            );
          },
        );
        return;
      }
      if (mounted) {
        _staticErrorMessage = null;
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      print('LOGIN ERROR: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Invalid email or password';
          _isLoading = false;
        });
        _staticErrorMessage = _errorMessage;
        if ((e.message?.toLowerCase().contains('email not confirmed') ?? false) ||
            (e.message?.toLowerCase().contains('confirm your email') ?? false)) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return _VerifyEmailGuide(
                email: _emailController.text.trim(),
                onResend: () async {
                  try {
                    await UserService().resendVerificationEmail(_emailController.text.trim());
                    if (context.mounted) {
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
                  } catch (e) {
                    if (context.mounted) {
                      final colorScheme = Theme.of(context).colorScheme;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: colorScheme.surface),
                              SizedBox(width: 12),
                              Text('Failed to resend email: $e'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        }
      }
    } catch (e) {
      print('LOGIN ERROR: ${e.toString()}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
        _staticErrorMessage = _errorMessage;
      }
    }
  }

  void _showForgotEmailDialog(BuildContext context) {
    final phoneController = TextEditingController();
    String? resultEmail;
    String? errorMessage;
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Find Your Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (resultEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Your email: $resultEmail',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : resultEmail == null
                          ? () async {
                              setState(() {
                                isSubmitting = true;
                                errorMessage = null;
                                resultEmail = null;
                              });
                              final phone = phoneController.text.trim();
                              if (phone.isEmpty) {
                                setState(() {
                                  errorMessage = 'Please enter your phone number.';
                                  isSubmitting = false;
                                });
                                return;
                              }
                              try {
                                final response = await Supabase.instance.client
                                    .from('users')
                                    .select('email')
                                    .eq('phone_number', phone)
                                    .maybeSingle();
                                if (response != null && response['email'] != null) {
                                  setState(() {
                                    resultEmail = response['email'] as String;
                                    errorMessage = null;
                                    isSubmitting = false;
                                  });
                                } else {
                                  setState(() {
                                    errorMessage = 'No account found for this phone number.';
                                    resultEmail = null;
                                    isSubmitting = false;
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  errorMessage = 'Error: ${e.toString()}';
                                  resultEmail = null;
                                  isSubmitting = false;
                                });
                              }
                            }
                          : () async {
                              if (resultEmail != null) {
                                await Clipboard.setData(ClipboardData(text: resultEmail!));
                                if (context.mounted) {
                                  final colorScheme = Theme.of(context).colorScheme;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: colorScheme.surface),
                                          SizedBox(width: 12),
                                          Text('Email copied to clipboard!'),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: colorScheme.primary,
                                    ),
                                  );
                                }
                              }
                            },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : resultEmail == null
                          ? const Text('Find Email')
                          : const Text('Copy Email'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/logo/logo.jpg',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                AnimatedFormField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  index: 0,
                  totalFields: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AnimatedFormField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  index: 1,
                  totalFields: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => context.push('/auth/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => _showForgotEmailDialog(context),
                      child: const Text('Forgot Email?'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedButton(
                  text: 'Login',
                  onPressed: _isLoading ? () {} : () => _handleLogin(),
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () => context.push('/auth/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifyEmailGuide extends StatelessWidget {
  final String email;
  final Future<void> Function() onResend;
  const _VerifyEmailGuide({required this.email, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(
            child: Icon(Icons.email_rounded, size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('How to Verify Your Email', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          _StepTile(
            step: 1,
            text: 'Tap the button below to resend the verification email to:',
            subText: email,
            icon: Icons.send_rounded,
          ),
          _StepTile(
            step: 2,
            text: 'Check your inbox (and spam folder) for an email from CashSify.',
            icon: Icons.inbox_rounded,
          ),
          _StepTile(
            step: 3,
            text: 'Click the verification link in the email to confirm your account.',
            icon: Icons.link_rounded,
          ),
          _StepTile(
            step: 4,
            text: 'Return to the app and refresh this screen.',
            icon: Icons.refresh_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: onResend,
                  label: const Text('Resend Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // const SizedBox(width: 12),
              // Expanded(
              //   child: ElevatedButton.icon(
              //     icon: const Icon(Icons.mail_outline_rounded),
              //     onPressed: () async {
              //       ...
              //     },
              //     label: const Text('Open Mail App'),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: colorScheme.secondary,
              //       foregroundColor: colorScheme.onSecondary,
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       textStyle: const TextStyle(fontWeight: FontWeight.bold),
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final String text;
  final String? subText;
  final IconData icon;
  const _StepTile({required this.step, required this.text, this.subText, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text('$step', style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: textTheme.bodyLarge),
                if (subText != null)
                  Text(subText!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 