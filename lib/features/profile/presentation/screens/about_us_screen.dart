import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/widgets/layout/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return WillPopScope(
      onWillPop: () async {
        context.go('/profile');
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'About Us',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CashSify', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Version 1.0.0', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('CashSify is a rewards platform where you can earn coins by watching ads, referring friends, and more. Redeem your coins for exciting rewards!', style: textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Contact us: cashsify@gmail.com', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 