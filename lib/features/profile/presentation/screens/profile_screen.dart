import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/theme_provider.dart';
import '../../../../core/widgets/layout/custom_card.dart';
import '../../../../core/widgets/feedback/custom_toast.dart';
import 'package:flutter/services.dart';

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
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                'K',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
                    _sectionHeader(context, 'Settings'),
                    _settingsCard(context, colorScheme, textTheme, isDarkMode, themeNotifier),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _AnimatedFadeIn(
                delay: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Account Management'),
                    _deleteAccountCard(context, colorScheme, textTheme),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(context, 'Legal'),
                    _legalCard(context, colorScheme, textTheme),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              _AnimatedFadeIn(
                delay: 500,
                child: _footer(context, colorScheme, textTheme),
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
    return Center(
      child: Column(
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
          SizedBox(height: AppSpacing.md),
          Text(
            'KS',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'ks@email.com',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: colorScheme.primary, size: 18),
                SizedBox(width: AppSpacing.xs),
                Text('Verified', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(context, Icons.calendar_today, 'Member Since', 'January 2024'),
          Divider(height: 1),
          _infoRow(context, Icons.access_time, 'Last Login', '2 hours ago'),
          Divider(height: 1),
          _infoRow(context, Icons.verified_user, 'Account Status', 'Verified'),
          Divider(height: 1),
          _referralRow(context, colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: AppSpacing.iconMd),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  Text(value, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _referralRow(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(Icons.share, color: colorScheme.primary, size: AppSpacing.iconMd),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Referral Code', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                Row(
                  children: [
                    Text('CASH123', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                    SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: Icon(Icons.copy, color: colorScheme.primary, size: AppSpacing.iconSm),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'CASH123'));
                        CustomToast.show(
                          context,
                          message: 'Referral code copied!',
                          type: ToastType.success,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('12 Referrals', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode, ThemeNotifier themeNotifier) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _settingsTile(context, colorScheme, textTheme, Icons.edit, 'Edit Profile', onTap: () {}),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.notifications, 'Notifications', onTap: () {}),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.lock, 'Change Password', onTap: () {}),
          Divider(height: 1),
          _settingsTile(
            context,
            colorScheme,
            textTheme,
            Icons.palette,
            'Theme Settings',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) => themeNotifier.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteAccountCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: colorScheme.error),
        title: Text(
          'Delete Account',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: () {},
      ),
    );
  }

  Widget _legalCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _settingsTile(context, colorScheme, textTheme, Icons.description, 'Terms of Service', onTap: () {}),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.privacy_tip, 'Privacy Policy', onTap: () {}),
          Divider(height: 1),
          _settingsTile(context, colorScheme, textTheme, Icons.info, 'About Us', onTap: () {}),
        ],
      ),
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

  Widget _settingsTile(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  Widget _footer(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'App Version: 1.0.0 (Build 1)',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Support Email: cashsify@gmail.com',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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