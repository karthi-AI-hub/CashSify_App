import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cashsify_app/features/common_screens/contact_us_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/app_config_provider.dart';
import 'package:go_router/go_router.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  final String? message;
  final VoidCallback? onInfo;
  final String? estimatedTime;
  final VoidCallback? onContactSupport;

  const MaintenanceScreen({
    super.key,
    this.message,
    this.onInfo,
    this.estimatedTime,
    this.onContactSupport,
  });

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    if (widget.estimatedTime != null) {
      final now = DateTime.now();
      final end = DateTime.tryParse(widget.estimatedTime!);
      if (end != null && end.isAfter(now)) {
        _remaining = end.difference(now);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            final diff = end.difference(DateTime.now());
            _remaining = diff.isNegative ? Duration.zero : diff;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
  }

  Future<void> _handleRefresh() async {
    // Re-fetch app config using the provider
    await ref.refresh(appConfigProvider.future);
    final appConfig = ref.read(appConfigProvider);
    if (appConfig.hasValue && (appConfig.value?['app_runs'] != false)) {
      if (mounted) Navigator.of(context).maybePop();
    } else {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App is still under maintenance.',
              style: TextStyle(color: colorScheme.surface),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [colorScheme.background, colorScheme.surfaceVariant]
                : [colorScheme.primary.withOpacity(0.08), colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Improved animation with pulse effect
                      _PulseAnimation(
                        child: Lottie.asset(
                          'assets/animations/maintanance.json',
                          width: 220,
                          height: 220,
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                      const SizedBox(height: AppSpacing.xl),
                      // Title with gradient for better visual appeal
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "We're Improving Your Experience",
                          style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: AppSpacing.lg),
                      // Maintenance message in a card for better focus
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? colorScheme.surfaceVariant.withOpacity(0.3)
                              : colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? colorScheme.outline.withOpacity(0.3)
                                : colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.construction,
                              size: 36,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              widget.message ?? "CashSify is currently undergoing scheduled maintenance to bring you new features and improvements.",
                              style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: AppSpacing.xl),
                      // Estimated time if available
                      if (_remaining != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              "Estimated completion (approximate): ${_formatDuration(_remaining)}",
                              style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Progress indicator to show work in progress
                      const SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "We're almost done! Thank you for your patience.",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Improved action button with better visual feedback
                      if (widget.onInfo != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onInfo,
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Learn More'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      // Additional helpful links or actions
                      Text(
                        "Need immediate assistance?",
                        style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () {
                          context.push('/contact-us');
                        },
                        icon: Icon(Icons.support_agent, color: colorScheme.primary),
                        label: Text(
                          "Contact Support",
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for pulse animation
class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}