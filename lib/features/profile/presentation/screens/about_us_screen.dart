import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/widgets/layout/custom_app_bar.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';

class AboutUsScreen extends HookConsumerWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Watch the providers
    final socialUrlsAsync = ref.watch(socialMediaUrlsProvider);
    final contactInfoAsync = ref.watch(contactInfoProvider);

    return WillPopScope(
      onWillPop: () async {
        context.go('/profile');
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'About CashSify',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/profile'),
            color: colorScheme.onPrimary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareApp(context, ref),
              tooltip: 'Share App',
              color: Colors.white,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // App Info Card
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: colorScheme.primary.withOpacity(0.1),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // App Name & Version
                        Text(
                          'CashSify',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppConfig.slogan}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Version ${AppConfig.appVersion}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // App Description
                        Text(
                          'CashSify is a rewards platform where you can earn virtual coins by watching ads, referring friends, and completing simple tasks. These coins can be redeemed for various rewards and premium features within the platform.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Features Card
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What You Can Do',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildFeatureItem(
                          context,
                          icon: Icons.play_circle_outline,
                          title: 'Watch Ads & Earn',
                          description: 'Watch short video ads and earn coins for each view',
                        ),
                        _buildFeatureItem(
                          context,
                          icon: Icons.people_outline,
                          title: 'Refer & Earn',
                          description: 'Invite friends and earn bonus rewards when they join',
                        ),
                        _buildFeatureItem(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Redeem Rewards',
                          description: 'Use your coins to redeem within the platform',
                        ),
                        _buildFeatureItem(
                          context,
                          icon: Icons.security,
                          title: 'Safe & Secure',
                          description: 'Your data and earnings are protected with bank-level security',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Contact Information Card
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get in Touch',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.support_agent, size: 20),
                            label: const Text('Contact Support'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => context.push('/contact-us'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Social Media Card
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follow Us',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        socialUrlsAsync.when(
                          data: (socialUrls) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (socialUrls['whatsapp']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.message,
                                  label: 'WhatsApp',
                                  onTap: () => _launchUrl(socialUrls['whatsapp']!),
                                ),
                              if (socialUrls['telegram']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.send,
                                  label: 'Telegram',
                                  onTap: () => _launchUrl(socialUrls['telegram']!),
                                ),
                              if (socialUrls['facebook']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.facebook,
                                  label: 'Facebook',
                                  onTap: () => _launchUrl(socialUrls['facebook']!),
                                ),
                              if (socialUrls['youtube']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.play_circle_filled,
                                  label: 'YouTube',
                                  onTap: () => _launchUrl(socialUrls['youtube']!),
                                ),
                              if (socialUrls['instagram']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.camera_alt,
                                  label: 'Instagram',
                                  onTap: () => _launchUrl(socialUrls['instagram']!),
                                ),
                              if (socialUrls['twitter']?.isNotEmpty == true)
                                _buildSocialButton(
                                  context,
                                  icon: Icons.flutter_dash,
                                  label: 'Twitter',
                                  onTap: () => _launchUrl(socialUrls['twitter']!),
                                ),
                            ],
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.error,
                                    size: 48,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Failed to load social links',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Legal Information
                Text(
                  '© ${DateTime.now().year} CashSify. All rights reserved.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/privacy-policy'),
                      child: const Text('Privacy Policy'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      child: const Text('Terms of Service'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Powered By CashSify
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Powered By CashSify',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context, WidgetRef ref) async {
    final contactInfoAsync = ref.read(contactInfoProvider);
    final playStoreUrl = await contactInfoAsync.when(
      data: (contactInfo) => contactInfo['playstore'] ?? AppConfig.playStoreUrl,
      loading: () => AppConfig.playStoreUrl,
      error: (_, __) => AppConfig.playStoreUrl,
    );
    
    final message = "🎉 Discover CashSify - the ultimate rewards platform! Earn virtual coins by watching ads, referring friends, and completing simple tasks. Download now: $playStoreUrl and start earning rewards today! 🚀";
    await Share.share(message);
  }
}
