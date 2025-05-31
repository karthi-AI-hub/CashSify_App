import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/utils/logger.dart';

/// Utility class for handling errors throughout the app
class ErrorHandler {
  /// Handle errors and show appropriate UI feedback
  static void handleError(BuildContext context, dynamic error) {
    AppError appError;
    
    if (error is AuthException) {
      appError = AuthError.fromSupabase(error);
    } else if (error is AppError) {
      appError = error;
    } else {
      appError = AppError(
        'An unexpected error occurred',
        originalError: error,
      );
    }

    // Log the error
    AppLogger.error(
      appError.message,
      appError.originalError,
      StackTrace.current,
    );

    // Show error message to user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appError.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Handle errors in async operations
  static Future<T> handleAsyncError<T>(
    BuildContext context,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error) {
      handleError(context, error);
      rethrow;
    }
  }

  /// Convert a generic error to an AppError
  static AppError toAppError(dynamic error) {
    if (error is AppError) {
      return error;
    }
    
    if (error is AuthException) {
      return AuthError.fromSupabase(error);
    }
    
    if (error is TimeoutException) {
      return NetworkError.timeout();
    }
    
    return AppError(
      error.toString(),
      originalError: error,
    );
  }
} 