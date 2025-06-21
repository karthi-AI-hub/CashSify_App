import 'package:shared_preferences/shared_preferences.dart';
import 'package:cashsify_app/core/utils/logger.dart';
import 'dart:convert';

/// Service to handle app state persistence using SharedPreferences
class AppStateService {
  static const String _navigationStateKey = 'navigation_state';
  static const String _userDataKey = 'user_data';
  static const String _appSettingsKey = 'app_settings';
  static const String _lastSavedKey = 'last_saved_timestamp';

  late SharedPreferences _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save current navigation state
  Future<void> saveNavigationState({
    required int currentIndex,
    required String title,
    bool showNotifications = false,
    bool showBonus = false,
  }) async {
    try {
      final state = {
        'currentIndex': currentIndex,
        'title': title,
        'showNotifications': showNotifications,
        'showBonus': showBonus,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_navigationStateKey, jsonEncode(state));
      await _prefs.setString(_lastSavedKey, DateTime.now().toIso8601String());
      
      AppLogger.info('Navigation state saved: $state');
    } catch (e) {
      AppLogger.error('Error saving navigation state: $e');
    }
  }

  /// Load saved navigation state
  Map<String, dynamic>? loadNavigationState() {
    try {
      final stateJson = _prefs.getString(_navigationStateKey);
      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        AppLogger.info('Navigation state loaded: $state');
        return state;
      }
    } catch (e) {
      AppLogger.error('Error loading navigation state: $e');
    }
    return null;
  }

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final data = {
        'userData': userData,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_userDataKey, jsonEncode(data));
      AppLogger.info('User data saved successfully');
    } catch (e) {
      AppLogger.error('Error saving user data: $e');
    }
  }

  /// Load saved user data
  Map<String, dynamic>? loadUserData() {
    try {
      final dataJson = _prefs.getString(_userDataKey);
      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        AppLogger.info('User data loaded successfully');
        return data['userData'] as Map<String, dynamic>?;
      }
    } catch (e) {
      AppLogger.error('Error loading user data: $e');
    }
    return null;
  }

  /// Save app settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final data = {
        'settings': settings,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_appSettingsKey, jsonEncode(data));
      AppLogger.info('App settings saved successfully');
    } catch (e) {
      AppLogger.error('Error saving app settings: $e');
    }
  }

  /// Load saved app settings
  Map<String, dynamic>? loadAppSettings() {
    try {
      final dataJson = _prefs.getString(_appSettingsKey);
      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        AppLogger.info('App settings loaded successfully');
        return data['settings'] as Map<String, dynamic>?;
      }
    } catch (e) {
      AppLogger.error('Error loading app settings: $e');
    }
    return null;
  }

  /// Save complete app state (navigation + user data + settings)
  Future<void> saveCompleteAppState({
    required int currentIndex,
    required String title,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? settings,
    bool showNotifications = false,
    bool showBonus = false,
  }) async {
    try {
      await Future.wait([
        saveNavigationState(
          currentIndex: currentIndex,
          title: title,
          showNotifications: showNotifications,
          showBonus: showBonus,
        ),
        saveUserData(userData),
        if (settings != null) saveAppSettings(settings),
      ]);

      AppLogger.info('Complete app state saved successfully');
    } catch (e) {
      AppLogger.error('Error saving complete app state: $e');
    }
  }

  /// Get last saved timestamp
  DateTime? getLastSavedTimestamp() {
    try {
      final timestamp = _prefs.getString(_lastSavedKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      AppLogger.error('Error getting last saved timestamp: $e');
    }
    return null;
  }

  /// Clear all saved app state
  Future<void> clearAppState() async {
    try {
      await Future.wait([
        _prefs.remove(_navigationStateKey),
        _prefs.remove(_userDataKey),
        _prefs.remove(_appSettingsKey),
        _prefs.remove(_lastSavedKey),
      ]);
      AppLogger.info('App state cleared successfully');
    } catch (e) {
      AppLogger.error('Error clearing app state: $e');
    }
  }

  /// Check if app state exists
  bool hasSavedState() {
    return _prefs.containsKey(_navigationStateKey) || 
           _prefs.containsKey(_userDataKey) || 
           _prefs.containsKey(_appSettingsKey);
  }
} 