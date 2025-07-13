import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/app_state_provider.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_dialog.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/core/utils/logger.dart';

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
    AppLogger.debug('ExitConfirmationWrapper: Building with screenIndex: $screenIndex, title: $screenTitle');
    
    return WillPopScope(
      onWillPop: () async {
        AppLogger.debug('ExitConfirmationWrapper: onWillPop called - Back button pressed!');
        AppLogger.debug('ExitConfirmationWrapper: Current route: ${ModalRoute.of(context)?.settings.name}');
        AppLogger.debug('ExitConfirmationWrapper: Can pop: ${Navigator.of(context).canPop()}');
        
        // Check if we can pop (go back to previous screen)
        if (Navigator.of(context).canPop()) {
          AppLogger.debug('ExitConfirmationWrapper: Can pop, allowing normal back navigation');
          return true; // Allow normal back navigation
        } else {
          AppLogger.debug('ExitConfirmationWrapper: Cannot pop, showing exit dialog');
          await _showExitDialog(context, ref);
          return false; // Prevent default back behavior
        }
      },
      child: child,
    );
  }

  Future<void> _showExitDialog(BuildContext context, WidgetRef ref) async {
    AppLogger.debug('ExitConfirmationWrapper: _showExitDialog called');
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userState = ref.read(userProvider);
    
    AppLogger.debug('ExitConfirmationWrapper: Showing exit confirmation dialog');
    
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
            onPressed: () {
              AppLogger.debug('ExitConfirmationWrapper: User cancelled exit');
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AppLogger.debug('ExitConfirmationWrapper: User confirmed exit');
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );

    AppLogger.debug('ExitConfirmationWrapper: Dialog result: $shouldExit');

    if (shouldExit == true) {
      await _exitApp(context, ref);
    } else {
      AppLogger.debug('ExitConfirmationWrapper: User cancelled exit, staying in app');
    }
  }

  Future<void> _exitApp(BuildContext context, WidgetRef ref) async {
    try {
      AppLogger.debug('ExitConfirmationWrapper: Saving app state before exit');
      
      final colorScheme = Theme.of(context).colorScheme;
      final userState = ref.read(userProvider);
      
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
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.surface),
                  SizedBox(width: 12),
                  Text('App state saved successfully!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.primary,
            ),
          );
        }
      }

      AppLogger.debug('ExitConfirmationWrapper: Exiting app with SystemNavigator.pop()');
      // Exit the app
      SystemNavigator.pop();
    } catch (e) {
      AppLogger.error('ExitConfirmationWrapper: Error saving state: $e');
      
      final colorScheme = Theme.of(context).colorScheme;
      
      // If saving fails, still exit but show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: colorScheme.error),
                SizedBox(width: 12),
                Text('Failed to save state, but exiting app: ${e.toString()}'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      }
      // Still exit the app
      SystemNavigator.pop();
    }
  }
} 