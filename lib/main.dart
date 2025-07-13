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

class MyApp extends ConsumerWidget {
  final SharedPreferences prefs;
  final String? initialRoute;
  
  const MyApp({super.key, required this.prefs, this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final router = ref.watch(routerProvider(initialRoute));
    final networkStatus = ref.watch(networkStatusProvider);
    final appConfig = ref.watch(appConfigProvider);

    final isOffline = networkStatus.value == ConnectivityResult.none;
    final isMaintenance = appConfig.hasValue && (appConfig.value?['app_runs'] == false);

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
              Positioned.fill(
                child: MaintenanceScreen(
                  message: appConfig.value?['message'],
                  estimatedTime: appConfig.value?['estimated_time']?.toString(),
                ),
              )
            else if (isOffline)
              Positioned.fill(
                child: NoInternetScreen(
                  onRetry: () => ref.refresh(networkStatusProvider),
                ),
              ),
          ],
        );
      },
    );
  }
}
