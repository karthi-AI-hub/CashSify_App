import 'package:flutter/material.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/error/app_error.dart';

class AppUtils {
  static void showError(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  static void showInfo(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.info,
    );
  }

  static void showToast(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
  }) {
    CustomToast.show(
      context,
      message: message,
      type: type,
    );
  }

  static void showSuccessToast(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.success,
    );
  }

  static void showErrorToast(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.error,
    );
  }

  static void showInfoToast(BuildContext context, String message) {
    CustomToast.show(
      context,
      message: message,
      type: ToastType.info,
    );
  }

  static Future<T> handleAsyncOperation<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        showInfoToast(context, 'Loading...');
      }

      final result = await operation();

      if (successMessage != null && context.mounted) {
        showSuccessToast(context, successMessage);
      }

      return result;
    } on AuthError catch (e) {
      if (context.mounted) {
        showErrorToast(context, e.message);
      }
      rethrow;
    } on NetworkError catch (e) {
      if (context.mounted) {
        showErrorToast(context, e.message);
      }
      rethrow;
    } on DatabaseError catch (e) {
      if (context.mounted) {
        showErrorToast(context, e.message);
      }
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        errorMessage ?? 'An unexpected error occurred',
        e,
        stackTrace,
      );
      if (context.mounted) {
        showErrorToast(
          context,
          errorMessage ?? 'An unexpected error occurred',
        );
      }
      rethrow;
    }
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.error(message, error, stackTrace);
  }

  static void logInfo(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.info(message, error, stackTrace);
  }

  static void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.warning(message, error, stackTrace);
  }

  static void logDebug(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.debug(message, error, stackTrace);
  }

  /// Shows an exit confirmation dialog
  /// Returns true if user wants to exit, false if they want to stay
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
} 