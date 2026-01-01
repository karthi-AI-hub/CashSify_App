import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // Production ad unit IDs
  static const String adUnitIdA = 'ca-app-pub-7086602185948470/1291652554';
  static const String adUnitIdB = 'ca-app-pub-7086602185948470/8767182851';
  static const String adUnitIdC = 'ca-app-pub-7086602185948470/6802235192';
  
  // Test ad unit IDs (use during development)
  static const String testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // Set this to true during development if your AdMob account is not approved
  static const bool useTestAds = false;

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
  
  // Preload more ads for better availability
  Timer? _aggressiveReloadTimer;

  // Diagnostics: Print loaded ad unit and timestamp
  void _logAdLoaded(String adUnitId) {
    debugPrint('[RewardedAdService] Ad loaded: $adUnitId at ${DateTime.now()}');
  }

  // Log mediation network information
  void _logMediationInfo(RewardedAd ad, String label) {
    try {
      final responseInfo = ad.responseInfo;
      if (responseInfo != null) {
        debugPrint('[RewardedAdService] Ad$label - Mediation Network: ${responseInfo.mediationAdapterClassName ?? 'Unknown'}');
        debugPrint('[RewardedAdService] Ad$label - Response ID: ${responseInfo.responseId ?? 'Unknown'}');
        
        // Check if Unity Ads is being used
        if (responseInfo.mediationAdapterClassName?.contains('unity') == true ||
            responseInfo.mediationAdapterClassName?.contains('Unity') == true) {
          debugPrint('[RewardedAdService] 🎯 UNITY ADS DETECTED! Ad$label served by Unity');
        } else {
          debugPrint('[RewardedAdService] 📱 Google AdMob served Ad$label');
        }
      }
    } catch (e) {
      debugPrint('[RewardedAdService] Error getting mediation info: $e');
    }
  }

  // Log detailed error information for mediation debugging
  void _logDetailedAdError(String label, LoadAdError error) {
    debugPrint('[RewardedAdService] ❌ Ad$label Load Error Details:');
    debugPrint('  - Code: ${error.code}');
    debugPrint('  - Domain: ${error.domain}');
    debugPrint('  - Message: ${error.message}');
    
    if (error.responseInfo != null) {
      final responseInfo = error.responseInfo!;
      debugPrint('  - Response ID: ${responseInfo.responseId ?? 'Unknown'}');
      debugPrint('  - Mediation Adapter: ${responseInfo.mediationAdapterClassName ?? 'Unknown'}');
      
      // Check for Unity-specific errors
      if (responseInfo.mediationAdapterClassName?.contains('unity') == true ||
          responseInfo.mediationAdapterClassName?.contains('Unity') == true) {
        debugPrint('  - 🎯 UNITY ADS ERROR: Unity mediation adapter failed');
        debugPrint('  - Possible causes: Unity Dashboard not configured, Game ID invalid, or placement issues');
      }
      
      // Log adapter responses for debugging
      final adapterResponses = responseInfo.adapterResponses;
      if (adapterResponses != null && adapterResponses.isNotEmpty) {
        debugPrint('  - Adapter Responses:');
        for (final adapterResponse in adapterResponses) {
          debugPrint('    * ${adapterResponse.adapterClassName}: ${adapterResponse.latencyMillis}ms');
          if (adapterResponse.adError != null) {
            debugPrint('      Error: ${adapterResponse.adError!.message}');
          }
        }
      }
    }
  }

  // Diagnostics: Print ad error details
  void _logAdError(String adLabel, LoadAdError error) {
    String errorMessage = 'Ad$adLabel failed to load: ';
    
    switch (error.code) {
      case 0:
        errorMessage += 'Internal error (${error.code})';
        break;
      case 1:
        errorMessage += 'Invalid request (${error.code})';
        break;
      case 2:
        errorMessage += 'Network error (${error.code})';
        break;
      case 3:
        errorMessage += 'No fill - no ads available (${error.code})';
        if (error.message.toLowerCase().contains('not approved')) {
          errorMessage += ' - AdMob account not approved yet';
        }
        break;
      case 8:
        errorMessage += 'Invalid ad unit ID (${error.code})';
        break;
      case 9:
        errorMessage += 'Invalid ad size (${error.code})';
        break;
      default:
        errorMessage += 'Unknown error (${error.code})';
    }
    
    errorMessage += ' - ${error.message}';
    debugPrint('[RewardedAdService] $errorMessage');
    
    // Additional context for account approval issues
    if (error.code == 3 && error.message.toLowerCase().contains('not approved')) {
      debugPrint('[RewardedAdService] AdMob account needs approval. Visit: https://support.google.com/admob/answer/9905175');
      debugPrint('[RewardedAdService] Consider using test ads during development.');
    }
  }

  void _loadAdA() {
    if (_adA != null || _isLoadingA) return;
    _isLoadingA = true;
    final adUnitId = useTestAds ? testAdUnitId : adUnitIdA;
    
    debugPrint('[RewardedAdService] Loading AdA... (${useTestAds ? "TEST" : "PROD"})');
    
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adA = ad;
          _isLoadingA = false;
          _adALoadedAt = DateTime.now();
          _adAExponentialBackoff = 1;
          _logAdLoaded(adUnitId);
          _logMediationInfo(ad, 'A');
          _scheduleExpiry('A');
        },
        onAdFailedToLoad: (error) {
          _adA = null;
          _isLoadingA = false;
          _logAdError('A', error);
          _logDetailedAdError('A', error);
          _scheduleRetry(_loadAdA, 'A');
        },
      ),
    );
  }

  void _loadAdB() {
    if (_adB != null || _isLoadingB) return;
    _isLoadingB = true;
    final adUnitId = useTestAds ? testAdUnitId : adUnitIdB;
    
    debugPrint('[RewardedAdService] Loading AdB... (${useTestAds ? "TEST" : "PROD"})');
    
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adB = ad;
          _isLoadingB = false;
          _adBLoadedAt = DateTime.now();
          _adBExponentialBackoff = 1;
          _logAdLoaded(adUnitId);
          _logMediationInfo(ad, 'B');
          _scheduleExpiry('B');
        },
        onAdFailedToLoad: (error) {
          _adB = null;
          _isLoadingB = false;
          _logAdError('B', error);
          _logDetailedAdError('B', error);
          _scheduleRetry(_loadAdB, 'B');
        },
      ),
    );
  }

  void _loadAdC() {
    if (_adC != null || _isLoadingC) return;
    _isLoadingC = true;
    final adUnitId = useTestAds ? testAdUnitId : adUnitIdC;
    
    debugPrint('[RewardedAdService] Loading AdC... (${useTestAds ? "TEST" : "PROD"})');
    
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _adC = ad;
          _isLoadingC = false;
          _adCLoadedAt = DateTime.now();
          _adCExponentialBackoff = 1;
          _logAdLoaded(adUnitId);
          _logMediationInfo(ad, 'C');
          _scheduleExpiry('C');
        },
        onAdFailedToLoad: (error) {
          _adC = null;
          _isLoadingC = false;
          _logAdError('C', error);
          _logDetailedAdError('C', error);
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

  // Get current ad service status for debugging
  Map<String, dynamic> getAdServiceStatus() {
    return {
      'useTestAds': useTestAds,
      'hasInitialized': _hasInitialized,
      'adA': {
        'loaded': _adA != null,
        'loading': _isLoadingA,
        'loadedAt': _adALoadedAt?.toIso8601String(),
        'expired': _isAdExpired(_adALoadedAt),
        'backoff': _adAExponentialBackoff,
      },
      'adB': {
        'loaded': _adB != null,
        'loading': _isLoadingB,
        'loadedAt': _adBLoadedAt?.toIso8601String(),
        'expired': _isAdExpired(_adBLoadedAt),
        'backoff': _adBExponentialBackoff,
      },
      'adC': {
        'loaded': _adC != null,
        'loading': _isLoadingC,
        'loadedAt': _adCLoadedAt?.toIso8601String(),
        'expired': _isAdExpired(_adCLoadedAt),
        'backoff': _adCExponentialBackoff,
      },
      'anyAvailable': isAnyAdAvailable,
    };
  }

  // Print debug information
  void printDebugInfo() {
    final status = getAdServiceStatus();
    debugPrint('[RewardedAdService] === DEBUG INFO ===');
    debugPrint('[RewardedAdService] Using ${status['useTestAds'] ? 'TEST' : 'PRODUCTION'} ads');
    debugPrint('[RewardedAdService] Initialized: ${status['hasInitialized']}');
    debugPrint('[RewardedAdService] Any ad available: ${status['anyAvailable']}');
    
    for (final adKey in ['adA', 'adB', 'adC']) {
      final adInfo = status[adKey] as Map<String, dynamic>;
      debugPrint('[RewardedAdService] $adKey: loaded=${adInfo['loaded']}, loading=${adInfo['loading']}, expired=${adInfo['expired']}');
    }
    
    if (!useTestAds && !isAnyAdAvailable) {
      debugPrint('[RewardedAdService] TIP: If your AdMob account is not approved, set useTestAds=true for development');
    }
  }
} 