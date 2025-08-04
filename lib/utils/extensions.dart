import 'dart:math' show pow;
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
  
  // Navigation helpers
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );
      
  Future<T?> pushReplacement<T, TO>(Widget page) => Navigator.of(this).pushReplacement<T, TO>(
        MaterialPageRoute(builder: (_) => page) as Route<T>,
      );

  // SnackBar helpers
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
  
  // Currency formatting
  String formatCurrency(double amount, {String symbol = '₵'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
  
  // Focus helpers
  void unfocus() => FocusScope.of(this).unfocus();
  void requestFocus(FocusNode focusNode) => FocusScope.of(this).requestFocus(focusNode);
  
  // Dialog helpers
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
}

/// Extension methods for String
extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  // Title case
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  // Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }
  
  // Check if string is a valid phone number
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(this);
  }
  
  // Check if string is a valid URL
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    return urlRegex.hasMatch(this);
  }
  
  // Remove all whitespaces
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');
  
  // Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  // Format date as "MMM dd, yyyy"
  String get formattedDate => DateFormat('MMM dd, yyyy').format(this);
  
  // Format date as "MMM dd, yyyy hh:mm a"
  String get formattedDateTime => DateFormat('MMM dd, yyyy hh:mm a').format(this);
  
  // Format time as "hh:mm a"
  String get formattedTime => DateFormat('hh:mm a').format(this);
  
  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  // Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  // Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 0) {
      if (isYesterday) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
      if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extension methods for double
extension DoubleExtensions on double {
  // Format currency
  String toCurrency({String symbol = '₵', int decimalDigits = 2}) {
    return '$symbol${toStringAsFixed(decimalDigits)}';
  }
  
  // Format percentage
  String toPercentage({int decimalDigits = 1}) {
    return '${toStringAsFixed(decimalDigits)}%';
  }
  
  // Round to specific decimal places
  double roundToDecimalPlaces(int decimalPlaces) {
    final mod = pow(10.0, decimalPlaces);
    return ((this * mod).round().toDouble() / mod);
  }
}

/// Extension methods for int
extension IntExtensions on int {
  // Format as currency
  String toCurrency({String symbol = '₵'}) {
    return '$symbol$this';
  }
  
  // Format with thousands separator
  String get withThousandsSeparator {
    return NumberFormat('#,###').format(this);
  }
  
  // Convert to ordinal (1st, 2nd, 3rd, etc.)
  String get ordinal {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}

/// Extension methods for List
extension ListExtensions<T> on List<T> {
  // Safely get element at index
  T? elementAtOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
  
  // Check if list has duplicates
  bool get hasDuplicates => length != toSet().length;
  
  // Remove duplicates
  List<T> get removeDuplicates => toSet().toList();
  
  // Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

// Import pow for DoubleExtensions (moved to top of file) 