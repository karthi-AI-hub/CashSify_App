import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/providers/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return SwitchListTile(
      title: Text(
        'Dark Mode',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        'Toggle between light and dark theme',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: isDarkMode,
      onChanged: (value) {
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
} 