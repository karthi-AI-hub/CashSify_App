import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? errorColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? focusedErrorBorderColor;
  final TextAlign? textAlign;
  final String? Function(String?)? validator;
  final bool filled;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.prefix,
    this.suffix,
    this.contentPadding,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.errorColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.focusedErrorBorderColor,
    this.textAlign,
    this.validator,
    this.filled = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = borderRadius ?? AppSpacing.radiusMd;
    final defaultHeight = height ?? AppSpacing.inputHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: textColor ?? theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        SizedBox(
          height: defaultHeight,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onFieldSubmitted: onSubmitted,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            enabled: enabled,
            readOnly: readOnly,
            autofocus: autofocus,
            focusNode: focusNode,
            textAlign: textAlign ?? TextAlign.start,
            validator: validator,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor ?? theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: hintColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              errorText: error,
              errorStyle: AppTextStyles.bodySmall.copyWith(
                color: errorColor ?? theme.colorScheme.error,
              ),
              prefixIcon: prefix,
              suffixIcon: suffix,
              contentPadding: contentPadding ?? EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              filled: filled,
              fillColor: fillColor ?? backgroundColor ?? theme.colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: borderColor ?? theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: borderColor ?? theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: focusedBorderColor ?? theme.colorScheme.primary,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: errorBorderColor ?? theme.colorScheme.error,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadius),
                borderSide: BorderSide(
                  color: focusedErrorBorderColor ?? theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 