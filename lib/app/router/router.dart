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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/';
      final isLoginCallbackRoute = state.matchedLocation == '/login-callback';

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute && !isLoginCallbackRoute) {
        return '/auth/login';
      }

      // If authenticated and trying to access auth routes or onboarding
      if (isAuthenticated && (isAuthRoute || isOnboardingRoute)) {
        return '/dashboard';
      }

      // If not authenticated and on auth route, stay there
      if (!isAuthenticated && isAuthRoute) {
        return null;
      }

      // If not authenticated and not on auth route, go to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      // If authenticated and on protected route, stay there
      if (isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
        return null;
      }

      return null;
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
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
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
    ],
  );
}); 