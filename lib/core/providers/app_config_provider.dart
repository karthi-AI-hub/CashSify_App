import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigNotifier extends StateNotifier<Map<String, dynamic>?> {
  RealtimeChannel? _channel;
  AppConfigNotifier() : super(null) {
    _init();
  }

  void _init() async {
    final supabase = SupabaseService().client;
    // Initial fetch
    final response = await supabase.from('app_config').select().single();
    state = response as Map<String, dynamic>?;

    // Subscribe to realtime updates
    _channel = supabase
      .channel('public:app_config')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: 'UPDATE', schema: 'public', table: 'app_config'),
        (payload, [ref]) async {
          // Optionally, fetch the latest config again
          final updated = await supabase.from('app_config').select().single();
          state = updated as Map<String, dynamic>?;
        },
      )
      .subscribe();
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