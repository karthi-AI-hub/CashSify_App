import 'package:flutter/material.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/features/common_screens/contact_us_screen.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:go_router/go_router.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQSection> _allSections = const [
    FAQSection(
      title: 'About Watch2Earn',
      icon: Icons.info_outline,
      questions: [
        FAQItem(
          question: 'What is Watch2Earn?',
          answer: 'Watch2Earn is a rewards platform where users can earn virtual coins by watching ads, referring friends, and participating in various activities. These coins can be redeemed for rewards within the platform.',
        ),
        FAQItem(
          question: 'Is Watch2Earn free to use?',
          answer: 'Yes, Watch2Earn is completely free to download and use. You can start earning coins immediately after registration.',
        ),
        FAQItem(
          question: 'Is Watch2Earn available worldwide?',
          answer: 'Currently, Watch2Earn is available in select regions. Please check the app store in your country for availability.',
        ),
      ],
    ),
    FAQSection(
      title: 'Earning Coins',
      icon: Icons.emoji_events_outlined,
      questions: [
        FAQItem(
          question: 'How can I earn coins?',
          answer: 'You can earn coins by watching video ads, referring friends to the platform, and participating in various engagement activities. Each activity has different coin rewards.',
        ),
        FAQItem(
          question: 'Are there daily limits on earning?',
          answer: 'Yes, there are daily limits on coin earning to ensure fair usage and platform stability. These limits may vary based on your activity level and region.',
        ),
        FAQItem(
          question: 'Why do I need to watch ads?',
          answer: 'Watching ads is one of the primary ways to earn coins. This helps support the platform and provides you with rewards for your time and engagement.',
        ),
        FAQItem(
          question: 'Do I get coins for referring friends?',
          answer: 'Yes! When your friends join Watch2Earn using your referral code, both you and your friend receive bonus coins. The exact amount varies based on current promotions.',
        ),
      ],
    ),
    FAQSection(
      title: 'Coins & Rewards',
      icon: Icons.monetization_on_outlined,
      questions: [
        FAQItem(
          question: 'What can I do with my coins?',
          answer: 'Coins can be used to unlock premium features, access exclusive content, and redeem various rewards within the platform. Check the rewards section for current options.',
        ),
        FAQItem(
          question: 'What is the minimum coin requirement?',
          answer: 'Most reward redemptions require a minimum of 15,000 coins. This helps maintain platform stability and ensures meaningful rewards.',
        ),
        FAQItem(
          question: 'Do coins expire?',
          answer: 'Coins do not expire as long as your account remains active. However, we recommend using them regularly to enjoy the platform\'s features.',
        ),
        FAQItem(
          question: 'Can I transfer coins to other users?',
          answer: 'No, coins are non-transferable and can only be used by the account holder who earned them.',
        ),
      ],
    ),
    FAQSection(
      title: 'Account & Security',
      icon: Icons.security,
      questions: [
        FAQItem(
          question: 'How do I create an account?',
          answer: 'Download the app, enter your phone number, and follow the verification process. You\'ll need to provide basic information to complete registration.',
        ),
        FAQItem(
          question: 'How can I reset my password?',
          answer: 'Use the "Forgot Password" option on the login screen. You\'ll receive a verification code via SMS to reset your password.',
        ),
        FAQItem(
          question: 'Is my personal information safe?',
          answer: 'Yes, we take data security seriously. Your personal information is encrypted and stored securely. We never share your data with third parties without your consent.',
        ),
        FAQItem(
          question: 'Can I have multiple accounts?',
          answer: 'No, each phone number can only be associated with one Watch2Earn account. Multiple accounts may result in suspension.',
        ),
      ],
    ),
    FAQSection(
      title: 'Referral Program',
      icon: Icons.people_outline,
      questions: [
        FAQItem(
          question: 'How does the referral system work?',
          answer: 'Share your unique referral code with friends. When they join using your code, both you and your friend receive bonus coins.',
        ),
        FAQItem(
          question: 'Where can I find my referral code?',
          answer: 'Your referral code is available in the Referrals section of the app. You can copy and share it with friends.',
        ),
        FAQItem(
          question: 'How many friends can I refer?',
          answer: 'There\'s no limit to the number of friends you can refer. However, each friend can only use one referral code.',
        ),
        FAQItem(
          question: 'When do I receive referral bonuses?',
          answer: 'Referral bonuses are credited immediately when your friend completes the registration process using your code.',
        ),
      ],
    ),
    FAQSection(
      title: 'Technical Support',
      icon: Icons.support_agent,
      questions: [
        FAQItem(
          question: 'The app is not working properly',
          answer: 'Try restarting the app or clearing the cache. If the issue persists, contact our support team through the in-app contact form.',
        ),
        FAQItem(
          question: 'I didn\'t receive my coins',
          answer: 'Check your internet connection and try refreshing the app. If coins still haven\'t appeared, contact support with details of the activity.',
        ),
        FAQItem(
          question: 'How can I contact support?',
          answer: 'You can reach our support team through the in-app contact form, email us at app.watch2earn@gmail.com, or use the contact information in the About Us section.',
        ),
        FAQItem(
          question: 'What are your support hours?',
          answer: 'Our support team is available 24/7 to assist you with any questions or issues you may have.',
        ),
      ],
    ),
    FAQSection(
      title: 'Platform Policies',
      icon: Icons.policy,
      questions: [
        FAQItem(
          question: 'What are the terms of service?',
          answer: 'Our terms of service outline the rules and guidelines for using Watch2Earn. You can find the complete terms in the app settings or on our website.',
        ),
        FAQItem(
          question: 'What is your privacy policy?',
          answer: 'Our privacy policy explains how we collect, use, and protect your personal information. You can read it in the app settings or on our website.',
        ),
        FAQItem(
          question: 'Can my account be suspended?',
          answer: 'Yes, accounts may be suspended for violating our terms of service, including creating multiple accounts, using automated tools, or engaging in fraudulent activities.',
        ),
        FAQItem(
          question: 'How do I report an issue?',
          answer: 'Use the in-app contact form or email app.watch2earn@gmail.com to report any issues. Please provide as much detail as possible.',
        ),
      ],
    ),
  ];

  List<FAQSection> _filteredSections = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredSections = _allSections;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredSections = _allSections;
      });
      return;
    }
    setState(() {
      _filteredSections = _allSections.map((section) {
        final filteredQuestions = section.questions.where((faq) {
          return faq.question.toLowerCase().contains(query) || 
                 faq.answer.toLowerCase().contains(query);
        }).toList();
        return filteredQuestions.isEmpty
            ? null
            : FAQSection(
                title: section.title,
                icon: section.icon,
                questions: filteredQuestions,
              );
      }).whereType<FAQSection>().toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return WillPopScope(
      onWillPop: () async {
        _clearSearch();
        context.go('/profile');
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'FAQs',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
        ),
        body: Column(
          children: [
            // Permanent search bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            // FAQ content
            Expanded(
              child: _filteredSections.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No results found',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Column(
                              children: _filteredSections.map((section) {
                                return FAQSectionWidget(
                                  section: section,
                                  isSearchResult: _searchController.text.isNotEmpty,
                                );
                              }).toList(),
                            ),
                          ),
                          // Contact support button
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.support_agent, size: 20),
                              label: const Text('Contact Support'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                context.push('/contact-us');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQSectionWidget extends StatelessWidget {
  final FAQSection section;
  final bool isSearchResult;

  const FAQSectionWidget({
    super.key,
    required this.section,
    this.isSearchResult = false,
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
      child: isSearchResult
          ? Column(
              children: section.questions.map((faq) {
                return _buildFAQItem(faq, colorScheme, textTheme);
              }).toList(),
            )
          : ExpansionTile(
              leading: Icon(section.icon, color: colorScheme.primary),
              title: Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              children: section.questions.map((faq) {
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

class FAQSection {
  final String title;
  final IconData icon;
  final List<FAQItem> questions;

  const FAQSection({
    required this.title,
    required this.icon,
    required this.questions,
  });
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}
