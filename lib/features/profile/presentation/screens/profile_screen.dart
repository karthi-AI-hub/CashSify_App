import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/theme_provider.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/widgets/feedback/custom_toast.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../features/common_screens/terms_screen.dart';
import '../../../../features/common_screens/privacy_policy_screen.dart';
import '../../../../features/common_screens/contact_us_screen.dart';
import '../../../../features/common_screens/faq_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeNotifier = ref.read(themeProviderProvider.notifier);
    final isDarkMode = ref.watch(themeProviderProvider).isDarkMode;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 0,
                child: _profileHeader(context),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Account Information'),
                    _accountInfoCard(context),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Payment Details'),
                    _paymentDetailsCard(context),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Settings'),
                    _settingsCard(context, colorScheme, textTheme, isDarkMode, themeNotifier),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Account Management'),
                    _accountManagementCard(context),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Legal'),
                    _legalCard(context),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 600,
                child: _footer(context),
              ),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Using the same verification status as in account info
    final isPhoneVerified = true; // From your phone verification status
    final isEmailVerified = true; // From your email verification status
    final isFullyVerified = isPhoneVerified && isEmailVerified;

    return Center(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    'K',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'KS',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          if (isFullyVerified) ...[
            SizedBox(height: AppSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: colorScheme.primary, size: 16),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Verified',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasReferrer = false; // This would come from your user data

    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.phone,
            'Phone Number',
            '+91 98765 43210',
            isVerified: true,
          ),
          _infoRow(
            context,
            Icons.email,
            'Email Address',
            'ks@email.com',
            isVerified: true,
          ),
          if (hasReferrer) // Only show if there's a referrer
            _infoRow(
              context,
              Icons.person,
              'Referred By',
              'John Doe',
            ),
          _infoRow(
            context,
            Icons.calendar_today,
            'Member Since',
            'January 2024',
          ),
          _infoRow(
            context,
            Icons.access_time,
            'Last Login',
            '2 hours ago',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _paymentDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.account_balance,
            'Bank Account',
            'XXXXXX1234',
          ),
          // Divider(height: 1),
          _infoRow(
            context,
            Icons.code,
            'IFSC Code',
            'SBIN0001234',
          ),
          // Divider(height: 1),
          _infoRow(
            context,
            Icons.payment,
            'UPI ID',
            'ks@upi',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isVerified = false,
    bool showDivider = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: AppSpacing.iconMd),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Row(
                      children: [
                        Text(
                          value.isEmpty ? 'Not available' : value,
                          style: textTheme.bodyMedium?.copyWith(
                            color: value.isEmpty ? colorScheme.error : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isVerified) ...[
                          SizedBox(width: AppSpacing.xs),
                          Icon(Icons.verified, color: colorScheme.primary, size: 16),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isVerified && (label == 'Phone Number' || label == 'Email Address'))
                TextButton(
                  onPressed: () {},
                  child: Text('Verify', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                ),
            ],
          ),
          if (!isVerified && (label == 'Phone Number' || label == 'Email Address'))
            Padding(
              padding: EdgeInsets.only(left: AppSpacing.iconMd + AppSpacing.md, top: AppSpacing.xs),
              child: Text(
                'Verification mandatory for withdrawal process',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (showDivider) Divider(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode, ThemeNotifier themeNotifier) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.edit,
            'Edit Profile',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            ),
          ),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.lock, 'Change Password', onTap: () {}),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.palette,
            'Dark Theme',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) => themeNotifier.toggleTheme(),
            ),
          ),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.support_agent,
            'Contact Us',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsScreen()),
            ),
          ),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.help_outline,
            'FAQ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FAQScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountManagementCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.delete_forever,
            'Delete Account',
            onTap: () {},
            textColor: colorScheme.error,
            iconColor: colorScheme.error,
          ),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.lock_reset,
            'Forgot Password',
            onTap: () {},
          ),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.logout,
            'Logout',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _legalCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.description,
            'Terms & Conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
          ),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.privacy_tip,
            'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            ),
          ),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.info, 'About Us', onTap: () {}),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          color: textColor ?? colorScheme.onSurface,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.primary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'App Version: 2.0',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () async {
              const email = 'cashsify@gmail.com';
              const phone = '+91 98765 43210'; // This would come from your user data
              try {
                final result = await launchUrlString(
                  'mailto:$email?subject=CashSify Support Request&body=Hello CashSify Support Team,%0A%0AI am writing regarding:%0A%0A%0A%0AUser Details:%0APhone: $phone%0A%0ABest regards,%0A[Your Name]',
                  mode: LaunchMode.externalNonBrowserApplication,
                );
                
                if (!result && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please contact us at $email'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please contact us at $email'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Support Email: cashsify@gmail.com',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated fade-in widget for section transitions
class _AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedFadeIn({required this.child, required this.delay});

  @override
  State<_AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<_AnimatedFadeIn> with SingleTickerProviderStateMixin {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() {
          _opacity = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _opacity == 1 ? Offset.zero : const Offset(0, 0.1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
} 