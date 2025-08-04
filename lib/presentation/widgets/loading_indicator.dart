import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final String? lottieAsset;
  final double? lottieHeight;
  final bool useScaffold;

  const LoadingIndicator({
    super.key,
    this.message,
    this.lottieAsset = 'assets/animations/loading.json',
    this.lottieHeight = 120.0,
    this.useScaffold = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lottieAsset != null) ...[
            Lottie.asset(
              lottieAsset!,
              height: lottieHeight,
              repeat: true,
            ),
          ] else ...[
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (useScaffold) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: loadingWidget,
      );
    }

    return loadingWidget;
  }
}
