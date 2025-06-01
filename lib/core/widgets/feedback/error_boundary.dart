import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Object? error;
  final VoidCallback? onRetry;
  final String? retryText;
  final String? errorTitle;
  final String? errorMessage;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.error,
    this.onRetry,
    this.retryText,
    this.errorTitle,
    this.errorMessage,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return child;

    final defaultBorderRadius = borderRadius ?? AppSpacing.radiusMd;
    final defaultPadding = padding ?? EdgeInsets.all(AppSpacing.lg);
    final defaultMargin = margin ?? EdgeInsets.all(AppSpacing.md);

    return Container(
      margin: defaultMargin,
      padding: defaultPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.errorContainer,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: iconColor ?? AppColors.error,
            size: AppSpacing.iconXl,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            errorTitle ?? 'Error',
            style: AppTextStyles.titleLarge.copyWith(
              color: textColor ?? AppColors.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor ?? AppColors.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                retryText ?? 'Retry',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 