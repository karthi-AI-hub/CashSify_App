import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../core/widgets/layout/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    final showPassword = useState(false);
    final showConfirmPassword = useState(false);

    void showSnackBar(String message, {bool success = true}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.surface),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorScheme.primary,
        ),
      );
    }

    Future<void> handleChangePassword() async {
      if (!formKey.currentState!.validate()) return;
      isLoading = true;
      try {
        await ref.read(userServiceProvider).supabase.updatePassword(passwordController.text);
        showSnackBar('Password updated successfully!');
        context.pop();
      } catch (e) {
        showSnackBar('Failed to update password', success: false);
      } finally {
        isLoading = false;
      }
    }

    return WillPopScope(
      onWillPop: () async {
        context.go('/profile');
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Change Password',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CustomCard(
              child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Enter your new password', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !showPassword.value,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword.value ? Icons.visibility : Icons.visibility_off,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => showPassword.value = !showPassword.value,
                          ),
                        ),
                        validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword.value,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword.value ? Icons.visibility : Icons.visibility_off,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => showConfirmPassword.value = !showConfirmPassword.value,
                          ),
                        ),
                        validator: (val) => val != passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleChangePassword,
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Change Password'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 