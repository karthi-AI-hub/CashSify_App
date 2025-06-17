import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/providers/providers.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_form_field.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/animated_button.dart';
import 'package:cashsify_app/features/auth/presentation/widgets/auth_page_transition.dart';
import 'package:cashsify_app/features/auth/presentation/screens/register_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _clearFieldsAndErrors() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isLoading = false;
      });
      _emailController.clear();
      _passwordController.clear();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    _shakeController.forward(from: 0);
  }

  Future<void> _handleLogin() async {
    if (!mounted) return;
    
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authProvider.notifier).signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        _clearFieldsAndErrors();
      } catch (e) {
        if (!mounted) return;
        String errorMessage;
        
        if (e is AuthException) {
          switch (e.message) {
            case 'Invalid login credentials':
              errorMessage = 'Invalid email or password';
              break;
            case 'Email not confirmed':
              errorMessage = 'Please verify your email first';
              break;
            default:
              errorMessage = e.message;
          }
        } else if (e is AuthError) {
          errorMessage = e.message;
        } else {
          errorMessage = 'An unexpected error occurred';
        }
        
        print('Error message: $errorMessage');
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        _shakeController.forward(from: 0);
      }
    }
  }

  void _navigateToRegister() {
    _clearFieldsAndErrors();
    Navigator.of(context).push(
      AuthPageTransition(
        page: const RegisterScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    _clearFieldsAndErrors();
    Navigator.of(context).push(
      AuthPageTransition(
        page: const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthLayout(
      title: 'Welcome Back',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onErrorDismiss: () {
        setState(() {
          _errorMessage = null;
        });
      },
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
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

              // Email Field
              AnimatedFormField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                index: 0,
                totalFields: 2,
                hasError: _errorMessage != null,
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

              // Password Field
              AnimatedFormField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline),
                index: 1,
                totalFields: 2,
                hasError: _errorMessage != null,
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
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToForgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              AnimatedButton(
                text: 'Login',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _navigateToRegister,
                    child: const Text('Register'),
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