import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/providers/network_provider.dart';
import '../../core/providers/app_config_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/navigation_provider.dart';
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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../core/utils/logger.dart';

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
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Ensure splash stays for at least 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _timerDone = true;
      _tryNavigate();
    });
    
    _prefetchReferralCode();
    
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFF5F6FA),
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF5F6FA),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryNavigate() async {
    AppLogger.info('SplashScreen: _tryNavigate called. _timerDone=$_timerDone, _dataReady=$_dataReady, _navigated=$_navigated');
    if (_timerDone && _dataReady && !_navigated && mounted) {
      _navigated = true;
      final user = SupabaseService().client.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (user != null) {
        AppLogger.info('SplashScreen: User is authenticated, navigating to dashboard');
        // User is authenticated
        final userService = UserService();
        userService.checkAndUpdateEmailVerified();
        SupabaseService().client.from('users').update({
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        _restoreAppState();
        context.go('/dashboard');
      } else {
        AppLogger.info('SplashScreen: User is NOT authenticated, onboardingComplete=$onboardingComplete');
        // User is not authenticated
        if (!onboardingComplete) {
          AppLogger.info('SplashScreen: Navigating to onboarding');
          context.go('/'); // Show onboarding
        } else {
          AppLogger.info('SplashScreen: Navigating to login');
          context.go('/auth/login'); // Go to login
        }
      }
    }
  }

  void _restoreAppState() {
    try {
      final appState = ref.read(appStateProvider.notifier);
      // Only restore if initialized
      if (appState.state.isInitialized) {
        final savedNavigationState = appState.loadNavigationState();
        
        if (savedNavigationState != null) {
          final currentIndex = savedNavigationState['currentIndex'] as int?;
          final title = savedNavigationState['title'] as String?;
          
          if (currentIndex != null && title != null) {
            ref.read(navigationProvider.notifier).setIndex(currentIndex);
          }
        }
      }
    } catch (e) {
      print('Error restoring app state: $e');
    }
  }

  Future<void> _prefetchReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final refCode = prefs.getString('pending_referral_code');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final networkStatus = ref.watch(networkStatusProvider);
    final appConfig = ref.watch(appConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!kIsWeb && networkStatus.value == ConnectivityResult.none) {
      return NoInternetScreen(onRetry: () => setState(() {}));
    }

    if (appConfig == null) {
      // Show loading or error (you may want to add error handling in your provider)
    }

    if (appConfig != null && appConfig['app_runs'] == false) {
      return MaintenanceScreen(
        message: appConfig?['message'],
        estimatedTime: appConfig?['estimated_time']?.toString(),
      );
    }

    if (((kIsWeb || networkStatus.hasValue) && appConfig != null) && !_dataReady) {
      _dataReady = true;
      Future.microtask(_tryNavigate);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              const Color(0xFFF5F6FA).withOpacity(0.8),
              const Color(0xFFE8EAF6).withOpacity(0.9),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Coin Rotation Effect
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(_controller.value * 6.283), // 360 degrees in radians
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFF9D423),
                                          Color(0xFFE65C00),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 3,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/logo/logo.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ).animate().scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 800.ms,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Welcome to CashSify',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Earn Cash Simply!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                          const SizedBox(height: AppSpacing.xl),
                          // Custom loading indicator with coin theme
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withOpacity(0.8),
                              ),
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  'Powered By CashSify',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}