import 'package:loki_logger/src/log_event.dart';

/// Log levels based on severity
enum Level {
  trace(0, 'TRACE'),
  debug(1, 'DEBUG'),
  info(2, 'INFO'),
  warning(3, 'WARNING'),
  error(4, 'ERROR'),
  fatal(5, 'FATAL'),
  nothing(6, 'NOTHING');

  final int value;
  final String name;

  const Level(this.value, this.name);

  bool operator >=(Level other) => value >= other.value;

  bool operator <=(Level other) => value <= other.value;

  bool operator >(Level other) => value > other.value;

  bool operator <(Level other) => value < other.value;

  /// Converts this level to the corresponding Loki level string
  String toLokiLevel() {
    switch (this) {
      case Level.trace:
      case Level.debug:
        return 'debug';
      case Level.info:
        return 'info';
      case Level.warning:
        return 'warn';
      case Level.error:
        return 'error';
      case Level.fatal:
        return 'fatal';
      case Level.nothing:
        return 'info';
    }
  }
}
