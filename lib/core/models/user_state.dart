import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_state.freezed.dart';
part 'user_state.g.dart';

@freezed
@JsonSerializable()
class UserState with _$UserState {
  const factory UserState({
    required String id,
    required String email,
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dob,
    required int coins,
    required String referralCode,
    int? referralCount,
    String? referredBy,
    String? upiId,
    Map<String, dynamic>? bankAccount,
    required bool isVerified,
    String? profileImageUrl,
    DateTime? lastLogin,
    required DateTime createdAt,
    bool? isEmailVerified,
    bool? isProfileCompleted,
  }) = _UserState;

  factory UserState.fromJson(Map<String, dynamic> json) {
    return _$UserStateFromJson({
      ...json,
      'name': json['name'] ?? 'User',
      'gender': json['gender'],
      'dob': json['dob'],
      'coins': json['coins'] ?? 0,
      'referralCode': json['referral_code'] ?? '',
      'isVerified': json['is_verified'] ?? false,
      'isEmailVerified': json['is_email_verified'] ?? false,
      'isProfileCompleted': json['is_profile_completed'] ?? true,
      'phoneNumber': json['phone_number'],
      'referralCount': json['referral_count'],
      'referredBy': json['referred_by'],
      'upiId': json['upi_id'],
      'bankAccount': json['bank_account'],
      'profileImageUrl': json['profile_image_url'],
      'lastLogin': json['last_login'],
      'createdAt': json['created_at'] ?? json['createdAt'],
    });
  }

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
      isVerified: appMetadata['is_verified'] as bool? ?? false,
      profileImageUrl: metadata['profile_image_url'] as String?,
      lastLogin: metadata['last_login'] != null 
          ? DateTime.tryParse(metadata['last_login'] as String)
          : null,
      createdAt: DateTime.parse(user.createdAt),
      isEmailVerified: metadata['is_email_verified'] as bool? ?? false,
    );
  }
} 