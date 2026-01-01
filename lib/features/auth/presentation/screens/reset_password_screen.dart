import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/layout/custom_app_bar.dart';
import '../../../../core/widgets/form/custom_button.dart';
import '../widgets/animated_form_field.dart';

class ResetPasswordScreen extends HookConsumerWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();

    final isLoading = useState<bool>(false);
    final showPassword = useState<bool>(false);
    final showConfirmPassword = useState<bool>(false);
    final errorMessage = useState<String?>(null);

    // Check if user has a valid session for password reset
    useEffect(() {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        errorMessage.value =
            'No active session. Please request a new password reset link.';
      }
      return null;
    }, []);

    Future<void> _resetPassword() async {
      if (!formKey.currentState!.validate()) return;

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'Passwords do not match';
        return;
      }

      // Check if we still have a valid session
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        errorMessage.value =
            'Session expired. Please request a new password reset link.';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: passwordController.text),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.surface),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Password updated successfully!'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );

          await Supabase.instance.client.auth.signOut();

          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) {
              context.go('/auth/login');
            }
          });
        }
      } catch (e) {
        AppLogger.error('Password reset failed: $e');
        errorMessage.value = 'Failed to update password. Please try again.';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Sign out user when going back to allow proper login flow
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              context.go('/auth/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.lock_reset,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create New Password',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be different from your previous password.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (errorMessage.value != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage.value!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                AnimatedFormField(
                  label: 'New Password',
                  hint: 'Enter your new password',
                  controller: passwordController,
                  obscureText: !showPassword.value,
                  index: 0,
                  totalFields: 2,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => showPassword.value = !showPassword.value,
                    icon: Icon(
                      showPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AnimatedFormField(
                  label: 'Confirm New Password',
                  hint: 'Confirm your new password',
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword.value,
                  index: 1,
                  totalFields: 2,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        showConfirmPassword.value = !showConfirmPassword.value,
                    icon: Icon(
                      showConfirmPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Update Password',
                  onPressed: isLoading.value ? null : _resetPassword,
                  isLoading: isLoading.value,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    // Sign out user to allow proper login flow
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      context.go('/auth/login');
                    }
                  },
                  child: Text(
                    'Back to Login',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
