import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/services/app_state_service.dart';

// App State Service Provider
final appStateServiceProvider = Provider<AppStateService>((ref) {
  return AppStateService();
});

// App State Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final service = ref.watch(appStateServiceProvider);
  return AppStateNotifier(service);
});

class AppState {
  final bool isInitialized;
  final DateTime? lastSaved;
  final bool hasSavedState;

  const AppState({
    this.isInitialized = false,
    this.lastSaved,
    this.hasSavedState = false,
  });

  AppState copyWith({
    bool? isInitialized,
    DateTime? lastSaved,
    bool? hasSavedState,
  }) {
    return AppState(
      isInitialized: isInitialized ?? this.isInitialized,
      lastSaved: lastSaved ?? this.lastSaved,
      hasSavedState: hasSavedState ?? this.hasSavedState,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  final AppStateService _service;

  AppStateNotifier(this._service) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initialize();
    final lastSaved = _service.getLastSavedTimestamp();
    final hasSavedState = _service.hasSavedState();
    
    state = state.copyWith(
      isInitialized: true,
      lastSaved: lastSaved,
      hasSavedState: hasSavedState,
    );
  }

  Future<void> saveAppState({
    required int currentIndex,
    required String title,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? settings,
    bool showNotifications = false,
    bool showBonus = false,
  }) async {
    await _service.saveCompleteAppState(
      currentIndex: currentIndex,
      title: title,
      userData: userData,
      settings: settings,
      showNotifications: showNotifications,
      showBonus: showBonus,
    );

    state = state.copyWith(
      lastSaved: DateTime.now(),
      hasSavedState: true,
    );
  }

  Future<void> clearAppState() async {
    await _service.clearAppState();
    state = state.copyWith(
      lastSaved: null,
      hasSavedState: false,
    );
  }

  Map<String, dynamic>? loadNavigationState() {
    return _service.loadNavigationState();
  }

  Map<String, dynamic>? loadUserData() {
    return _service.loadUserData();
  }

  Map<String, dynamic>? loadAppSettings() {
    return _service.loadAppSettings();
  }
} 