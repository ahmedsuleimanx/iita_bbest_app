import 'package:flutter/foundation.dart';

/// A simple logger utility class for consistent logging across the app.
/// This avoids direct use of print statements in production code.
class AppLogger {
  /// Log an informational message
  static void info(String message) {
    _log('INFO', message);
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      _log('ERROR', '└─ Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      _log('ERROR', '└─ StackTrace: $stackTrace');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    _log('WARNING', message);
  }

  /// Log a debug message (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      _log('DEBUG', message);
    }
  }

  /// Internal logging method
  static void _log(String level, String message) {
    if (kDebugMode) {
      debugPrint('[$level] $message');
    }
  }
}
