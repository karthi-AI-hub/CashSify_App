import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/app/router/router.dart';
import 'package:cashsify_app/core/config/app_config.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'package:cashsify_app/core/utils/image_utils.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/utils/storage_viewer.dart';
import 'package:cashsify_app/theme/theme_provider.dart';
import 'package:cashsify_app/theme/app_theme.dart';
import 'package:cashsify_app/features/ads/presentation/providers/earnings_provider.dart';
import 'package:cashsify_app/features/ads/data/services/ad_service.dart';
import 'package:cashsify_app/core/providers/network_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cashsify_app/core/providers/app_config_provider.dart';
import 'package:cashsify_app/features/common_screens/no_internet_screen.dart';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/features/common_screens/maintenance_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:cashsify_app/theme/app_spacing.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode

final appLinks = AppLinks();
final navigatorKey = GlobalKey<NavigatorState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check for debug commands
  if (args.contains('--view-storage')) {
    await StorageViewer.printAllData();
    exit(0);
  }
  
  if (args.contains('--list-keys')) {
    await StorageViewer.listKeys();
    exit(0);
  }
  
  if (args.contains('--clear-storage')) {
    await StorageViewer.clearAllData();
    exit(0);
  }
  
  // Initialize logging
  await AppLogger.init();
  AppLogger.info('App startup: Logger initialized');
  
  // Initialize performance monitoring
  PerformanceUtils.startMonitoring();
  AppLogger.info('App startup: Performance monitoring started');
  
  // Load environment variables
  await dotenv.load();
  await AppConfig.initialize();
  AppLogger.info('App startup: Environment and AppConfig loaded');
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  AppLogger.info('App startup: SharedPreferences initialized');
  
  // --- Deep Link Handling ---
  String? initialRoute;
  try {
    final initialUri = await appLinks.getInitialAppLink();
    if (initialUri != null) {
      AppLogger.info('App startup: Initial deep link: ' + initialUri.toString());
      // Handle referral code in query or fragment
      String? refCode = initialUri.queryParameters['ref'];
      if ((refCode == null || refCode.isEmpty) && initialUri.fragment.isNotEmpty) {
        final fragParams = Uri.splitQueryString(initialUri.fragment);
        refCode = fragParams['ref'];
      }
      if (refCode != null && refCode.isNotEmpty) {
        await prefs.setString('pending_referral_code', refCode);
        AppLogger.info('App startup: Referral code set: $refCode');
      }
      // Handle /login-callback with query or fragment
      if (initialUri.host == 'login-callback' || initialUri.path == '/login-callback') {
        String params = initialUri.query;
        if ((params.isEmpty) && initialUri.fragment.isNotEmpty) {
          params = initialUri.fragment;
        }
        initialRoute = '/login-callback?$params';
        AppLogger.info('App startup: Initial route set to login-callback: $initialRoute');
      }
    }
  } catch (e) {
    AppLogger.error('App startup: Error handling initial deep link: $e');
  }
  // Listen for incoming links (while app is running)
  appLinks.uriLinkStream.listen((Uri? uri) async {
    if (uri != null) {
      AppLogger.info('App runtime: Incoming deep link: ' + uri.toString());
      String? refCode = uri.queryParameters['ref'];
      if ((refCode == null || refCode.isEmpty) && uri.fragment.isNotEmpty) {
        final fragParams = Uri.splitQueryString(uri.fragment);
        refCode = fragParams['ref'];
      }
      if (refCode != null && refCode.isNotEmpty) {
        await prefs.setString('pending_referral_code', refCode);
        AppLogger.info('App runtime: Referral code set: $refCode');
      }
      if ((uri.host == 'login-callback' || uri.path == '/login-callback')) {
        String params = uri.query;
        if ((params.isEmpty) && uri.fragment.isNotEmpty) {
          params = uri.fragment;
        }
        final route = '/login-callback?$params';
        AppLogger.info('App runtime: Navigating to login-callback: $route');
        GoRouter.of(navigatorKey.currentContext!).go(route);
      }
    }
  }, onError: (err) {
    AppLogger.error('App runtime: Error in uriLinkStream: $err');
  });
  // --- End Deep Link Handling ---
  
  // Initialize Supabase
  await SupabaseService().initialize(
    supabaseUrl: AppConfig.supabaseUrl,
    supabaseAnonKey: AppConfig.supabaseAnonKey,
  );
  AppLogger.info('App startup: Supabase initialized');
  
  // Preload common images
  await ImageUtils.preloadImages([
    // Add your common image URLs here
  ]);
  AppLogger.info('App startup: Images preloaded');

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  AppLogger.info('App startup: Google Mobile Ads SDK initialized');
  
  runApp(
    ProviderScope(
      overrides: [
        earningsProvider.overrideWith((ref) => EarningsNotifier(
          AdService(SupabaseService().supabase),
          SupabaseService().supabase,
        )),
      ],
      child: MyApp(prefs: prefs, initialRoute: initialRoute),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final SharedPreferences prefs;
  final String? initialRoute;

  const MyApp({super.key, required this.prefs, this.initialRoute});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  AppUpdateInfo? _updateInfo;
  bool _checkingUpdate = true;
  bool _updateRequired = false;
  bool _updateInProgress = false;
  String? _updateError;

  @override
  void initState() {
    super.initState();
    // Only check for updates in release mode
    if (!kDebugMode) {
      _checkForUpdate();
    } else {
      // Skip update check in debug mode
      setState(() {
        _checkingUpdate = false;
        _updateRequired = false;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    // Skip if in debug mode
    if (kDebugMode) {
      setState(() {
        _checkingUpdate = false;
        _updateRequired = false;
      });
      return;
    }

    setState(() {
      _checkingUpdate = true;
      _updateRequired = false;
      _updateInProgress = false;
      _updateError = null;
    });
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        setState(() {
          _updateInfo = info;
          _updateRequired = true;
        });
        await _startImmediateUpdate();
      } else {
        setState(() {
          _updateRequired = false;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = e.toString();
        _updateRequired = true; // Block app if update check fails
      });
    } finally {
      setState(() {
        _checkingUpdate = false;
      });
    }
  }

  Future<void> _startImmediateUpdate() async {
    setState(() {
      _updateInProgress = true;
    });
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) {
        setState(() {
          _updateRequired = false;
        });
      } else {
        setState(() {
          _updateError = 'Update was not completed. Please try again.';
          _updateRequired = true;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = e.toString();
        _updateRequired = true;
      });
    } finally {
      setState(() {
        _updateInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip update UI in debug mode
    if (kDebugMode) {
      final themeProvider = ref.watch(themeProviderProvider);
      final router = ref.watch(routerProvider(widget.initialRoute));
      final networkStatus = ref.watch(networkStatusProvider);
      final appConfig = ref.watch(appConfigProvider);

      final isOffline = networkStatus.value == ConnectivityResult.none;
      final isMaintenance = appConfig != null && appConfig['app_runs'] == false;

      return MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: false,
        builder: (context, child) {
          return Stack(
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child!,
              ),
              if (isMaintenance)
                Builder(
                  builder: (context) => Positioned.fill(
                    child: MaintenanceScreen(
                      message: appConfig?['message'],
                      estimatedTime: appConfig?['estimated_time']?.toString(),
                    ),
                  ),
                )
              else if (isOffline)
                Builder(
                  builder: (context) => Positioned.fill(
                    child: NoInternetScreen(
                      onRetry: () {
                        ref.refresh(networkStatusProvider);
                        ref.refresh(appConfigProvider);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // Original update logic for release mode
    if (_checkingUpdate || _updateInProgress) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_updateRequired) {
      final colorScheme = Theme.of(context).colorScheme;
      final isDarkMode = colorScheme.brightness == Brightness.dark;
      final textTheme = Theme.of(context).textTheme;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: colorScheme.background,
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Image.asset(
                    'assets/logo/logo.png',
                    width: 100,
                    height: 100,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Update Required',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  // Card for message, styled like wallet_screen.dart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.surface,
                    shadowColor: colorScheme.primary.withOpacity(0.08),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.system_update,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            _updateError != null
                                ? (_updateError!.contains('ERROR_APP_NOT_OWNED') || _updateError!.contains('not owned')
                                    ? 'This app was not installed from the Play Store. Please install or update the app from the Play Store to use in-app updates.'
                                    : 'There was a problem updating the app:\n\n${_updateError!}\nPlease try again. If the problem persists, update manually from the Play Store.')
                                : 'A new version of CashSify is available. Please update to continue using the app.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _updateError != null ? _checkForUpdate : null,
                    icon: Icon(Icons.refresh),
                    label: Text(_updateError != null ? 'Retry Update' : 'Updating...'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final themeProvider = ref.watch(themeProviderProvider);
    final router = ref.watch(routerProvider(widget.initialRoute));
    final networkStatus = ref.watch(networkStatusProvider);
    final appConfig = ref.watch(appConfigProvider);

    final isOffline = networkStatus.value == ConnectivityResult.none;
    final isMaintenance = appConfig != null && appConfig['app_runs'] == false;

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false, // Remove debug banner
      showPerformanceOverlay: false,
      builder: (context, child) {
        return Stack(
          children: [
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            ),
            // Only show maintenance screen if config loads successfully AND app_runs is false
            if (isMaintenance)
              Builder(
                builder: (context) => Positioned.fill(
                  child: MaintenanceScreen(
                    message: appConfig?['message'],
                    estimatedTime: appConfig?['estimated_time']?.toString(),
                  ),
                ),
              )
            else if (isOffline)
              Builder(
                builder: (context) => Positioned.fill(
                  child: NoInternetScreen(
                    onRetry: () {
                      ref.refresh(networkStatusProvider);
                      ref.refresh(appConfigProvider);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
