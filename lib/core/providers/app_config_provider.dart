import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';

final appConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = SupabaseService().client;
  final response = await supabase.from('app_config').select().single();
  return response as Map<String, dynamic>;
}); 