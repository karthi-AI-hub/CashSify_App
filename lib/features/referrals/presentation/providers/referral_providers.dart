import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashsify_app/features/referrals/data/services/referral_service.dart';
import 'package:cashsify_app/core/providers/user_provider.dart';
import '../models/referral_history.dart';
import 'dart:convert';

// Service Provider
final referralServiceProvider = Provider((ref) => ReferralService());

// Stats Provider
final referralStatsProvider = FutureProvider((ref) async {
  final userId = ref.watch(userProvider).value?.id;
  if (userId == null) return null;
  
  final service = ref.watch(referralServiceProvider);
  return await service.getReferralStats(userId);
});

// History Provider
final referralHistoryProvider = FutureProvider((ref) async {
  final userId = ref.watch(userProvider).value?.id;
  if (userId == null) return <ReferralHistory>[];
  
  final service = ref.watch(referralServiceProvider);
  final rawList = await service.getReferralHistory(userId);
  return rawList.map<ReferralHistory>((item) => ReferralHistory.fromMap(item)).toList();
});

// Referral Code Provider
final referralCodeProvider = FutureProvider((ref) async {
  final userId = ref.watch(userProvider).value?.id;
  if (userId == null) return null;
  
  final service = ref.watch(referralServiceProvider);
  return service.getReferralCode(userId);
}); 