import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onDismiss;
  final Duration? duration;
  final bool showIcon;
  final bool showCloseButton;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomToast({
    super.key,
    required this.message,
    this.type = ToastType.info,
    this.onDismiss,
    this.duration,
    this.showIcon = true,
    this.showCloseButton = true,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = borderRadius ?? AppSpacing.radiusMd;
    final defaultPadding = padding ?? EdgeInsets.all(AppSpacing.md);
    final defaultMargin = margin ?? EdgeInsets.all(AppSpacing.md);

    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      switch (type) {
        case ToastType.success:
          return AppColors.successContainer;
        case ToastType.error:
          return AppColors.errorContainer;
        case ToastType.warning:
          return AppColors.warningContainer;
        case ToastType.info:
          return AppColors.infoContainer;
      }
    }

    Color getTextColor() {
      if (textColor != null) return textColor!;
      switch (type) {
        case ToastType.success:
          return AppColors.onSuccessContainer;
        case ToastType.error:
          return AppColors.onErrorContainer;
        case ToastType.warning:
          return AppColors.onWarningContainer;
        case ToastType.info:
          return AppColors.onInfoContainer;
      }
    }

    Color getIconColor() {
      if (iconColor != null) return iconColor!;
      switch (type) {
        case ToastType.success:
          return AppColors.success;
        case ToastType.error:
          return AppColors.error;
        case ToastType.warning:
          return AppColors.warning;
        case ToastType.info:
          return AppColors.info;
      }
    }

    IconData getIcon() {
      switch (type) {
        case ToastType.success:
          return Icons.check_circle_outline;
        case ToastType.error:
          return Icons.error_outline;
        case ToastType.warning:
          return Icons.warning_amber_outlined;
        case ToastType.info:
          return Icons.info_outline;
      }
    }

    return Container(
      margin: defaultMargin,
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: defaultPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  getIcon(),
                  color: getIconColor(),
                  size: AppSpacing.iconMd,
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: getTextColor(),
                  ),
                ),
              ),
              if (showCloseButton) ...[
                SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: getTextColor(),
                    size: AppSpacing.iconSm,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration? duration,
    bool showCloseButton = true,
    bool showIcon = true,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        child: Material(
          color: Colors.transparent,
          child: CustomToast(
            message: message,
            type: type,
            duration: duration,
            onDismiss: () => overlayEntry.remove(),
            showCloseButton: showCloseButton,
            showIcon: showIcon,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    if (duration != null) {
      Future.delayed(duration, () {
        overlayEntry.remove();
      });
    }
  }
}

enum ToastType {
  success,
  error,
  warning,
  info,
} 