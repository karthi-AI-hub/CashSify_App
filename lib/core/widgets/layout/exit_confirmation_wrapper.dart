import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/app_state_provider.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_dialog.dart';
import 'package:cashsify_app/theme/app_spacing.dart';

/// A reusable widget that wraps any screen with exit confirmation functionality.
/// This eliminates code duplication and provides centralized exit behavior.
class ExitConfirmationWrapper extends ConsumerWidget {
  final Widget child;
  final int screenIndex;
  final String screenTitle;
  final bool showNotifications;
  final bool showBonus;

  const ExitConfirmationWrapper({
    super.key,
    required this.child,
    required this.screenIndex,
    required this.screenTitle,
    this.showNotifications = false,
    this.showBonus = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context, ref),
      child: child,
    );
  }

  Future<bool> _onWillPop(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userState = ref.read(userProvider);
    
    // Show confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: 'Exit App',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Do you want to save your current progress and exit the app?',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your data will be saved locally and restored when you return.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      try {
        // Get current user data
        final user = userState.value;
        if (user != null) {
          // Save app state
          await ref.read(appStateProvider.notifier).saveAppState(
            currentIndex: screenIndex,
            title: screenTitle,
            userData: {
              'id': user.id,
              'email': user.email,
              'name': user.name,
              'coins': user.coins,
              'referralCode': user.referralCode,
              'referralCount': user.referralCount,
              'isEmailVerified': user.isEmailVerified,
              'lastLogin': user.lastLogin?.toIso8601String(),
              'createdAt': user.createdAt.toIso8601String(),
            },
            showNotifications: showNotifications,
            showBonus: showBonus,
          );

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'App state saved successfully!',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
                backgroundColor: colorScheme.primary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        // Exit the app
        SystemNavigator.pop();
      } catch (e) {
        // If saving fails, still exit but show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save state, but exiting app: ${e.toString()}',
                style: TextStyle(color: colorScheme.onPrimary),
              ),
              backgroundColor: colorScheme.error,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        // Still exit the app
        SystemNavigator.pop();
      }
    }

    return false; // Prevent default back behavior
  }
} 