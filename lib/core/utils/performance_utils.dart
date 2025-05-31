import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PerformanceUtils {
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