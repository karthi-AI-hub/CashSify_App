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
  static const bool useTestAds = kDebugMode; // Use test ads in debug mode for investigation
  
  // Investigation flags
  static bool _debugMode = true; // Enable detailed logging for investigation

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

  // Investigation: Track production ad failures
  static Map<String, List<String>> _productionAdErrors = {
    'A': [],
    'B': [],
    'C': [],
  };
  static int _totalProductionAttempts = 0;
  static int _totalTestAttempts = 0;

  // Diagnostics: Print loaded ad unit and timestamp
  void _logAdLoaded(String adUnitId) {
    debugPrint('[RewardedAdService] Ad loaded: $adUnitId at ${DateTime.now()}');
  }

  // Diagnostics: Print ad error details + Investigation logging
  void _logAdError(String adLabel, LoadAdError error) {
    // Track error for investigation
    final errorDetails = 'Code: ${error.code}, Message: ${error.message}, Domain: ${error.domain}';
    if (!useTestAds) {
      _productionAdErrors[adLabel]?.add(errorDetails);
    }
    
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
    
    // Investigation: Detailed error analysis
    if (_debugMode) {
      debugPrint('[RewardedAdService] === DETAILED ERROR ANALYSIS ===');
      debugPrint('[RewardedAdService] Ad Type: ${useTestAds ? 'TEST' : 'PRODUCTION'}');
      debugPrint('[RewardedAdService] Error Domain: ${error.domain}');
      debugPrint('[RewardedAdService] Response Info: ${error.responseInfo}');
      debugPrint('[RewardedAdService] Full Error: $errorDetails');
      
      if (!useTestAds) {
        debugPrint('[RewardedAdService] Production Error Count for Ad$adLabel: ${_productionAdErrors[adLabel]?.length}');
        debugPrint('[RewardedAdService] Total Production Attempts: $_totalProductionAttempts');
      }
    }
    
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
    
    // Investigation: Track attempts
    if (useTestAds) {
      _totalTestAttempts++;
    } else {
      _totalProductionAttempts++;
    }
    
    debugPrint('[RewardedAdService] Loading AdA... (${useTestAds ? "TEST" : "PROD"})');
    debugPrint('[RewardedAdService] Ad Unit ID: $adUnitId');
    
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
          _scheduleExpiry('A');
        },
        onAdFailedToLoad: (error) {
          _adA = null;
          _isLoadingA = false;
          _logAdError('A', error);
          _scheduleRetry(_loadAdA, 'A');
        },
      ),
    );
  }

  void _loadAdB() {
    if (_adB != null || _isLoadingB) return;
    _isLoadingB = true;
    final adUnitId = useTestAds ? testAdUnitId : adUnitIdB;
    
    // Investigation: Track attempts
    if (useTestAds) {
      _totalTestAttempts++;
    } else {
      _totalProductionAttempts++;
    }
    
    debugPrint('[RewardedAdService] Loading AdB... (${useTestAds ? "TEST" : "PROD"})');
    debugPrint('[RewardedAdService] Ad Unit ID: $adUnitId');
    
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
          _scheduleExpiry('B');
        },
        onAdFailedToLoad: (error) {
          _adB = null;
          _isLoadingB = false;
          _logAdError('B', error);
          _scheduleRetry(_loadAdB, 'B');
        },
      ),
    );
  }

  void _loadAdC() {
    if (_adC != null || _isLoadingC) return;
    _isLoadingC = true;
    final adUnitId = useTestAds ? testAdUnitId : adUnitIdC;
    
    // Investigation: Track attempts
    if (useTestAds) {
      _totalTestAttempts++;
    } else {
      _totalProductionAttempts++;
    }
    
    debugPrint('[RewardedAdService] Loading AdC... (${useTestAds ? "TEST" : "PROD"})');
    debugPrint('[RewardedAdService] Ad Unit ID: $adUnitId');
    
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
          _scheduleExpiry('C');
        },
        onAdFailedToLoad: (error) {
          _adC = null;
          _isLoadingC = false;
          _logAdError('C', error);
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

  // === INVESTIGATION METHODS ===
  
  // Print detailed production ad failure analysis
  void printProductionAdInvestigation() {
    debugPrint('[RewardedAdService] === PRODUCTION AD INVESTIGATION ===');
    debugPrint('[RewardedAdService] Account Status: Approved (from AdMob console)');
    debugPrint('[RewardedAdService] App ID: ca-app-pub-7086602185948470~4899725073');
    debugPrint('[RewardedAdService] Total Production Attempts: $_totalProductionAttempts');
    debugPrint('[RewardedAdService] Total Test Attempts: $_totalTestAttempts');
    
    debugPrint('[RewardedAdService] === AD UNIT ANALYSIS ===');
    debugPrint('[RewardedAdService] AdA ID: $adUnitIdA');
    debugPrint('[RewardedAdService] AdB ID: $adUnitIdB');
    debugPrint('[RewardedAdService] AdC ID: $adUnitIdC');
    debugPrint('[RewardedAdService] Test ID: $testAdUnitId');
    
    debugPrint('[RewardedAdService] === ERROR ANALYSIS ===');
    for (final entry in _productionAdErrors.entries) {
      debugPrint('[RewardedAdService] Ad${entry.key} Errors (${entry.value.length}):');
      for (int i = 0; i < entry.value.length && i < 5; i++) {
        debugPrint('[RewardedAdService]   ${i + 1}. ${entry.value[i]}');
      }
      if (entry.value.length > 5) {
        debugPrint('[RewardedAdService]   ... and ${entry.value.length - 5} more errors');
      }
    }
    
    debugPrint('[RewardedAdService] === POSSIBLE CAUSES ===');
    debugPrint('[RewardedAdService] 1. Ad units created recently (need 24-48 hours)');
    debugPrint('[RewardedAdService] 2. App not published to Google Play Store');
    debugPrint('[RewardedAdService] 3. Limited ad inventory in your region');
    debugPrint('[RewardedAdService] 4. App bundle ID mismatch');
    debugPrint('[RewardedAdService] 5. AdMob app verification pending');
    debugPrint('[RewardedAdService] 6. Payment/billing issues');
  }
  
  // Test both production and test ads for comparison
  void testBothAdTypes() {
    debugPrint('[RewardedAdService] === TESTING BOTH AD TYPES ===');
    
    // First test with current setting
    debugPrint('[RewardedAdService] Testing current setting (${useTestAds ? 'TEST' : 'PRODUCTION'})...');
    loadAllAds();
    
    // Schedule opposite test
    Timer(const Duration(seconds: 10), () {
      debugPrint('[RewardedAdService] Switching to ${useTestAds ? 'PRODUCTION' : 'TEST'} ads for comparison...');
      _clearAllAds();
      // Note: You'll need to manually change useTestAds value and call this again
      debugPrint('[RewardedAdService] Manually change useTestAds value and call loadAllAds() again');
    });
  }
  
  // Force test production ads (temporarily override setting)
  void forceTestProductionAds() {
    debugPrint('[RewardedAdService] === FORCING PRODUCTION AD TEST ===');
    _clearAllAds();
    
    // Temporarily test production ads
    debugPrint('[RewardedAdService] Testing production AdA...');
    RewardedAd.load(
      adUnitId: adUnitIdA,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[RewardedAdService] ✅ Production AdA loaded successfully!');
          ad.dispose();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAdService] ❌ Production AdA failed: ${error.code} - ${error.message}');
          debugPrint('[RewardedAdService] Domain: ${error.domain}');
          debugPrint('[RewardedAdService] Response Info: ${error.responseInfo}');
        },
      ),
    );
  }
  
  void _clearAllAds() {
    _adA?.dispose();
    _adB?.dispose();
    _adC?.dispose();
    _adA = null;
    _adB = null;
    _adC = null;
    _isLoadingA = false;
    _isLoadingB = false;
    _isLoadingC = false;
  }

  /// Print focused production ad analysis (key info only)
  void printFocusedProductionAnalysis() {
    print('\n' + '='*60);
    print('🔍 FOCUSED PRODUCTION AD ANALYSIS');
    print('='*60);
    
    print('📊 CURRENT CONFIGURATION:');
    print('  • Test Mode: ${useTestAds ? 'ENABLED' : 'DISABLED'}');
    print('  • Production Ad Units: 3 (A, B, C)');
    print('  • Test Ad Unit: $testAdUnitId');
    print('  • Production A: $adUnitIdA');
    print('  • Production B: $adUnitIdB');  
    print('  • Production C: $adUnitIdC');
    
    print('\n📈 CURRENT AD STATUS:');
    print('  • Ad A: ${_adA != null ? 'LOADED' : (_isLoadingA ? 'LOADING' : 'NOT LOADED')}');
    print('  • Ad B: ${_adB != null ? 'LOADED' : (_isLoadingB ? 'LOADING' : 'NOT LOADED')}');
    print('  • Ad C: ${_adC != null ? 'LOADED' : (_isLoadingC ? 'LOADING' : 'NOT LOADED')}');
    
    print('\n🎯 NEXT STEPS:');
    if (useTestAds) {
      print('  1. Switch useTestAds to false in the code');
      print('  2. Hot restart the app');
      print('  3. Try loading ads and watch for errors');
      print('  4. Look for "Account not approved" messages');
    } else {
      print('  1. Production mode is ACTIVE');
      print('  2. Try loading ads normally');
      print('  3. Check logs for specific error patterns');
      print('  4. Monitor for "Account not approved" vs other errors');
    }
    
    print('\n🔍 ERROR PATTERNS TO WATCH FOR:');
    print('  • "Account not approved yet" → Account/App setup issue');
    print('  • "Ad unit ID is invalid" → Wrong ad unit configuration');
    print('  • "No fill" → Geographic or targeting restrictions');
    print('  • "Request error" → Network or technical issues');
    
    print('='*60 + '\n');
  }

  /// Test production ads directly (regardless of useTestAds setting)
  void testProductionAdsDirectly() {
    print('\n' + '='*60);
    print('🧪 TESTING PRODUCTION ADS DIRECTLY');
    print('='*60);
    
    print('📝 Testing production ad unit A: $adUnitIdA');
    
    RewardedAd.load(
      adUnitId: adUnitIdA,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ SUCCESS: Production Ad A loaded successfully!');
          print('   This means your AdMob account and ad units are working.');
          ad.dispose();
        },
        onAdFailedToLoad: (error) {
          print('❌ FAILED: Production Ad A failed to load');
          print('   Error Code: ${error.code}');
          print('   Error Message: ${error.message}');
          print('   Domain: ${error.domain}');
          if (error.responseInfo != null) {
            print('   Response Info: ${error.responseInfo}');
          }
          
          // Analyze the specific error
          if (error.message.toLowerCase().contains('not approved')) {
            print('\n💡 ANALYSIS: Account approval issue detected');
            print('   - Your AdMob account may need additional verification');
            print('   - New ad units can take 24-48 hours to activate');
            print('   - Some regions require app store publication');
          } else if (error.message.toLowerCase().contains('invalid')) {
            print('\n💡 ANALYSIS: Invalid ad unit ID');
            print('   - Check if ad unit ID is correct in AdMob console');
            print('   - Verify the ad unit is created and active');
          } else if (error.message.toLowerCase().contains('no fill')) {
            print('\n💡 ANALYSIS: No ad inventory available');
            print('   - Geographic restrictions may apply');
            print('   - Try testing from different locations');
          }
        },
      ),
    );
    
    print('⏳ Loading production ad... Check logs above for results.');
    print('='*60 + '\n');
  }
} 