import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/models/user_state.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:io';

class UserService {
  final _supabase = SupabaseService();
  SupabaseService get supabase => _supabase;

  // Get current user state
  Future<UserState?> getCurrentUserState() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserState.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting user state: $e');
      return null;
    }
  }

  // Get user data by ID
  Future<UserState> getUserData(String userId) async {
    try {
      final response = await _supabase.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserState.fromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching user data: $e');
      return UserState.fromUser(_supabase.client.auth.currentUser!);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dob,
    String? upiId,
    Map<String, dynamic>? bankAccount,
    String? profileImageUrl,
  }) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final data = {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dob': dob.toIso8601String(),
        if (upiId != null) 'upi_id': upiId,
        if (bankAccount != null) 'bank_account': bankAccount,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        'profile_updated_at': DateTime.now().toIso8601String(),
      };

      // Update user metadata in auth
      await _supabase.client.auth.updateUser(
        UserAttributes(
          data: data,
        ),
      );

      // Update user profile in database
      await _supabase.client
          .from('users')
          .update(data)
          .eq('id', user.id);

      AppLogger.info('User profile updated successfully');
    } catch (e) {
      AppLogger.error('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update user coins
  Future<void> updateUserCoins(int coins) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabase.client.rpc('update_user_coins', params: {
        'user_id': user.id,
        'coins': coins,
      });
      AppLogger.info('User coins updated successfully');
    } catch (e) {
      AppLogger.error('Error updating user coins: $e');
      rethrow;
    }
  }

  // Update verification status
  Future<void> updateVerificationStatus({
    bool? isPhoneVerified,
    bool? isEmailVerified,
  }) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final data = {
        if (isPhoneVerified != null) 'is_phone_verified': isPhoneVerified,
        if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
      };

      await _supabase.client
          .from('users')
          .update(data)
          .eq('id', user.id);

      AppLogger.info('User verification status updated successfully');
    } catch (e) {
      AppLogger.error('Error updating verification status: $e');
      rethrow;
    }
  }

  // Update phone number
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabase.client
          .from('users')
          .update({
            'phone_number': phoneNumber,
            'is_phone_verified': true,
          })
          .eq('id', user.id);

      AppLogger.info('Phone number updated successfully');
    } catch (e) {
      AppLogger.error('Error updating phone number: $e');
      rethrow;
    }
  }

  // Update email
  Future<void> updateEmail(String email) async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabase.client.auth.updateUser(
        UserAttributes(
          email: email,
        ),
      );

      await _supabase.client
          .from('users')
          .update({
            'email': email,
            'is_email_verified': true,
          })
          .eq('id', user.id);

      AppLogger.info('Email updated successfully');
    } catch (e) {
      AppLogger.error('Error updating email: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _supabase.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from users table
      await _supabase.client
          .from('users')
          .delete()
          .eq('id', user.id);

      // Delete the user account
      await _supabase.client.auth.admin.deleteUser(user.id);

      AppLogger.info('User account deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting account: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.client.auth.signOut();
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Error signing out: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File file, String userId) async {
    try {
      // Validate file
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      // Validate file size (max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size must be less than 5MB');
      }

      final fileExt = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExt)) {
        throw Exception('Only JPG and PNG files are allowed');
      }

      // Use consistent file naming
      final fileName = 'profile_$userId.$fileExt';
      final filePath = 'profile-images/$fileName';

      // Upload file to storage
      await _supabase.client.storage
          .from('users')
          .upload(filePath, file);

      // Get public URL with correct format
      final imageUrl = _supabase.client.storage
          .from('users')
          .getPublicUrl(filePath)
          .replaceAll('/object/public/', '/storage/v1/object/public/');

      // Update user profile with new image URL
      await _supabase.client
          .from('users')
          .update({
            'profile_image_url': imageUrl,
            'profile_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      AppLogger.info('Profile image uploaded successfully');
      return imageUrl;
    } catch (e) {
      AppLogger.error('Error uploading profile image: $e');
      rethrow;
    }
  }
} 