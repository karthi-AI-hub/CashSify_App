import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display Styles
  static TextStyle get displayLarge => const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      );

  // Headline Styles
  static TextStyle get headlineLarge => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
      );

  // Title Styles
  static TextStyle get titleLarge => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // Label Styles
  static TextStyle get labelLarge => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      );

  // Body Styles
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // Button Style
  static TextStyle button(BuildContext context) => labelLarge.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      );

  // Helper method to get text style with color
  static TextStyle withColor(TextStyle style, Color color) => style.copyWith(
        color: color,
      );

  // Helper method to get text style with weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) => style.copyWith(
        fontWeight: weight,
      );

  // Helper method to get text style with size
  static TextStyle withSize(TextStyle style, double size) => style.copyWith(
        fontSize: size,
      );

  // Helper method to get text style with letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double spacing) => style.copyWith(
        letterSpacing: spacing,
      );

  // Helper method to get text style with height
  static TextStyle withHeight(TextStyle style, double height) => style.copyWith(
        height: height,
      );

  // Helper method to get text style with decoration
  static TextStyle withDecoration(TextStyle style, TextDecoration decoration) => style.copyWith(
        decoration: decoration,
      );

  // Helper method to get text style with font family
  static TextStyle withFontFamily(TextStyle style, String fontFamily) => style.copyWith(
        fontFamily: fontFamily,
      );

  // Helper method to get text style with font style
  static TextStyle withFontStyle(TextStyle style, FontStyle fontStyle) => style.copyWith(
        fontStyle: fontStyle,
      );

  // Helper method to get text style with background color
  static TextStyle withBackgroundColor(TextStyle style, Color color) => style.copyWith(
        backgroundColor: color,
      );

  // Helper method to get text style with shadows
  static TextStyle withShadows(TextStyle style, List<Shadow> shadows) => style.copyWith(
        shadows: shadows,
      );

  // Helper method to get text style with locale
  static TextStyle withLocale(TextStyle style, Locale locale) => style.copyWith(
        locale: locale,
      );

  // Helper method to get text style with package
  static TextStyle withPackage(TextStyle style, String package) => style.copyWith(
        package: package,
      );

  // Helper method to get text style with debug label
  static TextStyle withDebugLabel(TextStyle style, String debugLabel) => style.copyWith(
        debugLabel: debugLabel,
      );

  // Helper method to get text style with inherit
  static TextStyle withInherit(TextStyle style, bool inherit) => style.copyWith(
        inherit: inherit,
      );

  // Helper method to get text style with color and weight
  static TextStyle withColorAndWeight(TextStyle style, Color color, FontWeight weight) => style.copyWith(
        color: color,
        fontWeight: weight,
      );

  // Helper method to get text style with color and size
  static TextStyle withColorAndSize(TextStyle style, Color color, double size) => style.copyWith(
        color: color,
        fontSize: size,
      );

  // Helper method to get text style with color and letter spacing
  static TextStyle withColorAndLetterSpacing(TextStyle style, Color color, double spacing) => style.copyWith(
        color: color,
        letterSpacing: spacing,
      );

  // Helper method to get text style with color and height
  static TextStyle withColorAndHeight(TextStyle style, Color color, double height) => style.copyWith(
        color: color,
        height: height,
      );

  // Helper method to get text style with color and decoration
  static TextStyle withColorAndDecoration(TextStyle style, Color color, TextDecoration decoration) => style.copyWith(
        color: color,
        decoration: decoration,
      );

  // Helper method to get text style with color and font family
  static TextStyle withColorAndFontFamily(TextStyle style, Color color, String fontFamily) => style.copyWith(
        color: color,
        fontFamily: fontFamily,
      );

  // Helper method to get text style with color and font style
  static TextStyle withColorAndFontStyle(TextStyle style, Color color, FontStyle fontStyle) => style.copyWith(
        color: color,
        fontStyle: fontStyle,
      );

  // Helper method to get text style with color and background color
  static TextStyle withColorAndBackgroundColor(TextStyle style, Color color, Color backgroundColor) => style.copyWith(
        color: color,
        backgroundColor: backgroundColor,
      );

  // Helper method to get text style with color and shadows
  static TextStyle withColorAndShadows(TextStyle style, Color color, List<Shadow> shadows) => style.copyWith(
        color: color,
        shadows: shadows,
      );

  // Helper method to get text style with color and locale
  static TextStyle withColorAndLocale(TextStyle style, Color color, Locale locale) => style.copyWith(
        color: color,
        locale: locale,
      );

  // Helper method to get text style with color and package
  static TextStyle withColorAndPackage(TextStyle style, Color color, String package) => style.copyWith(
        color: color,
        package: package,
      );

  // Helper method to get text style with color and debug label
  static TextStyle withColorAndDebugLabel(TextStyle style, Color color, String debugLabel) => style.copyWith(
        color: color,
        debugLabel: debugLabel,
      );

  // Helper method to get text style with color and inherit
  static TextStyle withColorAndInherit(TextStyle style, Color color, bool inherit) => style.copyWith(
        color: color,
        inherit: inherit,
      );
} 