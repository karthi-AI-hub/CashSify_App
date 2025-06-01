import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../theme/app_theme.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/widgets/form/custom_text_field.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/utils/captcha_utils.dart';

// State providers for verification
final captchaTextProvider = StateProvider<String>((ref) => generateCaptcha());
final userInputProvider = StateProvider<String>((ref) => '');
final isVerifyingProvider = StateProvider<bool>((ref) => false);
final verificationAttemptsProvider = StateProvider<int>((ref) => 0);

class VerificationScreen extends HookConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final captchaText = ref.watch(captchaTextProvider);
    final userInput = ref.watch(userInputProvider);
    final isVerifying = ref.watch(isVerifyingProvider);
    final attempts = ref.watch(verificationAttemptsProvider);
    final maxAttempts = 3;
    final failed = attempts >= maxAttempts;
    final focusNode = useFocusNode();
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!failed) focusNode.requestFocus();
      });
      return null;
    }, [failed]);

    return LoadingOverlay(
      isLoading: isVerifying,
      child: Material(
        color: Theme.of(context).colorScheme.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 20, right: 20, top: 24, bottom: 24 + bottomInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(context, colorScheme, textTheme),
                        const SizedBox(height: 32),
                        _buildCaptchaCard(context, colorScheme, textTheme, captchaText, failed, ref),
                        const SizedBox(height: 32),
                        _buildInputField(context, colorScheme, textTheme, userInput, ref, focusNode, failed),
                        const SizedBox(height: 18),
                        _buildAttemptsChips(context, colorScheme, textTheme, attempts, maxAttempts, failed),
                        const SizedBox(height: 32),
                        _buildVerifyButton(context, colorScheme, textTheme, isVerifying, ref, failed),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.verified_user_rounded, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          'Human Verification',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter the code below to prove you're not a robot.",
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCaptchaCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, String captchaText, bool failed, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: failed ? colorScheme.errorContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: failed ? colorScheme.error : colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: textTheme.headlineMedium!.copyWith(
                    color: failed ? colorScheme.error : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 10,
                    shadows: [
                      Shadow(
                        color: failed ? colorScheme.error.withOpacity(0.2) : colorScheme.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(captchaText, textAlign: TextAlign.center),
                ),
              ),
              IconButton(
                tooltip: 'Refresh CAPTCHA',
                icon: Icon(Icons.refresh_rounded, color: colorScheme.primary, size: 20),
                onPressed: () {
                  ref.read(captchaTextProvider.notifier).state = generateCaptcha();
                  ref.read(userInputProvider.notifier).state = '';
                  CustomToast.show(
                    context,
                    message: 'CAPTCHA refreshed!',
                    type: ToastType.info,
                    duration: const Duration(seconds: 2),
                    showCloseButton: false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Type the characters above',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, String userInput, WidgetRef ref, FocusNode focusNode, bool failed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: failed
            ? [
                BoxShadow(
                  color: colorScheme.error.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextField(
        focusNode: focusNode,
        onChanged: (value) => ref.read(userInputProvider.notifier).state = value,
        textAlign: TextAlign.center,
        style: textTheme.bodyLarge?.copyWith(
          color: failed ? colorScheme.error : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 1.2,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
          hintText: 'Enter code',
          hintStyle: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: failed ? colorScheme.error : colorScheme.primary,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: failed ? colorScheme.error : colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: failed ? colorScheme.error : colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        cursorColor: colorScheme.primary,
        enabled: !failed,
      ),
    );
  }

  Widget _buildAttemptsChips(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, int attempts, int maxAttempts, bool failed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxAttempts, (i) {
        final isUsed = i < attempts;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isUsed
                  ? (failed ? colorScheme.error : colorScheme.primary)
                  : colorScheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUsed
                    ? (failed ? colorScheme.error : colorScheme.primary)
                    : colorScheme.outline.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: isUsed
                ? Icon(Icons.close, size: 8, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, bool isVerifying, WidgetRef ref, bool failed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.verified, color: colorScheme.onPrimary, size: 16),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            failed ? 'Blocked' : 'Verify',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: failed ? colorScheme.error : colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: failed ? 0 : 4,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 36),
        ),
        onPressed: isVerifying || failed ? null : () => _handleVerification(context, ref),
      ),
    );
  }

  void _handleVerification(BuildContext context, WidgetRef ref) async {
    final captchaText = ref.read(captchaTextProvider);
    final userInput = ref.read(userInputProvider);
    final attempts = ref.read(verificationAttemptsProvider);
    final maxAttempts = 3;

    if (attempts >= maxAttempts) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Too Many Attempts'),
          content: const Text('You have been blocked for now. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, false);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ref.read(isVerifyingProvider.notifier).state = true;

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (userInput.trim().toLowerCase() == captchaText.trim().toLowerCase()) {
        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Verification successful! 🎉',
            type: ToastType.success,
            duration: const Duration(seconds: 2),
            showCloseButton: false,
          );
          Navigator.pop(context, true);
        }
      } else {
        ref.read(verificationAttemptsProvider.notifier).state++;
        ref.read(userInputProvider.notifier).state = '';
        ref.read(captchaTextProvider.notifier).state = generateCaptcha();
        if (context.mounted) {
          CustomToast.show(
            context,
            message: 'Incorrect code. Please try again.',
            type: ToastType.error,
            duration: const Duration(seconds: 2),
            showCloseButton: false,
          );
        }
      }
    } finally {
      ref.read(isVerifyingProvider.notifier).state = false;
    }
  }
} 