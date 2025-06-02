import 'package:flutter/material.dart';

class CustomTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration showDuration;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;

  const CustomTooltip({
    super.key,
    required this.message,
    required this.child,
    this.showDuration = const Duration(seconds: 2),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 8,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: message,
      showDuration: showDuration,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: 12,
      ),
      preferBelow: true,
      verticalOffset: 8,
      child: child,
    );
  }
} 