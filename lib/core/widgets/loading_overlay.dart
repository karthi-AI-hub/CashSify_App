import 'package:flutter/material.dart';
import 'package:cashsify_app/core/providers/loading_provider.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 