import 'package:supabase_flutter/supabase_flutter.dart';

class UserState {
  final String? id;
  final String? email;
  final String? name;
  final String? phoneNumber;
  final String? referralCode;
  final DateTime? lastLogin;

  const UserState({
    this.id,
    this.email,
    this.name,
    this.phoneNumber,
    this.referralCode,
    this.lastLogin,
  });

  factory UserState.fromUser(User user) {
    final metadata = user.userMetadata ?? {};
    return UserState(
      id: user.id,
      email: user.email,
      name: metadata['display_name'] as String?,
      phoneNumber: metadata['phone_number'] as String?,
      referralCode: metadata['referral_code'] as String?,
      lastLogin: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
    );
  }

  UserState copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? referralCode,
    DateTime? lastLogin,
  }) {
    return UserState(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      referralCode: referralCode ?? this.referralCode,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
} 