import 'package:loki_logger/src/loki_client.dart';
import 'package:loki_logger/src/loki_config.dart';
import 'package:loki_logger/src/log_level.dart';
import 'package:loki_logger/src/log_event.dart';
import 'package:loki_logger/src/log_filter.dart';
import 'package:loki_logger/src/log_printer.dart';
import 'package:loki_logger/src/log_output.dart';

/// Main logger class that brings together filter, printer, and output
class LokiLogger {
  /// Global logger level
  static Level level = Level.info;

  /// The log filter
  final LogFilter filter;

  /// The log printer
  final LogPrinter printer;

  /// The log output
  final LogOutput output;

  /// The logger name
  final String? name;

  /// Configuration for the logger to connect to Loki Server
  /// If set, the logger will send log events to Loki Server
  final LokiConfig? config;

  /// Loki client to send log events to Loki Server
  late LokiClient? lokiClient;

  /// Creates a new Logger instance
  LokiLogger({
    this.name,
    this.config,
    LogFilter? filter,
    LogPrinter? printer,
    LogOutput? output,
  })  : filter = filter ?? LevelFilter(level),
        printer = printer ?? PrettyPrinter(),
        lokiClient = config != null ? LokiClient(config: config) : null,
        output = output ?? ConsoleOutput();

  /// Log a trace message
  void t(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.trace, message, error, stackTrace, customLabels);
  }

  /// Log a debug message
  void d(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.debug, message, error, stackTrace, customLabels);
  }

  /// Log an info message
  void i(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.info, message, error, stackTrace, customLabels);
  }

  /// Log a warning message
  void w(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.warning, message, error, stackTrace, customLabels);
  }

  /// Log an error message
  void e(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.error, message, error, stackTrace, customLabels);
  }

  /// Log a fatal message
  void f(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    log(Level.fatal, message, error, stackTrace, customLabels);
  }

  /// Log a message at the specified level
  void log(
    Level level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? customLabels,
  ]) {
    final event = LogEvent(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      loggerName: name,
      customLabels: customLabels,
    );

    if (filter.shouldLog(event)) {
      List<String> lines = printer.log(event);
      output.output(lines);
    }

    if (lokiClient != null) {
      lokiClient!.log(
        level: level.toLokiLevel(),
        message: message,
        error: error,
        stackTrace: stackTrace,
        time: event.time,
        loggerName: name,
        customLabels: event.customLabels,
      );
    }
  }

  /// Disposes resources used by this logger
  ///
  /// This should be called when the logger is no longer needed
  /// to free up resources and prevent memory leaks.
  void dispose() {
    lokiClient?.dispose();
  }
}
