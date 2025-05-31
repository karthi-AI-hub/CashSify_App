import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/utils/logger.dart';

/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const AppError(this.message, {this.code = 'UNKNOWN_ERROR', this.originalError});

  @override
  String toString() => message;
}

/// Authentication related errors
class AuthError extends AppError {
  const AuthError({
    required String message,
    required String code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  factory AuthError.invalidCredentials() {
    return const AuthError(
      code: '401',
      message: 'Invalid email or password',
    );
  }

  factory AuthError.userNotFound() {
    return const AuthError(
      code: '404',
      message: 'User not found',
    );
  }

  factory AuthError.emailInUse() {
    return const AuthError(
      code: '409',
      message: 'Email is already in use',
    );
  }

  factory AuthError.weakPassword() {
    return const AuthError(
      code: '400',
      message: 'Password is too weak',
    );
  }

  factory AuthError.fromSupabase(AuthException error) {
    return AuthError(
      code: error.statusCode ?? 'UNKNOWN_ERROR',
      message: error.message,
      originalError: error,
    );
  }
}

/// Network related errors
class NetworkError extends AppError {
  const NetworkError({
    required String message,
    String code = 'NETWORK_ERROR',
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  factory NetworkError.noConnection() {
    return const NetworkError(
      code: 'NO_CONNECTION',
      message: 'No internet connection',
    );
  }

  factory NetworkError.timeout() {
    return const NetworkError(
      code: 'TIMEOUT',
      message: 'Request timed out',
    );
  }

  factory NetworkError.serverError() {
    return const NetworkError(
      code: 'SERVER_ERROR',
      message: 'Server error occurred',
    );
  }
}

/// Database related errors
class DatabaseError extends AppError {
  const DatabaseError({
    required String message,
    String code = 'DATABASE_ERROR',
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  factory DatabaseError.notFound() {
    return const DatabaseError(
      code: 'NOT_FOUND',
      message: 'Record not found',
    );
  }

  factory DatabaseError.duplicateEntry() {
    return const DatabaseError(
      code: 'DUPLICATE_ENTRY',
      message: 'Record already exists',
    );
  }

  factory DatabaseError.invalidData() {
    return const DatabaseError(
      code: 'INVALID_DATA',
      message: 'Invalid data provided',
    );
  }
}

/// Validation related errors
class ValidationError extends AppError {
  const ValidationError({
    required String message,
    String code = 'VALIDATION_ERROR',
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  factory ValidationError.invalidEmail() {
    return const ValidationError(
      code: 'INVALID_EMAIL',
      message: 'Invalid email format',
    );
  }

  factory ValidationError.invalidPassword() {
    return const ValidationError(
      code: 'INVALID_PASSWORD',
      message: 'Password must be at least 6 characters',
    );
  }

  factory ValidationError.invalidPhone() {
    return const ValidationError(
      code: 'INVALID_PHONE',
      message: 'Invalid phone number format',
    );
  }
}

/// Permission related errors
class PermissionError extends AppError {
  const PermissionError({
    required String message,
    String code = 'PERMISSION_ERROR',
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  factory PermissionError.denied() {
    return const PermissionError(
      code: 'PERMISSION_DENIED',
      message: 'Permission denied',
    );
  }

  factory PermissionError.notGranted() {
    return const PermissionError(
      code: 'PERMISSION_NOT_GRANTED',
      message: 'Permission not granted',
    );
  }
}

/// Error handling utility
class ErrorHandler {
  /// Handle errors and show appropriate UI feedback
  static void handleError(BuildContext context, dynamic error) {
    AppError appError;
    
    if (error is AuthException) {
      appError = AuthError.fromSupabase(error);
    } else if (error is AppError) {
      appError = error;
    } else {
      appError = AuthError(message: 'An unexpected error occurred', code: 'UNKNOWN_ERROR', originalError: error);
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
} 