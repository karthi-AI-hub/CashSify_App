import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class that holds all app-wide constants and configuration values.
class AppConfig {
  // Required environment variables

  static const bool debug = bool.fromEnvironment('dart.vm.product', defaultValue: false);
  
  static const List<String> _requiredVariables = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // App Configuration
  static const String appName = 'Watch2Earn';
  static const String appVersion = '2.0';
  static const String slogan = 'Earn Cash Simply!';
  
  // Play Store URL
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.cashsify.android';
  
  // API Endpoints
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  
  // Feature Flags
  static bool get enableBiometrics => 
      dotenv.env['ENABLE_BIOMETRICS']?.toLowerCase() == 'true';
  static bool get enableSocialAuth => 
      dotenv.env['ENABLE_SOCIAL_AUTH']?.toLowerCase() == 'true';
  
  // Cache Configuration
  static int get cacheDuration => 
      int.tryParse(dotenv.env['CACHE_DURATION'] ?? '7') ?? 7;
  static int get maxCacheSize => 
      int.tryParse(dotenv.env['MAX_CACHE_SIZE'] ?? '100') ?? 100;

  /// Initialize the configuration by loading environment variables.
  /// This should be called before accessing any configuration values.
  static Future<void> initialize() async {
    await dotenv.load();
    _validateRequiredVariables();
  }

  /// Validates that all required environment variables are present.
  /// Throws [Exception] if any required variable is missing.
  static void _validateRequiredVariables() {
    final missingVariables = _requiredVariables
        .where((variable) => dotenv.env[variable]?.isEmpty ?? true)
        .toList();

    if (missingVariables.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVariables.join(', ')}',
      );
    }
  }
} 