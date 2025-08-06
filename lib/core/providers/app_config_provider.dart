import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class AppConfigNotifier extends StateNotifier<Map<String, dynamic>?> {
  RealtimeChannel? _channel;
  AppConfigNotifier() : super(null) {
    _init();
  }

  void _init() async {
    try {
      final supabase = SupabaseService().client;
      
      // Initial fetch with error handling
      final response = await supabase
          .from('app_config')
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      state = response as Map<String, dynamic>?;

      // Subscribe to realtime updates
      _channel = supabase.channel('public:app_config');

      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'app_config',
        callback: (payload) async {
          try {
            // Optionally, fetch the latest config again
            final updated = await supabase.from('app_config').select().single();
            state = updated as Map<String, dynamic>?;
          } catch (e) {
            AppLogger.error('Failed to fetch updated app config', e);
          }
        },
      );

      _channel!.subscribe();
    } on SocketException catch (e) {
      AppLogger.error('Network error loading app config', e);
      // Return default config for offline mode
      state = {
        'app_runs': true,
        'message': null,
        'estimated_time': null,
        'whatsapp_url': '',
        'telegram_url': '',
        'facebook_url': '',
        'youtube_url': '',
        'instagram_url': '',
        'twitter_url': '',
        'support_email': 'cashsify@gmail.com',
        'support_phone': '+91 80722 23275',
        'website_url': '',
        'playstore_url': '',
        'appstore_url': '',
      };
    } on http.ClientException catch (e) {
      AppLogger.error('HTTP error loading app config', e);
      // Return default config for HTTP errors
      state = {
        'app_runs': true,
        'message': null,
        'estimated_time': null,
        'whatsapp_url': '',
        'telegram_url': '',
        'facebook_url': '',
        'youtube_url': '',
        'instagram_url': '',
        'twitter_url': '',
        'support_email': 'cashsify@gmail.com',
        'support_phone': '+91 80722 23275',
        'website_url': '',
        'playstore_url': '',
        'appstore_url': '',
      };
    } catch (e) {
      AppLogger.error('Unexpected error loading app config', e);
      // Return default config for any other error
      state = {
        'app_runs': true,
        'message': null,
        'estimated_time': null,
        'whatsapp_url': '',
        'telegram_url': '',
        'facebook_url': '',
        'youtube_url': '',
        'instagram_url': '',
        'twitter_url': '',
        'support_email': 'cashsify@gmail.com',
        'support_phone': '+91 80722 23275',
        'website_url': '',
        'playstore_url': '',
        'appstore_url': '',
      };
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, Map<String, dynamic>?>((ref) {
  return AppConfigNotifier();
});

final socialMediaUrlsProvider = FutureProvider<Map<String, String>>((ref) async {
  final config = ref.watch(appConfigProvider);
  return {
    'whatsapp': config?['whatsapp_url'] as String? ?? '',
    'telegram': config?['telegram_url'] as String? ?? '',
    'facebook': config?['facebook_url'] as String? ?? '',
    'youtube': config?['youtube_url'] as String? ?? '',
    'instagram': config?['instagram_url'] as String? ?? '',
    'twitter': config?['twitter_url'] as String? ?? '',
  };
});

final contactInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final config = ref.watch(appConfigProvider);
  return {
    'email': config?['support_email'] as String? ?? 'cashsify@gmail.com',
    'phone': config?['support_phone'] as String? ?? '+91 80722 23275',
    'website': config?['website_url'] as String? ?? '',
    'playstore': config?['playstore_url'] as String? ?? '',
    'appstore': config?['appstore_url'] as String? ?? '',
  };
}); 