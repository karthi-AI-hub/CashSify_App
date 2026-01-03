import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logAdWatched() async {
    await _analytics.logEvent(
      name: 'ad_watched',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logCoinsEarned(int amount) async {
    await _analytics.logEvent(
      name: 'coins_earned',
      parameters: {
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logWithdrawalRequested(double amount, String method) async {
    await _analytics.logEvent(
      name: 'withdrawal_requested',
      parameters: {
        'amount': amount,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logReferralShared() async {
    await _analytics.logEvent(
      name: 'referral_shared',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }
}
