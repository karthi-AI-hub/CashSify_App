import 'package:flutter/material.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/features/common_screens/contact_us_screen.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar for FAQs
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
            
            // FAQ Categories
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: const [
                  FAQSection(
                    title: 'General',
                    icon: Icons.info_outline,
                    questions: [
                      FAQItem(
                        question: 'What is CashSify?',
                        answer: 'CashSify is a platform where users can engage with content and activities to earn virtual points.',
                      ),
                      FAQItem(
                        question: 'Is CashSify free to use?',
                        answer: 'Yes, CashSify is completely free to use. Registration only requires a mobile number to access all features.',
                      ),
                    ],
                  ),
                  FAQSection(
                    title: 'Engagement Rewards',
                    icon: Icons.emoji_events_outlined,
                    questions: [
                      FAQItem(
                        question: 'How can I earn points?',
                        answer: 'You can collect virtual points by participating in platform activities and engaging with content.',
                      ),
                      FAQItem(
                        question: 'Are there limits to point collection?',
                        answer: 'To ensure fair access for all users, there may be daily limits on virtual point accumulation, which can vary based on user activity.',
                      ),
                    ],
                  ),
                  FAQSection(
                    title: 'Virtual Points',
                    icon: Icons.monetization_on_outlined,
                    questions: [
                      FAQItem(
                        question: 'How do I use my points?',
                        answer: 'Virtual points can be used within the app for various features and activities. Check the app for current usage options.',
                      ),
                      FAQItem(
                        question: 'What is the minimum point threshold?',
                        answer: 'Certain features may require a minimum of 15000 points to be used. This helps maintain platform stability.',
                      ),
                    ],
                  ),
                  FAQSection(
                    title: 'Platform Features',
                    icon: Icons.dashboard_customize_outlined,
                    questions: [
                      FAQItem(
                        question: 'How do I access special features?',
                        answer: 'Navigate to the Wallet section to view available features that may require virtual points.',
                      ),
                      FAQItem(
                        question: 'How long do feature requests take?',
                        answer: 'Requests are typically processed within 24-72 business hours, excluding holidays.',
                      ),
                    ],
                  ),
                  FAQSection(
                    title: 'Social Features',
                    icon: Icons.people_outline,
                    questions: [
                      FAQItem(
                        question: 'How does the social sharing system work?',
                        answer: 'The platform offers social sharing features that may provide additional engagement opportunities.',
                      ),
                      FAQItem(
                        question: 'Where can I find my sharing code?',
                        answer: 'Your unique sharing identifier is available in the Social section of the app.',
                      ),
                    ],
                  ),
                  FAQSection(
                    title: 'Account & Support',
                    icon: Icons.support_agent,
                    questions: [
                      FAQItem(
                        question: 'How can I reset my password?',
                        answer: 'Use the "Forgot Password" option on the login screen to reset your credentials.',
                      ),
                      FAQItem(
                        question: 'I need technical assistance',
                        answer: 'Our support team can be reached through the in-app contact form or at support@cashsify.in.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contact support button
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: ElevatedButton.icon(
                icon: Icon(Icons.support_agent, size: 20),
                label: Text('Contact Support'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<FAQItem> questions;

  const FAQSection({
    super.key,
    required this.title,
    required this.icon,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.sm),
        children: questions.map((faq) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildFAQItem(faq, colorScheme, textTheme),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildFAQItem(FAQItem faq, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Text(
          faq.question,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              faq.answer,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}