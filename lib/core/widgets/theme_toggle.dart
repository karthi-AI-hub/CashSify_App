import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? iconColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const ThemeToggle({
    super.key,
    this.size,
    this.activeColor,
    this.inactiveColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final defaultSize = size ?? AppSpacing.iconLg;
    final defaultBorderRadius = borderRadius ?? AppSpacing.radiusMd;
    final defaultPadding = padding ?? EdgeInsets.all(AppSpacing.sm);

    return IconButton(
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
      icon: Container(
        padding: defaultPadding,
        decoration: BoxDecoration(
          color: themeMode == ThemeMode.dark
              ? activeColor ?? AppColors.primaryContainer
              : inactiveColor ?? AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        child: Icon(
          themeMode == ThemeMode.dark
              ? Icons.dark_mode
              : Icons.light_mode,
          color: iconColor ?? (themeMode == ThemeMode.dark
              ? AppColors.onPrimaryContainer
              : AppColors.onSurfaceVariant),
          size: defaultSize,
        ),
      ),
    );
  }
} 