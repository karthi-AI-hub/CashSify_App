import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Check if phone number already exists
      final phoneNumber = _phoneController.text.trim();
      final existing = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('phone_number', phoneNumber)
          .maybeSingle();
      if (existing != null && existing['id'] != null) {
        setState(() {
          _errorMessage = 'Phone number already exists. Try to login.';
          _isLoading = false;
        });
        return;
      }
      // Step 1: Create auth account
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'display_name': _nameController.text.trim(),
        },
      );
      if (response.user == null) {
        throw AuthException('Registration failed. Please try again.');
      }
      // Step 2: Register user profile with referral logic
      final referralCode = _referralCodeController.text.trim().isEmpty
          ? null
          : _referralCodeController.text.trim();
      final generatedReferralCode = _generateReferralCode(phoneNumber);
      await Supabase.instance.client.rpc(
        'register_user_with_referral',
        params: {
          'p_id': response.user!.id,
          'p_email': _emailController.text.trim(),
          'p_password': _passwordController.text,
          'p_name': _nameController.text.trim(),
          'p_phone_number': phoneNumber,
          'p_referral_code': generatedReferralCode,
          'p_referred_code': referralCode,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/auth/login');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please check your details.';
        _isLoading = false;
      });
    }
  }

  String _generateReferralCode(String phoneNumber) {
    final lastFourDigits = phoneNumber.length >= 4 ? phoneNumber.substring(phoneNumber.length - 4) : phoneNumber;
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final randomThreeDigits = (100 + random % 900).toString();
    return 'REF$lastFourDigits$randomThreeDigits';
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
                if (_errorMessage != null)
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
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
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
                AnimatedFormField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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
                AnimatedFormField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
                AnimatedFormField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedFormField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedFormField(
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code if you have one',
                  controller: _referralCodeController,
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
                AnimatedButton(
                  text: 'Create Account',
                  onPressed: _isLoading ? () {} : () => _handleRegister(),
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.pop(),
                      child: const Text('Login'),
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