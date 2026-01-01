import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/features/onboarding/view/onboarding_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/register_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:cashsify_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:cashsify_app/features/error/presentation/screens/error_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/auth_callback_screen.dart';
import 'package:cashsify_app/presentation/widgets/app_layout.dart';
import 'package:cashsify_app/features/ads/presentation/screens/watch_ads_screen_new.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:cashsify_app/features/referrals/presentation/screens/referrals_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/withdraw_screen.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashsify_app/features/splash/splash_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cashsify_app/features/profile/presentation/screens/change_password_screen.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashsify_app/features/wallet/presentation/screens/withdraw_requirements_screen.dart';

// Ensures splash is only shown on cold start
class _SplashNavigationGuard {
  static bool hasNavigated = false;
}

final routerProvider =
    Provider.family<GoRouter, String?>((ref, initialLocation) {
  final authState = ref.watch(authProvider);

  // Determine initial location: if authenticated, go to dashboard, else splash
  String effectiveInitialLocation;
  if (authState.isAuthenticated) {
    effectiveInitialLocation = '/dashboard';
  } else {
    effectiveInitialLocation = initialLocation ?? '/splash';
  }

  return GoRouter(
    initialLocation: effectiveInitialLocation,
    redirect: (context, state) async {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/';
      final isLoginCallbackRoute =
          state.matchedLocation.startsWith('/login-callback');
      final isSplashRoute = state.matchedLocation == '/splash';

      // Check onboarding_complete flag
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      AppLogger.info(
          'Router redirect: isAuthenticated=$isAuthenticated, matchedLocation=${state.matchedLocation}, fullPath=${state.fullPath}, onboardingComplete=$onboardingComplete');

      // If on splash screen and already authenticated, skip splash
      if (isSplashRoute && isAuthenticated) {
        AppLogger.info(
            'Router redirect: Authenticated user on splash, redirecting to /dashboard');
        return '/dashboard';
      }

      // Only allow /splash on the very first navigation after app launch
      if (isSplashRoute && !isAuthenticated) {
        if (!_SplashNavigationGuard.hasNavigated) {
          _SplashNavigationGuard.hasNavigated = true;
          AppLogger.info(
              'Router redirect: First navigation, letting splash handle navigation');
          return null;
        } else {
          AppLogger.info(
              'Router redirect: Not initial navigation, redirecting to /auth/login');
          // Instead of redirecting to /auth/login, just return null if already on /auth/login
          if (state.matchedLocation != '/auth/login') {
            return '/auth/login';
          }
          return null;
        }
      }

      if (isAuthenticated) {
        // Allow authenticated users to access specific auth screens
        if (state.matchedLocation == '/auth/reset-password' ||
            state.matchedLocation == '/auth/login' ||
            isLoginCallbackRoute) {
          AppLogger.info(
              'Router redirect: Authenticated user accessing auth route, allowing: ${state.matchedLocation}');
          return null;
        }

        // If authenticated and on other auth/onboarding routes, redirect to dashboard
        if (isAuthRoute || isOnboardingRoute) {
          AppLogger.info(
              'Router redirect: Authenticated user on auth/onboarding, redirecting to /dashboard');
          return '/dashboard';
        }
        AppLogger.info('Router redirect: Authenticated user, no redirect');
        return null;
      } else {
        // If not authenticated and not on any /auth route, redirect to /auth/login
        if (!isAuthenticated && !state.matchedLocation.startsWith('/auth')) {
          return '/auth/login';
        }
        // If onboarding is not complete, allow onboarding route
        if (!onboardingComplete && isOnboardingRoute) {
          AppLogger.info(
              'Router redirect: Unauthenticated user, onboarding not complete, allowing onboarding');
          return null;
        }
        // If on an auth route or login callback, allow
        if (isAuthRoute || isLoginCallbackRoute) {
          AppLogger.info(
              'Router redirect: Unauthenticated user on auth/login-callback, allowing');
          return null;
        }
        // If onboarding is complete, always redirect to login, but only if not already on /auth/login
        if (onboardingComplete && state.matchedLocation != '/auth/login') {
          AppLogger.info(
              'Router redirect: Unauthenticated user, onboarding complete, redirecting to /auth/login');
          return '/auth/login';
        }
        // If already on /auth/login, do not redirect
        return null;
      }
    },
    errorBuilder: (context, state) => ErrorScreen(
      error: NetworkError(
          message:
              'Navigation error: \\${state.error?.message ?? "Unknown error"}'),
      onRetry: () => context.go('/'),
    ),
    routes: [
      // Initial splash screen - handles auth state and navigation
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding screen - shown only if onboarding_complete is false
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Authentication routes
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
      GoRoute(
        path: '/auth/forgot-password',
        name: 'auth-forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Main app shell - requires authentication
      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/watch-ads',
            name: 'watch-ads',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/referrals',
            name: 'referrals',
            builder: (context, state) => const ReferralsScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
      // Error handling
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
        builder: (context, state) {
          final allParams = <String, String>{};
          allParams.addAll(state.uri.queryParameters);

          // Parse fragment parameters if present
          if (state.uri.fragment.isNotEmpty) {
            try {
              allParams.addAll(Uri.splitQueryString(state.uri.fragment));
            } catch (e) {
              AppLogger.warning('Failed to parse fragment parameters: $e');
            }
          }

          return AuthCallbackScreen(queryParams: allParams);
        },
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/withdraw',
        name: 'withdraw',
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: '/withdraw-requirements',
        name: 'withdraw-requirements',
        builder: (context, state) => const WithdrawRequirementsScreen(),
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
