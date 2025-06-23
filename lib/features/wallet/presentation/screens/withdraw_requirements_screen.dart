import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/widgets/layout/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawRequirementsScreen extends ConsumerWidget {
  const WithdrawRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final loading = ref.watch(loadingProvider) == LoadingState.loading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Redeem Requirements',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.onPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.07),
              colorScheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Please log in to view requirements.'));
            }
            final requirements = [
              (
                'Minimum 15,000 coins',
                user.coins >= 15000,
                'You need at least 15,000 coins to redeem. Earn more by watching ads and referring friends.',
                null,
                Icons.stars_rounded,
                null,
                Colors.amber,
              ),
              (
                'Profile 100% complete',
                user.isProfileCompleted ?? false,
                'Complete your profile with all required details to enable redeem coins.',
                () => context.push('/edit-profile'),
                Icons.person_rounded,
                'Complete Profile',
                Colors.blueAccent,
              ),
              (
                'Email verified',
                user.isEmailVerified ?? false,
                'Verify your email to enable redeem coins. Check your inbox for a verification link.',
                () async {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) {
                      return _VerifyEmailGuide(
                        email: user.email,
                        onResend: () async {
                          ref.read(loadingProvider.notifier).startLoading();
                          try {
                            final response = await SupabaseService().client.auth.resend(
                              type: OtpType.signup,
                              email: user.email,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: colorScheme.surface),
                                      SizedBox(width: 12),
                                      Text('Verification email resent!'),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: colorScheme.surface),
                                      SizedBox(width: 12),
                                      Text('Failed to resend email: $e'),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            }
                          } finally {
                            ref.read(loadingProvider.notifier).finishLoading();
                          }
                        },
                      );
                    },
                  );
                },
                Icons.email_rounded,
                'Verify Email',
                Colors.deepPurple,
              ),
              (
                'At least 5 referrals',
                (user.referralCount ?? 0) >= 5,
                'Invite at least 5 friends to join CashSify using your referral code.',
                () => context.push('/referrals'),
                Icons.group_rounded,
                'Invite Friends',
                Colors.green,
              ),
            ];

            final metCount = requirements.where((r) => r.$2).length;
            final allMet = metCount == requirements.length;

            return SafeArea(
              child: Center(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(userProvider.notifier).refreshUser();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.emoji_events, size: 64, color: colorScheme.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'Ready to Redeem?',
                                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete all requirements below to redeem your coins.',
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Animated progress bar
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: metCount / requirements.length),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: colorScheme.surfaceVariant,
                              color: allMet ? Colors.green : colorScheme.primary,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Requirements (${metCount}/${requirements.length})',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...requirements.map((r) => _RequirementTile(
                            label: r.$1,
                            met: r.$2,
                            description: r.$3,
                            action: r.$4,
                            icon: r.$5,
                            actionLabel: r.$6,
                            iconColor: r.$7,
                            loading: loading,
                          )),
                          const SizedBox(height: 24),
                          if (!allMet)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tip: Use the given buttons to complete each requirement.',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (allMet)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                onPressed: () => context.go('/withdraw'),
                                label: const Text('Proceed to Withdraw'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  final String label;
  final bool met;
  final String? description;
  final VoidCallback? action;
  final IconData? icon;
  final String? actionLabel;
  final Color? iconColor;
  final bool loading;
  const _RequirementTile({
    required this.label,
    required this.met,
    this.description,
    this.action,
    this.icon,
    this.actionLabel,
    this.iconColor,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: met
              ? Icon(Icons.check_circle, color: Colors.green, size: 32, key: const ValueKey('met'))
              : Icon(icon ?? Icons.cancel, color: iconColor ?? colorScheme.error, size: 32, key: const ValueKey('not_met')),
        ),
        title: Text(label, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: !met && description != null ? Text(description!, style: textTheme.bodyMedium) : null,
        trailing: !met && action != null
            ? ElevatedButton(
                onPressed: loading ? null : action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(actionLabel ?? 'Fix'),
              )
            : null,
      ),
    );
  }
}

class _VerifyEmailGuide extends StatelessWidget {
  final String email;
  final Future<void> Function() onResend;
  const _VerifyEmailGuide({required this.email, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(
            child: Icon(Icons.email_rounded, size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('How to Verify Your Email', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          _StepTile(
            step: 1,
            text: 'Tap the button below to resend the verification email to:',
            subText: email,
            icon: Icons.send_rounded,
          ),
          _StepTile(
            step: 2,
            text: 'Check your inbox (and spam folder) for an email from CashSify.',
            icon: Icons.inbox_rounded,
          ),
          _StepTile(
            step: 3,
            text: 'Click the verification link in the email to confirm your account.',
            icon: Icons.link_rounded,
          ),
          _StepTile(
            step: 4,
            text: 'Return to the app and refresh this page.',
            icon: Icons.refresh_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: onResend,
                  label: const Text('Resend Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mail_outline_rounded),
                  onPressed: () async {
                    // Try to open the default mail app inbox
                    bool opened = false;
                    // Android intent for email inbox
                    const androidIntent = 'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.APP_EMAIL;end';
                    // iOS URL scheme for mail app
                    const iosUrl = 'message://';
                    try {
                      if (Theme.of(context).platform == TargetPlatform.android) {
                        if (await canLaunchUrl(Uri.parse(androidIntent))) {
                          await launchUrl(Uri.parse(androidIntent));
                          opened = true;
                        }
                      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
                        if (await canLaunchUrl(Uri.parse(iosUrl))) {
                          await launchUrl(Uri.parse(iosUrl));
                          opened = true;
                        }
                      }
                    } catch (_) {}
                    if (!opened) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: colorScheme.surface),
                              SizedBox(width: 12),
                              Text('Could not open mail inbox.'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    }
                  },
                  label: const Text('Open Mail App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final String text;
  final String? subText;
  final IconData icon;
  const _StepTile({required this.step, required this.text, this.subText, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text('$step', style: textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: textTheme.bodyLarge),
                if (subText != null)
                  Text(subText!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}