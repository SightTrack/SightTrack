import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class Log {
  static final Logger _logger = Logger('SightTrack');

  static void init() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord record) {
      final logMessage =
          '[${record.level.name}] '
          '[${record.loggerName}] ${record.message}';

      if (kDebugMode) {
        debugPrintSynchronously(logMessage);
      }

      if (record.error != null) {
        if (kDebugMode) {
          debugPrintSynchronously('Error: ${record.error}');
        }
      }
      if (record.stackTrace != null) {
        if (kDebugMode) {
          debugPrintSynchronously('StackTrace: ${record.stackTrace}');
        }
      }
    });
  }

  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.fine(message, error, stackTrace);
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.info(message, error, stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.warning(message, error, stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.severe(message, error, stackTrace);
  }

  static void critical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.shout(message, error, stackTrace);
  }

  static void logCustom(
    Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.log(level, message, error, stackTrace);
  }
}
