import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(LoadingState.initial);

  void startLoading() {
    state = LoadingState.loading;
  }

  void finishLoading() {
    state = LoadingState.loaded;
  }

  void setError() {
    state = LoadingState.error;
  }

  void reset() {
    state = LoadingState.initial;
  }
}

final loadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
}); 