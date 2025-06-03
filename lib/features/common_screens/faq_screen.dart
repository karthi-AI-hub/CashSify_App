import 'package:flutter/material.dart';
import 'package:cashsify_app/theme/app_spacing.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: const [
          FAQSection(
            title: 'General',
            questions: [
              FAQItem(
                question: 'What is CashSify?',
                answer: 'CashSify is a reward-based app where users earn money by watching ads and completing simple tasks like CAPTCHA verification.',
              ),
              FAQItem(
                question: 'Is CashSify free to use?',
                answer: 'Yes, CashSify is completely free to use. You just need a mobile number to sign up and start earning.',
              ),
            ],
          ),
          FAQSection(
            title: 'Earnings',
            questions: [
              FAQItem(
                question: 'How can I earn money?',
                answer: 'You can earn money by watching rewarded ads and passing CAPTCHA challenges successfully.',
              ),
              FAQItem(
                question: 'Is there a daily earning limit?',
                answer: 'Yes, to maintain platform stability and prevent abuse, there is a daily earning limit which may vary based on user tier.',
              ),
            ],
          ),
          FAQSection(
            title: 'Withdrawals',
            questions: [
              FAQItem(
                question: 'How do I withdraw my earnings?',
                answer: 'Go to the Withdraw screen, enter your UPI ID and minimum threshold amount, and submit the request.',
              ),
              FAQItem(
                question: 'What is the minimum withdrawal amount?',
                answer: 'The minimum withdrawal amount is ₹20. You must have a verified UPI ID to withdraw.',
              ),
              FAQItem(
                question: 'How long does it take to process a withdrawal?',
                answer: 'Withdrawals are processed within 24-72 business hours after request, excluding holidays.',
              ),
            ],
          ),
          FAQSection(
            title: 'Referrals',
            questions: [
              FAQItem(
                question: 'How does the referral system work?',
                answer: 'You get rewarded in 3 phases when your referrals sign up, complete first task, and earn successfully.',
              ),
              FAQItem(
                question: 'Where can I find my referral code?',
                answer: 'Your referral code is available in the Referrals section inside the Earnings tab.',
              ),
            ],
          ),
          FAQSection(
            title: 'Account & Support',
            questions: [
              FAQItem(
                question: 'How can I reset my password?',
                answer: 'Click on "Forgot Password" in the login screen and follow the steps to reset it.',
              ),
              FAQItem(
                question: 'I faced a technical issue. What should I do?',
                answer: 'Please contact our support team via the Contact Us page or email us at support@cashsify.in.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  final String title;
  final List<FAQItem> questions;

  const FAQSection({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: questions.map((faq) {
        return ExpansionTile(
          title: Text(faq.question),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(faq.answer, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
} 