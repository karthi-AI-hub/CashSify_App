import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:cashsify_app/core/widgets/custom_button.dart';
import 'package:cashsify_app/core/widgets/custom_text_field.dart';
import 'package:cashsify_app/core/widgets/loading_overlay.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'package:cashsify_app/core/providers/supabase_provider.dart';
import 'package:cashsify_app/core/error/app_error.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ref.read(loadingProvider.notifier).startLoading();

      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.resetPassword(_emailController.text.trim());

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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider) == LoadingState.loading;
    final error = ref.watch(errorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error.message != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Reset Password',
                  onPressed: _handleResetPassword,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.go('/auth/login');
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 