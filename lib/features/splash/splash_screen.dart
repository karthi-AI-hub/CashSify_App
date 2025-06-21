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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    // Ensure splash stays for at least 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _timerDone = true;
      _tryNavigate();
    });
    // Optionally, prefetch referral code for onboarding/register
    _prefetchReferralCode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    print('_tryNavigate called: _timerDone=$_timerDone, _dataReady=$_dataReady, _navigated=$_navigated, mounted=$mounted');
    if (_timerDone && _dataReady && !_navigated && mounted) {
      _navigated = true;
      final user = SupabaseService().client.auth.currentUser;
      print('User: $user');
      if (user != null) {
        print('Navigating to /dashboard');
        // Update is_verified and last_login (is_verified will only be true if user has actually verified email)
        final userService = UserService();
        userService.checkAndUpdateEmailVerified();
        SupabaseService().client.from('users').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        context.go('/dashboard');
      } else {
        print('Navigating to /');
        context.go('/'); // Onboarding
      }
    }
  }

  Future<void> _prefetchReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final refCode = prefs.getString('pending_referral_code');
    // Optionally, you could pass this to a provider if needed
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final networkStatus = ref.watch(networkStatusProvider);
    final appConfig = ref.watch(appConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Network check (skip on web)
    if (!kIsWeb && networkStatus.value == ConnectivityResult.none) {
      return NoInternetScreen(onRetry: () => setState(() {}));
    }

    // App config error handling
    if (appConfig.hasError) {
      return Scaffold(
        body: Center(child: Text('Error loading app config: \\${appConfig.error}')),
      );
    }

    // Maintenance check
    if (appConfig.hasValue && (appConfig.value?['app_runs'] == false)) {
      return MaintenanceScreen(
      message: appConfig.value?['message'],
      estimatedTime: appConfig.value?['estimated_time']?.toString(),
      );
    }

    // If all good, show splash and proceed
    if (((kIsWeb || networkStatus.hasValue) && appConfig.hasValue) && !_dataReady) {
      _dataReady = true;
      Future.microtask(_tryNavigate);
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorScheme.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rotating logo (left to right, Y-axis 0 to pi)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_controller.value * 3.1415926535),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.08),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/logo/logo.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
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
                  const SizedBox(height: AppSpacing.xl),
                  const Spacer(),
                  Text(
                    'Powered By CashSify',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 