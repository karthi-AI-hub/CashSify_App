import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/features/onboarding/view/onboarding_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/register_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cashsify_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:cashsify_app/features/error/presentation/screens/error_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/auth_callback_screen.dart';
import 'package:cashsify_app/presentation/widgets/app_layout.dart';
import 'package:cashsify_app/features/ads/presentation/screens/watch_ads_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:cashsify_app/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/withdraw_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashsify_app/features/splash/splash_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/forgot_password_screen.dart' as profile_forgot;
import 'package:cashsify_app/features/referrals/presentation/screens/referral_history_screen.dart';
import 'package:cashsify_app/features/common_screens/contact_us_screen.dart';
import 'package:cashsify_app/features/common_screens/faq_screen.dart';
import 'package:cashsify_app/features/common_screens/terms_screen.dart';
import 'package:cashsify_app/features/common_screens/privacy_policy_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/about_us_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/debug_storage_screen.dart';
import 'package:cashsify_app/features/ads/presentation/screens/verification_screen.dart';
import 'package:flutter/services.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_dialog.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:cashsify_app/core/utils/logger.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/';
      final isLoginCallbackRoute = state.matchedLocation == '/login-callback';

      // Check onboarding_complete flag
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (isAuthenticated) {
        if (isAuthRoute || isOnboardingRoute) {
          return '/dashboard';
        }
        return null;
      } else {
        // If onboarding is not complete, allow onboarding route
        if (!onboardingComplete && isOnboardingRoute) {
          return null;
        }
        // If on an auth route or login callback, allow
        if (isAuthRoute || isLoginCallbackRoute) {
          return null;
        }
        // If onboarding is complete, always redirect to login
        return '/auth/login';
      }
    },
    errorBuilder: (context, state) => ErrorScreen(
      error: NetworkError(message: 'Navigation error: ${state.error?.message ?? "Unknown error"}'),
      onRetry: () => context.go('/'),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          // Temporarily remove WillPopScope to test if back button reaches Dashboard
          return AppLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const SizedBox(), // Empty because IndexedStack handles it
          ),
          GoRoute(
            path: '/watch-ads',
            name: 'watch-ads',
            builder: (context, state) => const SizedBox(), // Empty because IndexedStack handles it
          ),
          GoRoute(
            path: '/referrals',
            name: 'referrals',
            builder: (context, state) => const ReferralsScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const SizedBox(), // Empty because IndexedStack handles it
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const SizedBox(), // Empty because IndexedStack handles it
          ),
        ],
      ),
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) => ErrorScreen(
          error: NetworkError(message: 'An error occurred'),
          onRetry: () => context.go('/'),
        ),
      ),
      GoRoute(
        path: '/login-callback',
        name: 'login-callback',
        builder: (context, state) => AuthCallbackScreen(
          queryParams: state.uri.queryParameters,
        ),
      ), // Handles all Supabase auth callbacks (verify, reset, magiclink)
      GoRoute(
        path: '/withdraw',
        name: 'withdraw',
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: '/transaction-history',
        name: 'transaction-history',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const profile_forgot.ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/referral-history',
        name: 'referral-history',
        builder: (context, state) => const ReferralHistoryScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        name: 'contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/about-us',
        name: 'about-us',
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: '/delete-account',
        name: 'delete-account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/debug-storage',
        name: 'debug-storage',
        builder: (context, state) => const DebugStorageScreen(),
      ),
      GoRoute(
        path: '/verification',
        name: 'verification',
        builder: (context, state) => const VerificationScreen(),
      ),
    ],
  );
}); 