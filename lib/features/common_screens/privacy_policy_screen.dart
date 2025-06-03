import 'package:flutter/material.dart';
import 'package:cashsify_app/theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Introduction', textTheme),
            _sectionText(
              'Your privacy is important to us. This Privacy Policy explains how CashSify collects, uses, and protects your personal information.',
              textTheme,
            ),
            _sectionTitle('2. Data We Collect', textTheme),
            _sectionText(
              'We collect basic account information such as your name, email address, and device ID when you register on our platform.',
              textTheme,
            ),
            _sectionTitle('3. How We Use Your Data', textTheme),
            _sectionText(
              'Your information is used to personalize your experience, verify identity, provide rewards, and improve our services. We do not sell your data to third parties.',
              textTheme,
            ),
            _sectionTitle('4. Advertisements', textTheme),
            _sectionText(
              'We may display ads from third-party partners. These partners may collect limited data to serve relevant ads, as governed by their own privacy policies.',
              textTheme,
            ),
            _sectionTitle('5. Data Security', textTheme),
            _sectionText(
              'We implement reasonable security measures to protect your information. However, no system is completely secure. Use the app at your own risk.',
              textTheme,
            ),
            _sectionTitle('6. User Rights', textTheme),
            _sectionText(
              'You have the right to access, modify, or delete your data. You can do so by contacting us or using in-app options when available.',
              textTheme,
            ),
            _sectionTitle("7. Children's Privacy", textTheme),
            _sectionText(
              'CashSify is not intended for use by individuals under the age of 18. We do not knowingly collect data from minors.',
              textTheme,
            ),
            _sectionTitle('8. Changes to This Policy', textTheme),
            _sectionText(
              'We may update this policy from time to time. Continued use of the app signifies your acceptance of the updated terms.',
              textTheme,
            ),
            _sectionTitle('9. Contact', textTheme),
            _sectionText(
              'For any questions about this policy or your data, please reach out through the "Contact Us" option in the Profile tab.',
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