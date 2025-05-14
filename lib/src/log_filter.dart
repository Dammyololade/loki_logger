import 'package:loki_logger/src/log_event.dart';
import 'package:loki_logger/src/log_level.dart';

/// Interface for filtering log events
abstract class LogFilter {
  bool shouldLog(LogEvent event);
}

/// Default filter that only shows logs in debug mode
class DevelopmentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    assert(() {
      return true;
    }());
    return false;
  }
}

/// Filter that shows logs based on minimum level
class LevelFilter extends LogFilter {
  final Level level;

  LevelFilter(this.level);

  @override
  bool shouldLog(LogEvent event) {
    return event.level >= level;
  }
}
