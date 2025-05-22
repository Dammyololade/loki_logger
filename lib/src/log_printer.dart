import 'package:loki_logger/src/log_event.dart';
import 'package:loki_logger/src/log_level.dart';

/// Interface for formatting log events into strings
abstract class LogPrinter {
  List<String> log(LogEvent event);
}

/// Simple printer that outputs the log message
class SimplePrinter extends LogPrinter {
  final bool printTime;

  SimplePrinter({this.printTime = false});

  @override
  List<String> log(LogEvent event) {
    final buffer = StringBuffer();
    if (printTime) {
      buffer.write('${event.time} ');
    }
    buffer.write('[${event.level.name}]');
    if (event.loggerName != null) {
      buffer.write(' ${event.loggerName}:');
    }
    buffer.write(' ${event.formattedMessage}');
    return [buffer.toString()];
  }
}

/// Pretty printer with colors and formatting
class PrettyPrinter extends LogPrinter {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = '─';
  static const singleDivider = '┄';

  final int methodCount;
  final int errorMethodCount;
  final int lineLength;
  final bool colors;
  final bool printEmojis;
  final bool printTime;

  /// ANSI escape code for colors
  static const ansiEscape = '\x1B[';
  static const resetColor = '${ansiEscape}0m';

  static Map<Level, String> levelColors = {
    Level.trace: '${ansiEscape}37m', // White
    Level.debug: '${ansiEscape}36m', // Cyan
    Level.info: '${ansiEscape}32m', // Green
    Level.warning: '${ansiEscape}33m', // Yellow
    Level.error: '${ansiEscape}31m', // Red
    Level.fatal: '${ansiEscape}35m', // Magenta
    Level.nothing: resetColor,
  };

  static Map<Level, String> levelEmojis = {
    Level.trace: '🔍 ',
    Level.debug: '🐛 ',
    Level.info: '💡 ',
    Level.warning: '⚠️ ',
    Level.error: '⛔ ',
    Level.fatal: '💀 ',
    Level.nothing: '',
  };

  PrettyPrinter({
    this.methodCount = 2,
    this.errorMethodCount = 8,
    this.lineLength = 120,
    this.colors = true,
    this.printEmojis = true,
    this.printTime = false,
  });

  String _getColoredString(String string, Level level) {
    if (!colors) return string;
    return '${levelColors[level]}$string$resetColor';
  }

  @override
  List<String> log(LogEvent event) {
    String emoji = printEmojis ? levelEmojis[event.level] ?? '' : '';
    List<String> lines = [];

    // Top border
    lines.add(
      _getColoredString(
        '$topLeftCorner${doubleDivider * (lineLength - 1)}',
        event.level,
      ),
    );

    // Logger name and level
    String header = '$emoji${event.level.name}';
    if (event.loggerName != null) {
      header += ' [${event.loggerName}]';
    }
    if (printTime) {
      header += ' ${event.time.toString()}';
    }
    lines.add(_getColoredString('$verticalLine $header', event.level));

    // Message
    String messageStr = event.message;
    if (messageStr.isNotEmpty) {
      lines.add(
        _getColoredString(
          '$middleCorner${singleDivider * (lineLength - 1)}',
          event.level,
        ),
      );
      _addLines(messageStr, lines, event.level);
    }

    // Error
    if (event.error != null) {
      lines.add(
        _getColoredString(
          '$middleCorner${singleDivider * (lineLength - 1)}',
          event.level,
        ),
      );
      _addLines('ERROR: ${event.error}', lines, event.level);
    }

    // Stack trace
    if (event.stackTrace != null) {
      lines.add(
        _getColoredString(
          '$middleCorner${singleDivider * (lineLength - 1)}',
          event.level,
        ),
      );
      String stackTraceStr = event.stackTrace.toString();
      _addLines('STACK TRACE:', lines, event.level);
      _addLines(
        stackTraceStr,
        lines,
        event.level,
        methodCount: event.error != null ? errorMethodCount : methodCount,
      );
    }

    // Bottom border
    lines.add(
      _getColoredString(
        '$bottomLeftCorner${doubleDivider * (lineLength - 1)}',
        event.level,
      ),
    );

    return lines;
  }

  void _addLines(
    String text,
    List<String> lines,
    Level level, {
    int? methodCount,
  }) {
    List<String> messageLines = text.split('\n');
    if (methodCount != null && methodCount > 0) {
      messageLines = messageLines.take(methodCount).toList();
    }

    for (var line in messageLines) {
      if (line.length > lineLength - 2) {
        // Split long lines
        int current = 0;
        while (current < line.length) {
          int end = current + lineLength - 2;
          if (end >= line.length) {
            end = line.length;
          }
          lines.add(
            _getColoredString(
              '$verticalLine ${line.substring(current, end)}',
              level,
            ),
          );
          current = end;
        }
      } else {
        lines.add(_getColoredString('$verticalLine $line', level));
      }
    }
  }
}
