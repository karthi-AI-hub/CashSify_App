import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/layout/custom_app_bar.dart';

class DeleteAccountScreen extends HookConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    bool isLoading = false;

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

    Future<void> handleDeleteAccount() async {
      isLoading = true;
      try {
        await ref.read(userProvider.notifier).deleteAccount();
        // await ref.read(userProvider.notifier).signOut();
        showSnackBar('Account deleted. You have been signed out. Your account will be fully removed soon.');
        context.pop();
      } catch (e) {
        showSnackBar('Failed to delete account', success: false);
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
          title: 'Delete Account',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Are you sure you want to delete your account?', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Text('This action cannot be undone.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: isLoading ? null : () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
                          onPressed: isLoading ? null : handleDeleteAccount,
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 