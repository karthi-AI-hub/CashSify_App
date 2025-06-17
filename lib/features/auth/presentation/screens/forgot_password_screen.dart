import 'package:flutter/material.dart';
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
import 'package:cashsify_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_page_transition.dart';
import 'package:cashsify_app/features/auth/presentation/screens/login_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

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
        Navigator.of(context).pop();
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
    print("Entered in _handleLoginNavigation");
    if (!mounted) return;
    
    // Clear fields and errors before navigation
    _emailController.clear();
    ref.read(errorProvider.notifier).clearError();
    
    print("Before navigation");
    // Navigate back to login screen
    Navigator.of(context).pop();
    print("After navigation");
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider) == LoadingState.loading;
    final error = ref.watch(errorProvider);
    final theme = Theme.of(context);

    return AuthLayout(
      title: 'Reset Password',
      isLoading: isLoading,
      errorMessage: error.message,
      onBack: null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo or App Name
            Center(
              child: Image.asset(
                'assets/logo/logo.jpg',
                height: 100, // Adjust height as needed
              ),
            ),
            const SizedBox(height: 32),

            // Description
            Text(
              'Enter your email address and we\'ll send you instructions to reset your password.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email Field
            AnimatedFormField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              index: 0,
              totalFields: 1,
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
            const SizedBox(height: 32),

            // Reset Button
            AnimatedButton(
              text: 'Send Reset Instructions',
              onPressed: _handleResetPassword,
              isLoading: isLoading,
            ),
            const SizedBox(height: 24),

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
    );
  }
} 