import 'package:flutter/material.dart';
import 'package:cashsify_app/core/widgets/form/custom_text_field.dart';

class AnimatedFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int index;
  final int totalFields;
  final bool hasError;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextStyle? textStyle;
  final Color? fillColor;
  final bool isLocked;

  const AnimatedFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    required this.index,
    required this.totalFields,
    this.hasError = false,
    this.readOnly = false,
    this.onChanged,
    this.textStyle,
    this.fillColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: textStyle,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: isLocked || fillColor != null,
          fillColor: fillColor ?? (isLocked ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : null),
          errorStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? theme.colorScheme.error : theme.colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? theme.colorScheme.error : theme.colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 2,
            ),
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
} 