import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:cashsify_app/core/widgets/custom_button.dart';
import 'package:cashsify_app/core/widgets/custom_text_field.dart';
import 'package:cashsify_app/core/widgets/loading_overlay.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/providers/error_provider.dart';
import 'package:cashsify_app/core/mixins/performance_mixin.dart';
import 'package:cashsify_app/core/providers/supabase_provider.dart';
import 'package:cashsify_app/core/error/app_error.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ref.read(loadingProvider.notifier).startLoading();

      final supabaseService = ref.read(supabaseServiceProvider);

      // Sign up with Supabase Auth
      final authResponse = await supabaseService.signUpWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (authResponse.user == null) {
        throw AuthError(
          message: 'Failed to create user account. Please try again.',
          code: 'AUTH_ERROR',
        );
      }

      // Register user profile with referral
      await supabaseService.registerUserWithReferral(
        id: authResponse.user!.id,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        referredCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
      );

      // Update last login
      await supabaseService.updateLastLogin(authResponse.user!.id);

      if (mounted) {
        ref.read(loadingProvider.notifier).finishLoading();
        context.go('/home');
      }
    } on AuthError catch (e) {
      if (mounted) {
        ref.read(loadingProvider.notifier).setError();
        ref.read(errorProvider.notifier).setError(
          e.message,
          code: e.code,
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ref.read(loadingProvider.notifier).setError();
        ref.read(errorProvider.notifier).setError(
          'Failed to create user profile. Please try again.',
          code: 'DB_ERROR',
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(loadingProvider.notifier).setError();
        ref.read(errorProvider.notifier).setError(
          'An unexpected error occurred. Please try again.',
          code: 'UNKNOWN_ERROR',
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
        title: const Text('Register'),
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
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code if you have one',
                  controller: _referralCodeController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final code = value.trim().toUpperCase();
                      if (!code.startsWith('REF')) {
                        return 'Referral code must start with REF';
                      }
                      if (code.length != 9) { // REF + 6 characters
                        return 'Referral code must be 9 characters';
                      }
                      if (!RegExp(r'^REF[A-Z0-9]{6}$').hasMatch(code)) {
                        return 'Invalid referral code format';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Register',
                  onPressed: _handleRegister,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.go('/auth/login');
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 