import 'package:flutter/material.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';

mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  final Map<String, Stopwatch> _timers = {};

  @override
  void initState() {
    super.initState();
    _startTimer('initState');
  }

  @override
  void dispose() {
    _stopTimer('initState');
    super.dispose();
  }

  void _startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  void _stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      debugPrint('Performance [$name]: ${timer.elapsedMilliseconds}ms');
      _timers.remove(name);
    }
  }

  Future<T> measureOperation<T>({
    required String name,
    required Future<T> Function() operation,
  }) async {
    _startTimer(name);
    try {
      return await operation();
    } finally {
      _stopTimer(name);
    }
  }

  void measureBuild(String name, VoidCallback build) {
    _startTimer(name);
    build();
    _stopTimer(name);
  }

  Widget wrapWithPerformanceOverlay(Widget child) {
    return PerformanceUtils.withPerformanceOverlay(child);
  }
} 