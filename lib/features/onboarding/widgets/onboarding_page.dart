import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String animation;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Lottie animation with loading state
                Lottie.asset(
                  'assets/animations/$animation',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  options: LottieOptions(enableMergePaths: true),
                  frameBuilder: (context, child, composition) {
                    if (composition != null) {
                      return child;
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Lottie error: $error');
                    return Icon(
                      Icons.animation,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 