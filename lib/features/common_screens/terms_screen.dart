import 'package:flutter/material.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          title: 'Terms & Conditions',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('1. Introduction', textTheme),
              _sectionText(
                'By downloading or using the app, you agree to be bound by these Terms and Conditions. These terms govern your use of CashSify and outline your rights and responsibilities as a user.',
                textTheme,
              ),
              _sectionTitle('2. User Eligibility', textTheme),
              _sectionText(
                'You must be at least 18 years old to use this app. By using CashSify, you confirm that you meet this age requirement.',
                textTheme,
              ),
              _sectionTitle('3. Account Registration', textTheme),
              _sectionText(
                'Users must register with a valid email address and password. You are responsible for maintaining the confidentiality of your login credentials.',
                textTheme,
              ),
              _sectionTitle('4. Use of the App', textTheme),
              _sectionText(
                'You agree to use the app for lawful purposes only. Any attempt to exploit the ad-watching or reward system through automation, manipulation, or fraud is strictly prohibited.',
                textTheme,
              ),
              _sectionTitle('5. Rewards & Coins', textTheme),
              _sectionText(
                'Users earn coins by watching ads and completing CAPTCHA verification. Coins have no real monetary value unless converted through our redeemtion process. We reserve the right to modify or limit rewards at any time.',
                textTheme,
              ),
              _sectionTitle('6. Advertisements', textTheme),
              _sectionText(
                'CashSify relies on rewarded ads. We are not responsible for ad content or the availability of ads. Ad abuse may lead to account termination.',
                textTheme,
              ),
              _sectionTitle('7. Termination & Suspension', textTheme),
              _sectionText(
                'We may suspend or terminate your account at our sole discretion if we suspect fraudulent activity or any violation of these terms.',
                textTheme,
              ),
              _sectionTitle('8. Limitation of Liability', textTheme),
              _sectionText(
                'CashSify is provided "as is". We do not guarantee uninterrupted or error-free operation. We are not liable for any loss or damage resulting from app use.',
                textTheme,
              ),
              _sectionTitle('9. Changes to Terms', textTheme),
              _sectionText(
                'We may update these Terms at any time. Continued use of the app after changes implies your acceptance of the new terms.',
                textTheme,
              ),
              _sectionTitle('10. Contact Us', textTheme),
              _sectionText(
                'If you have questions or concerns regarding these Terms and Conditions, please reach out to us via the "Contact Us" section in the Profile tab.',
                textTheme,
              ),
              SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  '© 2025 CashSify. All rights reserved.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.bodyMedium?.copyWith(
        height: 1.5,
      ),
    );
  }
} 