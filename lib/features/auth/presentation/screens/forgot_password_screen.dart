import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'package:cashsify_app/core/providers/supabase_provider.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_page_transition.dart';
import 'package:cashsify_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailReadOnly = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Try to get email from user state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      final user = userState.value;
      if (user != null && user.email.isNotEmpty) {
        _emailController.text = user.email;
        setState(() {
          _isEmailReadOnly = true;
        });
      }
    });
  }

  void _clearFieldsAndErrors() {
    _emailController.clear();
    if (mounted) {
      ref.read(errorProvider.notifier).clearError();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.surface),
                SizedBox(width: 12),
                Text('Password reset email sent! Check your inbox.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.primary,
          ),
        );
        context.go('/auth/login');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Failed to send reset instructions.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send reset instructions.';
        _isLoading = false;
      });
    }
  }

  void _handleLoginNavigation() {
    if (!mounted) return;
    _emailController.clear();
    setState(() {
      _errorMessage = null;
    });
    context.go('/auth/login');
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    _emailController.clear();
    ref.read(errorProvider.notifier).clearError();
    context.pop();
  }

  Future<bool> _handleBackButton() async {
    _handleBackNavigation();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: CustomAppBar(
          title: 'Reset Password',
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Logo or App Name
                        Center(
                          child: Image.asset(
                            'assets/logo/logo.jpg',
                            height: 100,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Description
                        Text(
                          'Enter your email address and we\'ll send you instructions to reset your password.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Error message display
                        if (_errorMessage != null && _errorMessage!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ref.read(errorProvider.notifier).clearError();
                                  },
                                ),
                              ],
                            ),
                          ),

                        // Email Field
                        AnimatedFormField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          index: 0,
                          totalFields: 1,
                          readOnly: _isEmailReadOnly,
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
                        const SizedBox(height: AppSpacing.xl),

                        // Reset Button
                        AnimatedButton(
                          text: 'Send Reset Instructions',
                          onPressed: _isLoading ? () {} : () => _handleResetPassword(),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Back to Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remember your password?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _handleLoginNavigation,
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Powered By CashSify at bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Powered By CashSify',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 