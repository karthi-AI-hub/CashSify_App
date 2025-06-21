import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_state.freezed.dart';
part 'user_state.g.dart';

@freezed
class UserState with _$UserState {
  const UserState._(); // <-- Add this line

  const factory UserState({
    @JsonKey(defaultValue: '') required String id,
    required String email,
    String? name,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? gender,
    DateTime? dob,
    required int coins,
    @JsonKey(name: 'referral_code') required String referralCode,
    @JsonKey(name: 'referral_count') int? referralCount,
    @JsonKey(name: 'referred_by') String? referredBy,
    @JsonKey(name: 'upi_id') String? upiId,
    @JsonKey(name: 'bank_account') Map<String, dynamic>? bankAccount,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'is_email_verified') bool? isEmailVerified,
    @JsonKey(name: 'is_profile_completed') bool? isProfileCompleted,
  }) = _UserState;

  factory UserState.fromJson(Map<String, dynamic> json) => _$UserStateFromJson(json);

  // You can keep this factory if you need it for Supabase User mapping
  factory UserState.fromUser(User user) {
    final metadata = user.userMetadata ?? {};
    final appMetadata = user.appMetadata ?? {};
    return UserState(
      id: user.id,
      email: user.email ?? '',
      phoneNumber: metadata['phone_number'] as String?,
      name: metadata['name'] as String? ?? 'User',
      gender: metadata['gender'] as String?,
      dob: metadata['dob'] != null ? DateTime.tryParse(metadata['dob'] as String) : null,
      coins: appMetadata['coins'] as int? ?? 0,
      referralCode: metadata['referral_code'] as String? ?? '',
      referralCount: metadata['referral_count'] as int?,
      referredBy: metadata['referred_by'] as String?,
      upiId: metadata['upi_id'] as String?,
      bankAccount: metadata['bank_account'] as Map<String, dynamic>?,
      profileImageUrl: metadata['profile_image_url'] as String?,
      lastLogin: metadata['last_login'] != null 
          ? DateTime.tryParse(metadata['last_login'] as String)
          : null,
      createdAt: DateTime.parse(user.createdAt),
      isEmailVerified: metadata['is_email_verified'] as bool? ?? false,
      isProfileCompleted: metadata['is_profile_completed'] as bool? ?? false,
    );
  }
}