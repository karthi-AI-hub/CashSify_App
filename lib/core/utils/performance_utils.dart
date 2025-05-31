import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PerformanceUtils {
  static Widget withPerformanceOverlay(Widget child) {
    return Builder(
      builder: (context) => Stack(
        children: [
          child,
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                'Performance Overlay',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    return Stack(
      children: [
        child,
        if (kDebugMode)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                'Performance Overlay',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 