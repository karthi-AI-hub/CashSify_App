import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashsify_app/core/models/user_state.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      AppLogger.info('Fetching user data for ID: $userId');
      
      final response = await _supabase.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      AppLogger.info('Raw database response: $response');
      
      // Log each field to debug mapping issues
      AppLogger.info('User ID: ${response['id']}');
      AppLogger.info('User Email: ${response['email']}');
      AppLogger.info('User Name: ${response['name']}');
      AppLogger.info('Phone Number: ${response['phone_number']}');
      AppLogger.info('Gender: ${response['gender']}');
      AppLogger.info('DOB: ${response['dob']}');
      AppLogger.info('Coins: ${response['coins']}');
      AppLogger.info('Referral Code: ${response['referral_code']}');
      AppLogger.info('Referral Count: ${response['referral_count']}');
      AppLogger.info('Referred By: ${response['referred_by']}');
      AppLogger.info('UPI ID: ${response['upi_id']}');
      AppLogger.info('Bank Account: ${response['bank_account']}');
      AppLogger.info('Profile Image URL: ${response['profile_image_url']}');
      AppLogger.info('Last Login: ${response['last_login']}');
      AppLogger.info('Created At: ${response['created_at']}');
      AppLogger.info('Is Email Verified: ${response['is_email_verified']}');
      AppLogger.info('Is Profile Completed: ${response['is_profile_completed']}');

      final userState = UserState.fromJson(response);
      AppLogger.info('Parsed UserState: $userState');
      
      return userState;
    } catch (e) {
      AppLogger.error('Error fetching user data: $e');
      return UserState.fromUser(_supabase.client.auth.currentUser!);
    }
  }

  // Check and update profile completed status
  Future<void> checkAndUpdateProfileCompleted() async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return;

    final response = await _supabase.client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    final name = response['name'];
    final email = response['email'];
    final phone = response['phone_number'];
    final gender = response['gender'];
    final dob = response['dob'];
    final upiId = response['upi_id'];
    final bankAccount = response['bank_account'];

    final hasPayment = (upiId != null && upiId.toString().isNotEmpty) ||
                      (bankAccount != null && bankAccount.toString().isNotEmpty);

    final requiredFields = [name, email, phone, gender, dob];
    final isComplete = requiredFields.every((field) => field != null && field.toString().isNotEmpty) && hasPayment;

    await _supabase.client
        .from('users')
        .update({'is_profile_completed': isComplete})
        .eq('id', user.id);
  }

  // Check and update email verification status
  Future<void> checkAndUpdateEmailVerified() async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return;
    final isEmailVerified = user.emailConfirmedAt != null;
    await _supabase.client
        .from('users')
        .update({'is_email_verified': isEmailVerified})
        .eq('id', user.id);
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

      // Check and update profile completed status
      await checkAndUpdateProfileCompleted();
      // Check and update email verified status
      await checkAndUpdateEmailVerified();

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
          })
          .eq('id', user.id);

      // Optionally, trigger a check for verification status
      await checkAndUpdateEmailVerified();

      AppLogger.info('Email updated successfully');
    } catch (e) {
      AppLogger.error('Error updating email: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _supabase.client.auth.currentUser;
    final session = _supabase.client.auth.currentSession;
    if (user == null || session == null) throw Exception('No user logged in');

    // 1. Delete user data from your tables
    // await _supabase.client.from('users').delete().eq('id', user.id);

    // 2. Call the Edge Function to delete from Auth
    final url = 'https://huohftwbbqvhhqsabmzb.functions.supabase.co/delete-user';
    final accessToken = session.accessToken;

    print("Access Token : $accessToken");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': user.id}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }

    AppLogger.info('User account deleted successfully');
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
      await supabase.client.storage
        .from('users')
        .upload(filePath, file, fileOptions: FileOptions(upsert: true));

      // Get public URL with correct format
      final imageUrl = _supabase.client.storage
          .from('users')
          .getPublicUrl(filePath);

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

  // Debug method to test database connection and data retrieval
  Future<void> debugUserData() async {
    try {
      AppLogger.info('=== DEBUG: Testing User Data Retrieval ===');
      
      final currentUser = _supabase.client.auth.currentUser;
      AppLogger.info('Current auth user: ${currentUser?.id}');
      AppLogger.info('Current auth user email: ${currentUser?.email}');
      
      if (currentUser == null) {
        AppLogger.error('No authenticated user found');
        return;
      }

      // Test direct database query
      AppLogger.info('Testing direct database query...');
      final response = await _supabase.client
          .from('users')
          .select('*')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        AppLogger.error('No user data found in database for ID: ${currentUser.id}');
        return;
      }

      AppLogger.info('Database response keys: ${response.keys.toList()}');
      AppLogger.info('Full database response: $response');

      // Test UserState parsing
      try {
        final userState = UserState.fromJson(response);
        AppLogger.info('Successfully parsed UserState:');
        AppLogger.info('  - ID: ${userState.id}');
        AppLogger.info('  - Email: ${userState.email}');
        AppLogger.info('  - Name: ${userState.name}');
        AppLogger.info('  - Phone: ${userState.phoneNumber}');
        AppLogger.info('  - Coins: ${userState.coins}');
        AppLogger.info('  - Referral Code: ${userState.referralCode}');
        AppLogger.info('  - Is Email Verified: ${userState.isEmailVerified}');
        AppLogger.info('  - Is Profile Completed: ${userState.isProfileCompleted}');
      } catch (parseError) {
        AppLogger.error('Error parsing UserState: $parseError');
      }

      AppLogger.info('=== END DEBUG ===');
    } catch (e) {
      AppLogger.error('Debug error: $e');
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    await _supabase.client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }
}