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
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final isProcessing = useState(false);
    final referralCode = useState<String?>(null);

    final pages = [
      OnboardingPage(
        title: 'Watch & Earn Coins',
        description: 'Watch ads and complete tasks to earn virtual coins',
        animation: 'earnmoney.json',
      ),
      OnboardingPage(
        title: 'Invite Friends',
        description: 'Share with friends and earn bonus coins together',
        animation: 'referral.json',
      ),
      OnboardingPage(
        title: 'Redeem Rewards',
        description: 'Use your coins redeem rewards',
        animation: 'withdraw.json',
      ),
    ];

    // Preload animations
    useEffect(() {
      // Lottie animations are loaded automatically by the Lottie widget
      return null;
    }, []);

    useEffect(() {
      SharedPreferences.getInstance().then((prefs) {
        referralCode.value = prefs.getString('pending_referral_code');
      });
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
              // Set onboarding_complete flag
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', true);
              if (context.mounted) {
                context.go('/auth/login');
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
              if (referralCode.value != null && referralCode.value!.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.green.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Referral code detected: ${referralCode.value}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                      isFullWidth: true,
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