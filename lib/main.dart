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
import 'package:cashsify_app/features/common_screens/no_internet_screen.dart';
import 'dart:io';

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
  AppLogger.init();
  
  // Initialize performance monitoring
  PerformanceUtils.startMonitoring();
  
  // Load environment variables
  await dotenv.load();
  await AppConfig.initialize();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // // Listen for referral code in initial link
  // try {
  //   final initialLink = await getInitialLink();
  //   if (initialLink != null) {
  //     final uri = Uri.parse(initialLink);
  //     final refCode = uri.queryParameters['ref'];
  //     if (refCode != null && refCode.isNotEmpty) {
  //       await prefs.setString('pending_referral_code', refCode);
  //     }
  //   }
  // } catch (e) {
  //   // Ignore errors
  // }
  
  // Initialize Supabase
  await SupabaseService().initialize(
    supabaseUrl: AppConfig.supabaseUrl,
    supabaseAnonKey: AppConfig.supabaseAnonKey,
  );
  
  // Preload common images
  await ImageUtils.preloadImages([
    // Add your common image URLs here
  ]);
  
  runApp(
    ProviderScope(
      overrides: [
        earningsProvider.overrideWith((ref) => EarningsNotifier(
          AdService(SupabaseService().supabase),
          SupabaseService().supabase,
        )),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final router = ref.watch(routerProvider);
    final networkStatus = ref.watch(networkStatusProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      builder: (context, child) {
        if (networkStatus.value == ConnectivityResult.none) {
          return NoInternetScreen(
            onRetry: () => ref.refresh(networkStatusProvider),
          );
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProviderProvider).isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashsify'),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProviderProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to Cashsify!'),
      ),
    );
  }
}
