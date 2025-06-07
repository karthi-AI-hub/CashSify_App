import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_state.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserState?> {
  UserNotifier() : super(null) {
    // Initialize with current session if exists
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      state = UserState.fromUser(session.user);
    }

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            state = UserState.fromUser(session!.user);
          }
          break;
        case AuthChangeEvent.signedOut:
          state = null;
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            state = UserState.fromUser(session!.user);
          }
          break;
        default:
          break;
      }
    });
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: metadata,
        ),
      );
      if (response.user != null) {
        state = UserState.fromUser(response.user!);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = null;
  }
} 