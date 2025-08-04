import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension methods for BuildContext
extension BuildContextExtensions on BuildContext {
  // Theme extensions
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // Media query extensions
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get statusBarHeight => mediaQuery.padding.top;
  double get bottomPadding => mediaQuery.padding.bottom;
  EdgeInsets get viewPadding => mediaQuery.viewPadding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  // Orientation
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  
  // Responsive breakpoints
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  
  // Helper methods
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
    );
  }
  
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.red,
    );
  }
  
  // Navigation helpers
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );
      
  Future<T?> pushReplacement<T, TO>(Widget page) => Navigator.of(this).pushReplacement<T, TO>(
        MaterialPageRoute(builder: (_) => page) as Route<T>,
      );
      
  // Formatting helpers
  String formatCurrency(double value) {
    return NumberFormat.currency(symbol: '₵', decimalDigits: 2).format(value);
  }
}

extension ContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // MediaQuery shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  bool get isKeyboardOpen => MediaQuery.of(this).viewInsets.bottom > 0;
  
  // Breakpoints
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  
  // Navigation shortcuts
  NavigatorState get navigator => Navigator.of(this);
  void pop([Object? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T extends Object?>(Route<T> route) => Navigator.of(this).push(route);
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) => 
      Navigator.of(this).pushNamed(routeName, arguments: arguments);
  
  // ScaffoldMessenger shortcuts
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  
  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
  
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
  
  void showWarningSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }
  
  void showInfoSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
  
  // Focus shortcuts
  void unfocus() => FocusScope.of(this).unfocus();
  void requestFocus(FocusNode focusNode) => FocusScope.of(this).requestFocus(focusNode);
  
  // Currency formatting
  String formatCurrency(double amount, {String symbol = '₵'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
  // Dialog shortcuts
  Future<T?> showConfirmDialog<T>({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDangerous 
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  Future<void> showLoadingDialog({String? message}) {
    return showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message ?? 'Loading...'),
            ),
          ],
        ),
      ),
    );
  }
  
  void hideLoadingDialog() {
    Navigator.of(this).pop();
  }
}
