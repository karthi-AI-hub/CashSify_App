import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import 'package:cashsify_app/features/common_screens/contact_us_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:cashsify_app/core/utils/logger.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;
  final VoidCallback? onContactSupport;

  const NoInternetScreen({
    super.key,
    this.onRetry,
    this.onSettings,
    this.onContactSupport,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
    if (state == AppLifecycleState.resumed && _mounted) {
      // Check connectivity when app resumes
      _handleRefresh();
    }
  }

  Future<void> openAppSettings() async {
    final uri = Uri.parse('app-settings:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openWifiSettings() async {
    // Android intent
    final androidUri = Uri.parse('intent:#Intent;action=android.settings.WIFI_SETTINGS;end');
    // iOS
    final iosUri = Uri.parse('App-Prefs:WIFI');
    if (await canLaunchUrl(androidUri)) {
      await launchUrl(androidUri);
    } else if (await canLaunchUrl(iosUri)) {
      await launchUrl(iosUri);
    } else {
      await openAppSettings();
    }
  }

  Future<void> openMobileDataSettings() async {
    // Android intent
    final androidUri = Uri.parse('intent:#Intent;action=android.settings.DATA_ROAMING_SETTINGS;end');
    // iOS
    final iosUri = Uri.parse('App-Prefs:MOBILE_DATA_SETTINGS_ID');
    if (await canLaunchUrl(androidUri)) {
      await launchUrl(androidUri);
    } else if (await canLaunchUrl(iosUri)) {
      await launchUrl(iosUri);
    } else {
      await openAppSettings();
    }
  }

  Future<void> _handleRefresh() async {
    if (_isLoading || !_mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      AppLogger.info('Checking connectivity status');
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity != ConnectivityResult.none) {
        AppLogger.info('Connection restored');
        if (_mounted) {
          _showSuccessSnackBar('Connection restored!');
          Navigator.of(context).maybePop();
        }
      } else {
        AppLogger.info('Still no internet connection');
        if (_mounted) {
          _showErrorSnackBar('Still no internet connection');
        }
      }
    } catch (e) {
      AppLogger.error('Error checking connectivity: $e');
      if (_mounted) {
        _showErrorSnackBar('Error checking connection');
      }
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: colorScheme.surface),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.surface),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [colorScheme.background, colorScheme.surfaceVariant]
                : [colorScheme.primary.withOpacity(0.08), colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: widget.onRetry != null ? () async { widget.onRetry!(); } : _handleRefresh,
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation with connection visualization
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/no_internet.json',
                          width: 220,
                          height: 220,
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          bottom: 32,
                          child: Icon(
                            Icons.wifi_off,
                            size: 44,
                            color: colorScheme.error.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.xl),
                    // Title with emphasis
                    Text(
                      'Connection Lost',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: AppSpacing.md),
                    // Detailed message in a container
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceVariant.withOpacity(0.3)
                            : colorScheme.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.outline.withOpacity(0.3)
                              : colorScheme.error.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your device is not connected to the internet.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Please check your:',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi, size: 18, color: colorScheme.error),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Wi-Fi connection', style: textTheme.bodyMedium),
                              const SizedBox(width: AppSpacing.lg),
                              Icon(Icons.sim_card, size: 18, color: colorScheme.error),
                              const SizedBox(width: AppSpacing.xs),
                              Text('Mobile data', style: textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Troubleshooting tips
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips:',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text('• Toggle Airplane mode on/off'),
                                Text('• Restart your router'),
                                Text('• Try connecting to a different network'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: AppSpacing.xl),
                    // Primary action button
                    FilledButton.icon(
                      onPressed: _isLoading ? null : (widget.onRetry ?? _handleRefresh),
                      icon: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isLoading ? 'Checking...' : 'Retry Connection'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(220, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
                    const SizedBox(height: AppSpacing.md),
                    // Secondary action button
                    Tooltip(
                      message: 'Opens network settings with smart fallback',
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : openMobileDataSettings,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSecondary,
                                ),
                              )
                            : Icon(Icons.settings, color: colorScheme.onPrimary),
                        label: Text(_isLoading ? 'Opening...' : 'Open Network Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Smart network settings button
                    Tooltip(
                      message: 'Smart network settings with comprehensive fallback',
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : openMobileDataSettings,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onTertiary,
                                ),
                              )
                            : Icon(Icons.wifi, color: colorScheme.onPrimary),
                        label: Text(_isLoading ? 'Opening...' : 'Smart Network Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Wi-Fi settings button
                    Tooltip(
                      message: 'Wi-Fi settings with fallback',
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : openWifiSettings,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Icon(Icons.wifi_tethering, color: colorScheme.onPrimary),
                        label: Text(_isLoading ? 'Opening...' : 'Wi-Fi Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Mobile data settings button
                    Tooltip(
                      message: 'Mobile data settings with fallback',
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : openMobileDataSettings,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Icon(Icons.sim_card, color: colorScheme.onSurfaceVariant),
                        label: Text(_isLoading ? 'Opening...' : 'Mobile Data Settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.surfaceVariant,
                          foregroundColor: colorScheme.onSurfaceVariant,
                          minimumSize: const Size(220, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Additional help option
                    TextButton.icon(
                      onPressed: _isLoading ? null : (widget.onContactSupport ?? () {
                        context.push('/contact-us');
                      }),
                      icon: Icon(Icons.support_agent, color: colorScheme.primary),
                      label: Text(
                        'Contact Support',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Still having trouble?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}