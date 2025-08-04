import 'package:flutter/material.dart';

/// Class containing size constants for consistent UI across the app
class AppSizes {
  // Spacing
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p48 = 48.0;
  static const double p64 = 64.0;

  // Alternative naming
  static const double s = 8.0;   // small
  static const double m = 16.0;  // medium  
  static const double l = 24.0;  // large
  static const double xl = 32.0; // extra large

  // Border radius
  static const double br4 = 4.0;
  static const double br8 = 8.0;
  static const double br12 = 12.0;
  static const double br16 = 16.0;
  static const double br20 = 20.0;

  // Card properties
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Common spacers
  static const Widget smallVerticalSpacer = SizedBox(height: p8);
  static const Widget mediumVerticalSpacer = SizedBox(height: p16);
  static const Widget largeVerticalSpacer = SizedBox(height: p24);

  static const Widget smallHorizontalSpacer = SizedBox(width: p8);
  static const Widget mediumHorizontalSpacer = SizedBox(width: p16);
  static const Widget largeHorizontalSpacer = SizedBox(width: p24);

  // Gaps (newer naming convention)
  static const Widget gapH4 = SizedBox(height: p4);
  static const Widget gapH8 = SizedBox(height: p8);
  static const Widget gapH12 = SizedBox(height: p12);
  static const Widget gapH16 = SizedBox(height: p16);
  static const Widget gapH20 = SizedBox(height: p20);
  static const Widget gapH24 = SizedBox(height: p24);
  static const Widget gapH32 = SizedBox(height: p32);

  static const Widget gapW4 = SizedBox(width: p4);
  static const Widget gapW8 = SizedBox(width: p8);
  static const Widget gapW12 = SizedBox(width: p12);
  static const Widget gapW16 = SizedBox(width: p16);
  static const Widget gapW20 = SizedBox(width: p20);
  static const Widget gapW24 = SizedBox(width: p24);
  static const Widget gapW32 = SizedBox(width: p32);

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  // Button dimensions
  static const double buttonHeight = 48.0;
  static const double buttonMinWidth = 120.0;

  // Input field dimensions
  static const double inputHeight = 48.0;

  // Avatar sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
}
