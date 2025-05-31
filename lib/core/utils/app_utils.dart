import 'package:flutter/material.dart';
import 'package:cashsify_app/core/widgets/custom_toast.dart';
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

  static void showToast({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomToast.show(
      context,
      message: message,
      type: type,
      duration: duration,
    );
  }

  static void showSuccessToast(BuildContext context, String message) {
    showToast(
      context: context,
      message: message,
      type: ToastType.success,
    );
  }

  static void showErrorToast(BuildContext context, String message) {
    showToast(
      context: context,
      message: message,
      type: ToastType.error,
    );
  }

  static void showInfoToast(BuildContext context, String message) {
    showToast(
      context: context,
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
} 