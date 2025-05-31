import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final performanceProvider = StateNotifierProvider<PerformanceNotifier, Map<String, int>>((ref) {
  return PerformanceNotifier();
});

class PerformanceNotifier extends StateNotifier<Map<String, int>> {
  PerformanceNotifier() : super({});

  void recordOperation(String name, int milliseconds) {
    state = {
      ...state,
      name: milliseconds,
    };
  }

  void clearMetrics() {
    state = {};
  }

  Map<String, int> getMetrics() {
    return Map.from(state);
  }
}

class PerformanceMonitor extends StatelessWidget {
  final Widget child;

  const PerformanceMonitor({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Consumer(
        builder: (context, ref, _) {
          final metrics = ref.watch(performanceProvider);
          
          return Stack(
            alignment: Alignment.topRight,
            children: [
              child,
              if (metrics.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: metrics.entries.map((entry) {
                      return Text(
                        '${entry.key}: ${entry.value}ms',
                        style: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
} 