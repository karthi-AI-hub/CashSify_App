import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../../../../theme/app_theme.dart';
import 'package:cashsify_app/core/widgets/layout/loading_overlay.dart';
import 'package:cashsify_app/core/widgets/form/custom_text_field.dart';
import 'package:cashsify_app/core/widgets/form/custom_button.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_toast.dart';
import 'package:cashsify_app/core/utils/captcha_utils.dart';
import 'package:cashsify_app/core/widgets/feedback/success_animation.dart';
import 'package:cashsify_app/core/widgets/feedback/custom_tooltip.dart';
import 'package:cashsify_app/features/ads/presentation/providers/earnings_provider.dart';

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
    final isSuccess = useState(false);
    final controller = useTextEditingController(text: userInput);
    useEffect(() {
      if (controller.text != userInput) {
        controller.text = userInput;
        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
      }
      return null;
    }, [userInput]);
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!failed) focusNode.requestFocus();
      });
      return null;
    }, [failed]);

    return WillPopScope(
      onWillPop: () async => false,
      child: LoadingOverlay(
        isLoading: isVerifying,
        child: Material(
          color: Theme.of(context).colorScheme.background,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.background,
              image: DecorationImage(
                image: _createPatternImage(
                  color: colorScheme.primary.withOpacity(0.03),
                  size: 20,
                ),
                repeat: ImageRepeat.repeat,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                  final isSmallScreen = constraints.maxWidth < 360;
                  return SizedBox.expand(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: isSmallScreen ? 16 : 20,
                        right: isSmallScreen ? 16 : 20,
                        top: isSmallScreen ? 16 : 24,
                        bottom: 24 + bottomInset,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header: Avatar above title, centered
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primary.withOpacity(0.12),
                                child: Icon(Icons.verified_user_rounded, color: colorScheme.primary, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Human Verification',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
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
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _buildCaptchaCard(
                            context,
                            colorScheme,
                            textTheme,
                            captchaText,
                            failed,
                            ref,
                            focusNode,
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _buildInputField(
                            context,
                            colorScheme,
                            textTheme,
                            userInput,
                            ref,
                            focusNode,
                            failed,
                            controller,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 18),
                          _buildAttemptsChips(
                            context,
                            colorScheme,
                            textTheme,
                            attempts,
                            maxAttempts,
                            failed,
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          _buildVerifyButton(
                            context,
                            colorScheme,
                            textTheme,
                            isVerifying,
                            ref,
                            failed,
                            isSuccess,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptchaCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String captchaText,
    bool failed,
    WidgetRef ref,
    FocusNode focusNode,
  ) {
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
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
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
                Positioned(
                  right: 0,
                  child: IconButton(
                    tooltip: 'Refresh CAPTCHA',
                    icon: Icon(Icons.refresh_rounded, color: colorScheme.primary, size: 20),
                    onPressed: () {
                      ref.read(captchaTextProvider.notifier).state = generateCaptcha();
                      ref.read(userInputProvider.notifier).state = '';
                      focusNode.requestFocus();
                      CustomToast.show(
                        context,
                        message: 'CAPTCHA refreshed!',
                        type: ToastType.info,
                        duration: const Duration(seconds: 2),
                        showCloseButton: false,
                      );
                    },
                  ),
                ),
              ],
            ),
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

  Widget _buildInputField(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String userInput,
    WidgetRef ref,
    FocusNode focusNode,
    bool failed,
    TextEditingController controller,
  ) {
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
        controller: controller,
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

  Widget _buildVerifyButton(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isVerifying,
    WidgetRef ref,
    bool failed,
    ValueNotifier<bool> isSuccess,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isSuccess.value
          ? SuccessAnimation(
              key: const ValueKey('success'),
              onComplete: () => Navigator.pop(context, true),
            )
          : SizedBox(
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
                onPressed: isVerifying || failed ? null : () => _handleVerification(context, ref, isSuccess),
              ),
            ),
    );
  }

  void _handleVerification(BuildContext context, WidgetRef ref, ValueNotifier<bool> isSuccess) async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    final captchaText = ref.read(captchaTextProvider);
    final userInput = ref.read(userInputProvider);
    final attempts = ref.read(verificationAttemptsProvider);
    final maxAttempts = 3;

    if (attempts >= maxAttempts) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Too Many Attempts'),
          content: const Text('You have been blocked for now. Please try again later.'),
        ),
      );
      // Wait 2 seconds, then close both dialogs and go back
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
          Navigator.of(context).pop(false); // Pop VerificationScreen, return to WatchAdsScreen
        }
      });
      return;
    }

    ref.read(isVerifyingProvider.notifier).state = true;
    try {
      final success = await ref.read(earningsProvider.notifier).processAdWatch(userInput);
      if (success) {
        // Reload earnings only
        await ref.read(earningsProvider.notifier).loadEarnings();
        isSuccess.value = true;
      } else {
        ref.read(verificationAttemptsProvider.notifier).state++;
        CustomToast.show(
          context,
          message: 'Verification failed. Please try again.',
          type: ToastType.error,
        );
        ref.read(isVerifyingProvider.notifier).state = false;
      }
    } catch (e) {
      ref.read(verificationAttemptsProvider.notifier).state++;
      CustomToast.show(
        context,
        message: 'An error occurred. Please try again.',
        type: ToastType.error,
      );
      ref.read(isVerifyingProvider.notifier).state = false;
    }
  }

  ImageProvider _createPatternImage({required Color color, required double size}) {
    return CustomPatternImage(
      color: color,
      size: size,
    );
  }
}

class CustomPatternImage extends ImageProvider<CustomPatternImage> {
  final Color color;
  final double size;

  const CustomPatternImage({
    required this.color,
    required this.size,
  });

  @override
  Future<CustomPatternImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CustomPatternImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
    CustomPatternImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer, {bool allowUpscaling, int? cacheHeight, int? cacheWidth}) decode,
  ) {
    return OneFrameImageStreamCompleter(_loadImage(key));
  }

  Future<ImageInfo> _loadImage(CustomPatternImage key) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw dots in a grid pattern
    for (var i = 0; i < 10; i++) {
      for (var j = 0; j < 10; j++) {
        canvas.drawCircle(
          Offset(i * size, j * size),
          size / 4,
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (size * 10).toInt(),
      (size * 10).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw Exception('Failed to generate pattern image');
    }
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    return ImageInfo(image: frame.image);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CustomPatternImage &&
        other.color == color &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(color, size);
}