import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
}); 