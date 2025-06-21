import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? contentColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final double? maxWidth;
  final double? maxHeight;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.showCloseButton = true,
    this.backgroundColor,
    this.titleColor,
    this.contentColor,
    this.borderRadius,
    this.contentPadding,
    this.actionsPadding,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? AppSpacing.radiusLg;
    final defaultContentPadding = contentPadding ?? EdgeInsets.all(AppSpacing.lg);
    final defaultActionsPadding = actionsPadding ?? EdgeInsets.all(AppSpacing.md);

    return Dialog(
      backgroundColor: backgroundColor ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 400,
          maxHeight: maxHeight ?? 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: defaultContentPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: titleColor ?? AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: titleColor ?? AppColors.onSurfaceVariant,
                        size: AppSpacing.iconMd,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: defaultContentPadding,
                child: DefaultTextStyle(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: contentColor ?? AppColors.onSurface,
                  ),
                  child: content,
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: defaultActionsPadding,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(defaultBorderRadius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: EdgeInsets.only(
                              left: AppSpacing.sm,
                            ),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 