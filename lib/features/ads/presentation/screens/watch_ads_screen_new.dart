// Dummy Watch Ads Screen (no ads / no database)
import 'package:flutter/material.dart';
import 'package:cashsify_app/core/config/app_config.dart';

class WatchAdsScreen extends StatefulWidget {
  const WatchAdsScreen({super.key});
  @override
  State<WatchAdsScreen> createState() => _WatchAdsScreenState();
}

class _WatchAdsScreenState extends State<WatchAdsScreen> {
  static const int target = 20; // dummy target
  int watched = 0;
  bool simulateLoading = false;

  void _simulateWatch() async {
    if (simulateLoading || watched >= target) return;
    setState(() => simulateLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      watched++;
      simulateLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = watched / target;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Ads (Demo)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              child: Column(
                children: [
                  Text(
                    watched >= target
                        ? 'Daily Goal Reached!'
                        : 'Simulated Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('$watched / $target (Demo counter)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Demo Actions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: watched >= target || simulateLoading ? null : _simulateWatch,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(watched >= target ? 'Completed' : simulateLoading ? 'Simulating...' : 'Simulate Watching Ad'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: watched == 0 && !simulateLoading
                        ? null
                        : () => setState(() => watched = 0),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About This Dummy Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text(
                      'The Ads watched in the Demo screen will not be considered as ${AppConfig.appName} coins. This is only for demonstration purposes.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}