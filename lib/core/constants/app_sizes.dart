import 'package:flutter/material.dart';

/// Class containing standard sizing constants for the app UI
class AppSizes {
  // Padding and margin sizes
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border radius
  static const double borderRadiusXS = 4.0;
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  
  // Button sizes
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;
  
  // Icon sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  
  // Avatar and image sizes
  static const double avatarS = 40.0;
  static const double avatarM = 60.0;
  static const double avatarL = 80.0;
  static const double avatarXL = 120.0;
  
  // Text field heights
  static const double textFieldHeight = 56.0;
  
  // Card sizes
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  
  // Product image aspect ratio
  static const double productImageAspectRatio = 1.0;
  static const double productGridImageHeight = 160.0;
  
  // Screen edge padding
  static const EdgeInsets screenPadding = EdgeInsets.all(m);
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets screenVerticalPadding = EdgeInsets.symmetric(vertical: m);
  
  // Gap heights
  static const SizedBox gapH4 = SizedBox(height: xs);
  static const SizedBox gapH8 = SizedBox(height: s);
  static const SizedBox gapH16 = SizedBox(height: m);
  static const SizedBox gapH24 = SizedBox(height: l);
  static const SizedBox gapH32 = SizedBox(height: xl);
  static const SizedBox gapH48 = SizedBox(height: xxl);
  
  // Gap widths
  static const SizedBox gapW4 = SizedBox(width: xs);
  static const SizedBox gapW8 = SizedBox(width: s);
  static const SizedBox gapW16 = SizedBox(width: m);
  static const SizedBox gapW24 = SizedBox(width: l);
  static const SizedBox gapW32 = SizedBox(width: xl);
  static const SizedBox gapW48 = SizedBox(width: xxl);
}
