import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;
  final Color? progressColor;
  final Color? messageColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.isLoading = false,
    this.message,
    this.backgroundColor,
    this.progressColor,
    this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? AppColors.overlay,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppSpacing.iconXl,
                    height: AppSpacing.iconXl,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: messageColor ?? theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
} 