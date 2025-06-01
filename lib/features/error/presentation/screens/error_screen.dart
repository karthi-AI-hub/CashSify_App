import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../theme/app_theme.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashsify_app/core/error/app_error.dart';

/// A reusable error screen that displays error information and provides retry functionality
class ErrorScreen extends StatelessWidget {
  final AppError? error;
  final VoidCallback onRetry;
  final String? customMessage;
  final String? customTitle;
  final Widget? customIcon;
  final String? helpText;
  final VoidCallback? onHelpPressed;

  const ErrorScreen({
    super.key,
    this.error,
    required this.onRetry,
    this.customMessage,
    this.customTitle,
    this.customIcon,
    this.helpText,
    this.onHelpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              customIcon ??
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
              const SizedBox(height: 24),
              Text(
                customTitle ?? 'Oops! Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                customMessage ?? error?.message ?? 'An unexpected error occurred',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Try Again',
                onPressed: onRetry,
              ),
              if (helpText != null || onHelpPressed != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onHelpPressed,
                  child: Text(
                    helpText ?? 'Need Help?',
                    style: GoogleFonts.poppins(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 