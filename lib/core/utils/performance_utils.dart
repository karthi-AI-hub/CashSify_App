import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class PerformanceUtils {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<double>> _frameRates = {};
  static bool _isMonitoring = false;

  /// Start monitoring performance metrics
  static void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _monitorFrameRate();
  }

  /// Stop monitoring performance metrics
  static void stopMonitoring() {
    _isMonitoring = false;
  }

  /// Start a timer for a specific operation
  static void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  /// Stop a timer and log the duration
  static void stopTimer(String operationName) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      AppLogger.info(
        'Performance: $operationName took ${timer.elapsedMilliseconds}ms',
      );
      _timers.remove(operationName);
    }
  }

  /// Monitor frame rate
  static void _monitorFrameRate() {
    if (!_isMonitoring) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final frameRate = 1000 / (now - _lastFrameTime);
      _lastFrameTime = now;

      _frameRates.putIfAbsent('current', () => []).add(frameRate);
      if (_frameRates['current']!.length > 60) {
        _frameRates['current']!.removeAt(0);
      }

      if (_isMonitoring) {
        _monitorFrameRate();
      }
    });
  }

  static int _lastFrameTime = 0;

  /// Get current average frame rate
  static double getAverageFrameRate() {
    final rates = _frameRates['current'];
    if (rates == null || rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  /// Measure widget build time
  static T measureBuildTime<T>(String widgetName, T Function() build) {
    startTimer('build_$widgetName');
    final result = build();
    stopTimer('build_$widgetName');
    return result;
  }

  /// Log memory usage (platform specific)
  static void logMemoryUsage() {
    // This is a placeholder. Actual implementation would require platform-specific code
    AppLogger.info('Memory usage logging not implemented for this platform');
  }

  /// Clear all performance data
  static void clearData() {
    _timers.clear();
    _frameRates.clear();
  }

  static Widget withPerformanceOverlay(Widget child) {
    return child;
  }

  static Future<T> computeInBackground<T>({
    required Future<T> Function() task,
    required String taskName,
  }) async {
    if (kDebugMode) {
      print('Starting background task: $taskName');
    }
    
    final result = await task();
    
    if (kDebugMode) {
      print('Completed background task: $taskName');
    }
    
    return result;
  }

  static void throttle(Function callback) {
    callback();
  }

  static void debounce(
    Function callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    Timer? timer;
    if (timer?.isActive ?? false) timer?.cancel();
    timer = Timer(duration, () => callback());
  }

  static void debounceWithCallback(
    Function callback, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    Timer? timer;
    if (timer?.isActive ?? false) timer?.cancel();
    timer = Timer(duration, () {
      callback();
    });
  }
}

class PerformanceOverlay extends StatelessWidget {
  final Widget child;

  const PerformanceOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
} 