import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cashsify_app/core/widgets/custom_button.dart';
import 'package:cashsify_app/core/widgets/loading_overlay.dart';
import 'package:cashsify_app/core/services/supabase_service.dart';
import 'package:cashsify_app/core/utils/app_utils.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';
import 'package:cashsify_app/core/providers/performance_provider.dart';
import 'package:cashsify_app/core/mixins/performance_mixin.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(false);
    final user = useState<Map<String, dynamic>?>(null);

    // Load user data on mount
    useEffect(() {
      loadUserData();
      return null;
    }, []);

    Future<void> loadUserData() async {
      try {
        final userData = await PerformanceUtils.computeInBackground(
          task: () => SupabaseService().getCurrentUser(),
          taskName: 'Load User Data',
        );
        user.value = userData;
      } catch (e) {
        AppUtils.logError('Failed to load user data', e);
      }
    }

    Future<void> handleLogout() async {
      if (isProcessing.value) return;
      isProcessing.value = true;

      try {
        ref.read(loadingProvider.notifier).startLoading('Logging out...');
        
        await PerformanceUtils.computeInBackground(
          task: () => AppUtils.handleAsyncOperation(
            context: context,
            operation: () => SupabaseService().signOut(),
            successMessage: 'Logged out successfully',
            errorMessage: 'Failed to logout. Please try again.',
            showLoading: false,
          ),
          taskName: 'Logout Operation',
        );

        if (context.mounted) {
          context.go('/auth/login');
        }
      } catch (e) {
        AppUtils.logError('Logout failed', e);
      } finally {
        isProcessing.value = false;
        ref.read(loadingProvider.notifier).stopLoading();
      }
    }

    return PerformanceUtils.withPerformanceOverlay(
      Scaffold(
        appBar: AppBar(
          title: Text(
            'Home',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => PerformanceUtils.throttle(handleLogout),
            ),
          ],
        ),
        body: LoadingOverlay(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to CashSify',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your trusted platform for earning rewards',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (user.value != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Email: ${user.value!['email']}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Referral Code: ${user.value!['referral_code'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Logout',
                    onPressed: () => PerformanceUtils.throttle(handleLogout),
                    isLoading: isProcessing.value,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 