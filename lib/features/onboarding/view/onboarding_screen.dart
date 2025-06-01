import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../theme/app_theme.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/core/utils/performance_utils.dart';
import 'package:cashsify_app/core/utils/image_utils.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final isProcessing = useState(false);

    final pages = [
      OnboardingPage(
        title: 'Earn Real Money',
        description: 'Watch ads and earn coins that you can withdraw via UPI',
        animation: 'earnmoney.json',
      ),
      OnboardingPage(
        title: 'Refer & Earn More',
        description: 'Invite friends and earn bonus coins for every referral',
        animation: 'referral.json',
      ),
      OnboardingPage(
        title: 'Easy Withdrawals',
        description: 'Withdraw your earnings directly to your UPI account',
        animation: 'withdraw.json',
      ),
    ];

    // Preload animations
    useEffect(() {
      // Lottie animations are loaded automatically by the Lottie widget
      return null;
    }, []);

    Future<void> handleNavigation() async {
      if (isProcessing.value) return;
      isProcessing.value = true;

      try {
        if (currentPage.value == pages.length - 1) {
          await PerformanceUtils.computeInBackground(
            task: () async {
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.mounted) {
                context.go('/auth');
              }
            },
            taskName: 'Navigation to Auth',
          );
        } else {
          await pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } finally {
        isProcessing.value = false;
      }
    }

    return PerformanceUtils.withPerformanceOverlay(
      Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => currentPage.value = index,
                  itemBuilder: (context, index) => pages[index],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: currentPage.value == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentPage.value == index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: currentPage.value == pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: () => PerformanceUtils.throttle(handleNavigation),
                      isLoading: isProcessing.value,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 