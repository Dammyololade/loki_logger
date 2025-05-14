import 'package:loki_logger/src/log_level.dart';

/// Represents a log event with all relevant information
class LogEvent {
  final Level level;
  final DateTime time;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final String? loggerName;
  final Map<String, String>? customLabels;

  LogEvent({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    DateTime? time,
    this.loggerName,
    this.customLabels,
  }) : time = time ?? DateTime.now();

  /// Creates a formatted message including error and stack trace if present
  String get formattedMessage {
    String result = message;
    if (error != null) {
      result += '\nError: $error';
    }
    if (stackTrace != null) {
      result += '\nStack Trace: $stackTrace';
    }
    return result;
  }
}
