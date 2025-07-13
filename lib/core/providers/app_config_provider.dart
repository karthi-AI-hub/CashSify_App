import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';

final appConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = SupabaseService().client;
  final response = await supabase.from('app_config').select().single();
  return response as Map<String, dynamic>;
});

final socialMediaUrlsProvider = FutureProvider<Map<String, String>>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  return {
    'whatsapp': config['whatsapp_url'] as String? ?? '',
    'telegram': config['telegram_url'] as String? ?? '',
    'facebook': config['facebook_url'] as String? ?? '',
    'youtube': config['youtube_url'] as String? ?? '',
    'instagram': config['instagram_url'] as String? ?? '',
    'twitter': config['twitter_url'] as String? ?? '',
  };
});

final contactInfoProvider = FutureProvider<Map<String, String>>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  return {
    'email': config['support_email'] as String? ?? 'cashsify@gmail.com',
    'phone': config['support_phone'] as String? ?? '+91 80722 23275',
    'website': config['website_url'] as String? ?? '',
    'playstore': config['playstore_url'] as String? ?? '',
    'appstore': config['appstore_url'] as String? ?? '',
  };
}); 