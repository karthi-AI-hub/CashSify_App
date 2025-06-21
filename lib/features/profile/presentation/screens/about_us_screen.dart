import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../core/widgets/layout/custom_card.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        leading: BackButton(),
        backgroundColor: colorScheme.surface,
        elevation: 0,
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
                  Text('CashSify is a rewards platform where you can earn coins by watching ads, referring friends, and more. Redeem your coins for exciting rewards and cashouts!', style: textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Contact us: cashsify@gmail.com', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 