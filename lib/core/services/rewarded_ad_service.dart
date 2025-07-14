import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  static const String adUnitIdA = 'ca-app-pub-7086602185948470/1291652554';
  static const String adUnitIdB = 'ca-app-pub-7086602185948470/8767182851';
  static const String adUnitIdC = 'ca-app-pub-7086602185948470/6802235192';

  RewardedAd? _adA;
  RewardedAd? _adB;
  RewardedAd? _adC;

  bool _isLoadingA = false;
  bool _isLoadingB = false;
  bool _isLoadingC = false;

  DateTime? _adALoadedAt;
  DateTime? _adBLoadedAt;
  DateTime? _adCLoadedAt;

  int _adAExponentialBackoff = 2;
  int _adBExponentialBackoff = 2;
  int _adCExponentialBackoff = 2;

  Timer? _expiryTimerA;
  Timer? _expiryTimerB;
  Timer? _expiryTimerC;

  static const int _maxBackoff = 300; // 5 min
  static const int _adExpirySeconds = 3600; // 1 hour

  bool _hasInitialized = false;

  // Diagnostics: Print loaded ad unit and timestamp
  void _logAdLoaded(String adUnitId) {
    debugPrint('[RewardedAdService] Ad loaded: $adUnitId at ${DateTime.now()}');
  }

  void _loadAdA() {
    if (_adA != null || _isLoadingA) return;
    _isLoadingA = true;
    RewardedAd.load(
      adUnitId: adUnitIdA,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adA = ad;
          _isLoadingA = false;
          _adALoadedAt = DateTime.now();
          _adAExponentialBackoff = 1;
          _logAdLoaded(adUnitIdA);
          _scheduleExpiry('A');
        },
        onAdFailedToLoad: (error) {
          _adA = null;
          _isLoadingA = false;
          _scheduleRetry(_loadAdA, 'A');
        },
      ),
    );
  }

  void _loadAdB() {
    if (_adB != null || _isLoadingB) return;
    _isLoadingB = true;
    RewardedAd.load(
      adUnitId: adUnitIdB,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adB = ad;
          _isLoadingB = false;
          _adBLoadedAt = DateTime.now();
          _adBExponentialBackoff = 1;
          _logAdLoaded(adUnitIdB);
          _scheduleExpiry('B');
        },
        onAdFailedToLoad: (error) {
          _adB = null;
          _isLoadingB = false;
          _scheduleRetry(_loadAdB, 'B');
        },
      ),
    );
  }

  void _loadAdC() {
    if (_adC != null || _isLoadingC) return;
    _isLoadingC = true;
    RewardedAd.load(
      adUnitId: adUnitIdC,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adC = ad;
          _isLoadingC = false;
          _adCLoadedAt = DateTime.now();
          _adCExponentialBackoff = 1;
          _logAdLoaded(adUnitIdC);
          _scheduleExpiry('C');
        },
        onAdFailedToLoad: (error) {
          _adC = null;
          _isLoadingC = false;
          _scheduleRetry(_loadAdC, 'C');
        },
      ),
    );
  }

  // Only call this on app launch or screen entry
  void loadAllAds() {
    if (_hasInitialized) return;
    _hasInitialized = true;
    _loadAdA();
    Future.delayed(const Duration(seconds: 2), _loadAdB);
    Future.delayed(const Duration(seconds: 4), _loadAdC);
  }

  void _scheduleRetry(void Function() loadAd, String label) {
    int delay;
    switch (label) {
      case 'A':
        delay = _adAExponentialBackoff;
        _adAExponentialBackoff = (_adAExponentialBackoff * 2).clamp(2, _maxBackoff);
        break;
      case 'B':
        delay = _adBExponentialBackoff;
        _adBExponentialBackoff = (_adBExponentialBackoff * 2).clamp(2, _maxBackoff);
        break;
      case 'C':
        delay = _adCExponentialBackoff;
        _adCExponentialBackoff = (_adCExponentialBackoff * 2).clamp(2, _maxBackoff);
        break;
      default:
        delay = 2;
    }
    debugPrint('[RewardedAdService] Retrying Ad$label in $delay seconds');
    Future.delayed(Duration(seconds: delay), () {
      switch (label) {
        case 'A':
          _loadAdA();
          break;
        case 'B':
          _loadAdB();
          break;
        case 'C':
          _loadAdC();
          break;
      }
    });
  }

  void _scheduleExpiry(String label) {
    void reload() {
      debugPrint('[RewardedAdService] Ad$label expired, reloading');
      switch (label) {
        case 'A':
          _adA = null;
          _loadAdA();
          break;
        case 'B':
          _adB = null;
          _loadAdB();
          break;
        case 'C':
          _adC = null;
          _loadAdC();
          break;
      }
    }
    switch (label) {
      case 'A':
        _expiryTimerA?.cancel();
        _expiryTimerA = Timer(Duration(seconds: _adExpirySeconds), reload);
        break;
      case 'B':
        _expiryTimerB?.cancel();
        _expiryTimerB = Timer(Duration(seconds: _adExpirySeconds), reload);
        break;
      case 'C':
        _expiryTimerC?.cancel();
        _expiryTimerC = Timer(Duration(seconds: _adExpirySeconds), reload);
        break;
    }
  }

  bool _isAdExpired(DateTime? loadedAt) {
    if (loadedAt == null) return true;
    return DateTime.now().difference(loadedAt).inSeconds > _adExpirySeconds;
  }

  // Only reload the specific ad after show/fail
  Future<bool> showAvailableAd({
    required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
    required VoidCallback onAdFailedToShow,
  }) async {
    if (_adA != null) {
      debugPrint('[RewardedAdService] Showing AdA');
      _showAd(_adA!, 'A', onUserEarnedReward, () {
        _adA = null;
        _loadAdA();
        onAdDismissed();
      }, () {
        _adA = null;
        _loadAdA();
        onAdFailedToShow();
      });
      return true;
    } else if (_adB != null) {
      debugPrint('[RewardedAdService] Showing AdB');
      _showAd(_adB!, 'B', onUserEarnedReward, () {
        _adB = null;
        _loadAdB();
        onAdDismissed();
      }, () {
        _adB = null;
        _loadAdB();
        onAdFailedToShow();
      });
      return true;
    } else if (_adC != null) {
      debugPrint('[RewardedAdService] Showing AdC');
      _showAd(_adC!, 'C', onUserEarnedReward, () {
        _adC = null;
        _loadAdC();
        onAdDismissed();
      }, () {
        _adC = null;
        _loadAdC();
        onAdFailedToShow();
      });
      return true;
    }
    debugPrint('[RewardedAdService] No ad available to show.');
    return false;
  }

  void _showAd(
    RewardedAd ad,
    String label,
    void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    VoidCallback onAdDismissed,
    VoidCallback onAdFailedToShow,
  ) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('[RewardedAdService] Ad$label shown'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[RewardedAdService] Ad$label dismissed');
        ad.dispose();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAdService] Ad$label failed to show: ${error.message}');
        ad.dispose();
        onAdFailedToShow();
      },
      onAdImpression: (ad) => debugPrint('[RewardedAdService] Ad$label impression'),
    );
    ad.show(onUserEarnedReward: (ad, reward) {
      debugPrint('[RewardedAdService] Ad$label user earned reward: ${reward.amount}');
      onUserEarnedReward(ad, reward);
    });
  }

  void _setAdCallbacks(RewardedAd ad, String label) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('[RewardedAdService] Ad$label shown'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[RewardedAdService] Ad$label dismissed');
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAdService] Ad$label failed to show: ${error.message}');
        ad.dispose();
      },
      onAdImpression: (ad) => debugPrint('[RewardedAdService] Ad$label impression'),
    );
  }

  // Expose ad state for UI/diagnostics
  bool get isAdALoaded => _adA != null && !_isAdExpired(_adALoadedAt);
  bool get isAdBLoaded => _adB != null && !_isAdExpired(_adBLoadedAt);
  bool get isAdCLoaded => _adC != null && !_isAdExpired(_adCLoadedAt);
  bool get isAnyAdAvailable => isAdALoaded || isAdBLoaded || isAdCLoaded;
  DateTime? get adALoadedAt => _adALoadedAt;
  DateTime? get adBLoadedAt => _adBLoadedAt;
  DateTime? get adCLoadedAt => _adCLoadedAt;

  // Remove any forced reloads on demand except for initial load or if all ads are expired
  void reloadAllIfAllExpired() {
    final now = DateTime.now();
    final allExpired = [
      _adA == null || (_adALoadedAt != null && now.difference(_adALoadedAt!).inMinutes > 60),
      _adB == null || (_adBLoadedAt != null && now.difference(_adBLoadedAt!).inMinutes > 60),
      _adC == null || (_adCLoadedAt != null && now.difference(_adCLoadedAt!).inMinutes > 60),
    ].every((e) => e);
    if (allExpired) {
      debugPrint('[RewardedAdService] All ads expired, reloading all.');
      loadAllAds();
    }
  }
} 