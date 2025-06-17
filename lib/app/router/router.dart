import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/error/app_error.dart';
import 'package:cashsify_app/core/providers/auth_provider.dart';
import 'package:cashsify_app/features/onboarding/view/onboarding_screen.dart';
import 'package:cashsify_app/features/auth/presentation/screens/auth_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/';
      final isLoginCallbackRoute = state.matchedLocation == '/login-callback';

      // If the user is authenticated
      if (isAuthenticated) {
        // If they are trying to access auth routes or onboarding, redirect to dashboard
        if (isAuthRoute || isOnboardingRoute) {
          return '/dashboard';
        }
        // Otherwise, they are authenticated and on a valid protected route, so no redirect
        return null;
      } else {
        // If the user is NOT authenticated
        // If they are on the onboarding route, allow them to stay there
        if (isOnboardingRoute) {
          return null;
        }
        // If they are on an auth route or login callback, allow them to stay there
        if (isAuthRoute || isLoginCallbackRoute) {
          return null;
        }
        // If they are not authenticated and trying to access any other route, redirect to login
        return '/auth/login';
      }
    },
    errorBuilder: (context, state) => ErrorScreen(
      error: NetworkError(message: 'Navigation error: ${state.error?.message ?? "Unknown error"}'),
      onRetry: () => context.go('/'),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
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
        builder: (context, state, child) => AppLayout(child: child),
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
    ],
  );
}); 