import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/providers/network_provider.dart';
import '../../core/providers/app_config_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/user_service.dart';
import '../common_screens/no_internet_screen.dart';
import '../common_screens/maintenance_screen.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final AnimationController _controller;
  bool _canNavigate = false;
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    // Ensure splash stays for at least 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _canNavigate = true;
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_canNavigate && _dataReady && !_navigated && mounted) {
      _navigated = true;
      final user = SupabaseService().client.auth.currentUser;
      if (user != null) {
        // Update is_verified and last_login
        final userService = UserService();
        userService.checkAndUpdateEmailVerified();
        SupabaseService().client.from('users').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        context.go('/dashboard');
      } else {
        context.go('/'); // Onboarding
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final networkStatus = ref.watch(networkStatusProvider);
    final appConfig = ref.watch(appConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Network check
    if (networkStatus.value == ConnectivityResult.none) {
      return NoInternetScreen(onRetry: () => setState(() {}));
    }

    // Maintenance check
    if (appConfig.hasValue && (appConfig.value?['app_runs'] == false)) {
      return MaintenanceScreen(
      message: appConfig.value?['message'],
      estimatedTime: appConfig.value?['estimated_time']?.toString(),
      );
    }

    // If all good, show splash and proceed
    if (networkStatus.hasValue && appConfig.hasValue && !_dataReady) {
      _dataReady = true;
      Future.microtask(_tryNavigate);
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [colorScheme.background, colorScheme.surfaceVariant]
                : [colorScheme.primary.withOpacity(0.08), colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rotating logo
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_controller.value * 2 * 3.1415926535),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/logo/logo.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Welcome to CashSify',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Earn Cash Simply!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 