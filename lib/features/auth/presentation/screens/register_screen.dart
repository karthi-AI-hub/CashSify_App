import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/providers/providers.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final refCode = prefs.getString('pending_referral_code');
    if (refCode != null && refCode.isNotEmpty) {
      _referralCodeController.text = refCode;
    }
  }

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

  void _clearFieldsAndErrors() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _referralCodeController.clear();
    ref.read(errorProvider.notifier).clearError();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ref.read(loadingProvider.notifier).startLoading();

      // Use the centralized auth provider
      await ref.read(authProvider.notifier).registerWithReferral(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        referredCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
      );

      // Success: show message and redirect
      if (mounted) {
        ref.read(loadingProvider.notifier).finishLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
          ),
        );
        _clearFieldsAndErrors();
        // Clear referral code after use
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_referral_code');
        await ref.read(authProvider.notifier).signOut();
        context.go('/auth/login');
      }
    } catch (error) {
      if (mounted) {
        ref.read(loadingProvider.notifier).finishLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    _clearFieldsAndErrors();
    context.pop();
  }

  Future<bool> _handleBackButton() async {
    _navigateToLogin();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider) == LoadingState.loading;
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: AuthLayout(
        title: 'Create Account',
        isLoading: isLoading,
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

              // Name Field
              AnimatedFormField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline),
                index: 0,
                totalFields: 6,
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

              // Email Field
              AnimatedFormField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                index: 1,
                totalFields: 6,
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

              // Phone Field
              AnimatedFormField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                index: 2,
                totalFields: 6,
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

              // Password Field
              AnimatedFormField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                index: 3,
                totalFields: 6,
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
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              AnimatedFormField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                index: 4,
                totalFields: 6,
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
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Referral Code Field
              AnimatedFormField(
                label: 'Referral Code (Optional)',
                hint: 'Enter referral code if you have one',
                controller: _referralCodeController,
                prefixIcon: const Icon(Icons.card_giftcard_outlined),
                index: 5,
                totalFields: 6,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final code = value.trim().toUpperCase();
                    if (!code.startsWith('REF')) {
                      return 'Referral code must start with REF';
                    }
                    if (code.length != 10 && code.length != 11) {
                      return 'Referral code must be 10 characters';
                    }
                    if (!RegExp(r'^REF[A-Z0-9]{7,8}$').hasMatch(code)) {
                      return 'Invalid referral code format';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Register Button
              AnimatedButton(
                text: 'Create Account',
                onPressed: _handleRegister,
                isLoading: isLoading,
              ),
              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 