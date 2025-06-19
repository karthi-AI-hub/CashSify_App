import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
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
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/models/user_state.dart';
import 'package:flutter/rendering.dart';
import 'package:cashsify_app/core/widgets/optimized_image.dart';
import 'dart:async';

// Add this provider to fetch the referrer's name by ID
final referrerNameProvider = FutureProvider.family<String?, String?>((ref, referrerId) async {
  if (referrerId == null) return null;
  final supabase = SupabaseService().client;
  final response = await supabase
      .from('users')
      .select('name')
      .eq('id', referrerId)
      .maybeSingle();
  return response?['name'] as String?;
});

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeNotifier = ref.read(themeProviderProvider.notifier);
    final isDarkMode = ref.watch(themeProviderProvider).isDarkMode;
    final loadingState = ref.watch(loadingProvider);
    final userState = ref.watch(userProvider);

    // Store the loading notifier before useEffect
    final loadingNotifier = ref.read(loadingProvider.notifier);
    
    useEffect(() {
      final userService = ref.read(userServiceProvider);
      final currentUser = userService.supabase.client.auth.currentUser;
      
      // Refresh user data when screen is mounted
      if (currentUser != null) {
        ref.read(userProvider.notifier).refreshUser();
      }
      
      // No cleanup needed as we don't want to modify state after disposal
      return null;
    }, []);

    // Memoize expensive computations
    final isFullyVerified = useMemoized(() {
      return userState.value?.isEmailVerified ?? false;
    }, [userState.value?.isEmailVerified]);

    return LoadingOverlay(
      isLoading: loadingState == LoadingState.loading && userState.isLoading,
      message: loadingState == LoadingState.loading ? 'Loading profile...' : null,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: userState.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  'Please login to view your profile',
                  style: textTheme.bodyLarge,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(userProvider.notifier).refreshUser();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppSpacing.xxl),
                          _profileHeader(context, user, ref),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Personal Details',
                            _personalDetailsCard(context, user),
                            delay: 100,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Account Information',
                            _accountInfoCard(context, user),
                            delay: 200,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Payment Details',
                            _paymentDetailsCard(context, user),
                            delay: 300,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Settings',
                            _settingsCard(context, colorScheme, textTheme, isDarkMode, themeNotifier),
                            delay: 400,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Account Management',
                            _accountManagementCard(context, ref),
                            delay: 500,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _buildSection(
                            context,
                            'Legal',
                            _legalCard(context),
                            delay: 500,
                          ),
                          SizedBox(height: AppSpacing.xxl),
                          _footer(context),
                          SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error loading profile: ${error.toString()}',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content, {required int delay}) {
    return _AnimatedFadeIn(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, title),
          content,
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, UserState user, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFullyVerified = user.isEmailVerified ?? false;

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
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          (user.name?.isNotEmpty ?? false) ? user.name![0].toUpperCase() : 'U',
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () async {
                      // Navigate to edit screen and wait for result
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      
                      // If profile was updated, refresh the data
                      if (result == true && context.mounted) {
                        await ref.read(userProvider.notifier).refreshUser();
                      }
                    },
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
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            user.name ?? 'User',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          if (isFullyVerified)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: colorScheme.primary, size: 16),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'verified',
                  style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _personalDetailsCard(BuildContext context, UserState user) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.person,
            'Name',
            user.name ?? 'User',
          ),
          _infoRow(
            context,
            Icons.email,
            'Email Address',
            user.email,
            isVerified: user.isEmailVerified ?? false,
          ),
          _infoRow(
            context,
            Icons.phone,
            'Phone Number',
            user.phoneNumber ?? 'Not set',
          ),
          _infoRow(
            context,
            Icons.person_outline,
            'Gender',
            user.gender ?? 'Not set',
          ),
          _infoRow(
            context,
            Icons.cake,
            'Date of Birth',
            user.dob != null ? _formatDate(user.dob) : 'Not set',
          ),
          if (user.referredBy != null)
            Consumer(
              builder: (context, ref, _) {
                final referrerNameAsync = ref.watch(referrerNameProvider(user.referredBy));
                return referrerNameAsync.when(
                  data: (name) => _infoRow(
                    context,
                    Icons.group,
                    'Referred By',
                    name ?? user.referredBy!, // fallback to ID if name not found
                  ),
                  loading: () => _infoRow(
                    context,
                    Icons.group,
                    'Referred By',
                    'Loading...',
                  ),
                  error: (e, _) => _infoRow(
                    context,
                    Icons.group,
                    'Referred By',
                    'Unknown',
                  ),
                );
              },
            ),
          _infoRow(
            context,
            Icons.calendar_today,
            'Member Since',
            _formatDate(user.createdAt),
          ),
          _infoRow(
            context,
            Icons.access_time,
            'Last Login',
            _formatDate(user.lastLogin),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _accountInfoCard(BuildContext context, UserState user) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.monetization_on,
            'Coins',
            user.coins.toString(),
          ),
          _infoRow(
            context,
            Icons.code,
            'Referral Code',
            user.referralCode,
          ),
          _infoRow(
            context,
            Icons.people,
            'Referral Count',
            user.referralCount?.toString() ?? '0',
          ),
          _infoRow(
            context,
            Icons.verified_user,
            'Is Verified',
            user.isVerified ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _paymentDetailsCard(BuildContext context, UserState user) {
    return CustomCard(
      margin: EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.payment,
            'UPI ID',
            user.upiId ?? 'Not set',
          ),
          if (user.bankAccount != null) ...[
            _infoRow(
              context,
              Icons.account_balance,
              'Bank Account Number',
              user.bankAccount?['account_no'] ?? 'N/A',
            ),
            _infoRow(
              context,
              Icons.account_box,
              'Account Holder Name',
              user.bankAccount?['name'] ?? 'N/A',
            ),
            _infoRow(
              context,
              Icons.code,
              'IFSC Code',
              user.bankAccount?['ifsc'] ?? 'N/A',
              showDivider: false,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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

  Widget _accountManagementCard(
    BuildContext context,
    WidgetRef ref,
  ) {
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
            onTap: () async {
              try {
                ref.read(loadingProvider.notifier).state = LoadingState.loading;
                
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  // Call Supabase service to sign out
                  await SupabaseService().signOut();
                  
                  // Update user provider state
                  ref.read(userProvider.notifier).signOut();

                  if (context.mounted) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully logged out'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    // Navigate to login screen using go_router
                    context.go('/auth/login');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to logout. Please try again.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                ref.read(loadingProvider.notifier).state = LoadingState.initial;
              }
            },
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              SizedBox(width: 12),
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
                          SizedBox(width: 4),
                          Icon(Icons.verified, color: colorScheme.primary, size: 16),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) Divider(height: 16),
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
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
} 