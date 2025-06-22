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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailReadOnly = false;

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

    try {
      ref.read(loadingProvider.notifier).startLoading();

      await ref.read(authProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        ref.read(loadingProvider.notifier).finishLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset instructions sent to your email'),
          ),
        );
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider.notifier).setError();
        ref.read(errorProvider.notifier).setError(
          e.toString(),
          code: e is AuthError ? e.code : 'UNKNOWN_ERROR',
        );
      }
    }
  }

  void _handleLoginNavigation() {
    if (!mounted) return;
    
    // Clear fields and errors before navigation
    _emailController.clear();
    ref.read(errorProvider.notifier).clearError();
    
    // Navigate back to login screen using context.go for consistency
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
    final isLoading = ref.watch(loadingProvider) == LoadingState.loading;
    final error = ref.watch(errorProvider);
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
                        if (error.message != null && error.message!.isNotEmpty)
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
                                    error.message!,
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
                          onPressed: _handleResetPassword,
                          isLoading: isLoading,
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
                              onPressed: _handleLoginNavigation,
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