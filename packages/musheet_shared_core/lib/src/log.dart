import 'package:flutter/foundation.dart';

/// Centralized logging utility for MuSheet.
class Log {
  Log._();

  /// Debug level - detailed internal state.
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Info level - key operations, state changes.
  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Warning level - recoverable issues.
  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $message');
    }
  }

  /// Error level - failures, exceptions.
  static void e(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) {
        debugPrint('[$tag] Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$tag] StackTrace: $stackTrace');
      }
    }
  }
}
