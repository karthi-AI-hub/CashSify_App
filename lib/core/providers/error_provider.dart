import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/utils/logger.dart';

/// State class for error handling
class ErrorState {
  final String? message;
  final String? code;
  final dynamic originalError;

  ErrorState({
    this.message,
    this.code,
    this.originalError,
  });

  ErrorState copyWith({
    String? message,
    String? code,
    dynamic originalError,
  }) {
    return ErrorState(
      message: message ?? this.message,
      code: code ?? this.code,
      originalError: originalError ?? this.originalError,
    );
  }

  ErrorState clear() {
    return ErrorState();
  }

  static ErrorState none() => ErrorState();
}

/// Notifier for managing error state
class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(ErrorState());

  /// Handle an error and update the state
  void handleError(
    Object error, [
    StackTrace? stackTrace,
    String? message,
  ]) {
    AppError appError;
    if (error is AppError) {
      appError = error;
    } else {
      appError = AuthError(
        message: message ?? 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
        originalError: error,
      );
    }

    state = ErrorState(
      message: appError.message,
      code: appError.code,
      originalError: appError.originalError,
    );

    AppLogger.error(
      appError.message,
      appError.originalError,
      stackTrace,
    );
  }

  /// Clear the current error state
  void clear() {
    state = state.clear();
  }

  void clearError() {
    state = ErrorState.none();
  }

  void setError(String message, {String? code, dynamic originalError}) {
    state = ErrorState(
      message: message,
      code: code,
      originalError: originalError,
    );
  }

  void setAppError(AppError error) {
    state = ErrorState(
      message: error.message,
      code: error.code,
      originalError: error.originalError,
    );
  }
}

/// Provider for error state management
final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
}); 