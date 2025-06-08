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
import 'package:cashsify_app/theme/theme_provider.dart';
import 'package:cashsify_app/theme/app_theme.dart';
import 'package:cashsify_app/features/ads/presentation/providers/earnings_provider.dart';
import 'package:cashsify_app/features/ads/data/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  AppLogger.init();
  
  // Initialize performance monitoring
  PerformanceUtils.startMonitoring();
  
  // Load environment variables
  await dotenv.load();
  await AppConfig.initialize();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
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
    
    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      builder: (context, child) {
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
