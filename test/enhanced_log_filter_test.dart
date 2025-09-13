import 'package:test/test.dart';
import 'package:loki_logger/src/enhanced_log_filter.dart';
import 'package:loki_logger/src/log_event.dart';
import 'package:loki_logger/src/log_level.dart';
import 'package:loki_logger/src/log_filter.dart';

void main() {
  group('EnhancedLogFilter', () {
    late DateTime testTime;
    late LogEvent debugEvent;
    late LogEvent infoEvent;
    late LogEvent warningEvent;
    late LogEvent errorEvent;
    late LogEvent eventWithError;
    late LogEvent eventWithStackTrace;
    late LogEvent eventWithLabels;
    late LogEvent eventWithLoggerName;

    setUp(() {
      testTime = DateTime.now();
      
      debugEvent = LogEvent(
        level: Level.debug,
        message: 'Debug message',
        time: testTime,
      );
      
      infoEvent = LogEvent(
        level: Level.info,
        message: 'Info message',
        time: testTime,
      );
      
      warningEvent = LogEvent(
        level: Level.warning,
        message: 'Warning message',
        time: testTime,
      );
      
      errorEvent = LogEvent(
        level: Level.error,
        message: 'Error message',
        time: testTime,
      );
      
      eventWithError = LogEvent(
        level: Level.error,
        message: 'Error with exception',
        error: Exception('Test exception'),
        time: testTime,
      );
      
      eventWithStackTrace = LogEvent(
        level: Level.error,
        message: 'Error with stack trace',
        stackTrace: StackTrace.current,
        time: testTime,
      );
      
      eventWithLabels = LogEvent(
        level: Level.info,
        message: 'Event with labels',
        customLabels: {'service': 'auth', 'version': '1.0'},
        time: testTime,
      );
      
      eventWithLoggerName = LogEvent(
        level: Level.info,
        message: 'Event with logger name',
        loggerName: 'TestLogger',
        time: testTime,
      );
    });

    group('Level filtering', () {
      test('should filter by minimum level', () {
        final filter = EnhancedLogFilter(minLevel: Level.warning);
        
        expect(filter.shouldLog(debugEvent), false);
        expect(filter.shouldLog(infoEvent), false);
        expect(filter.shouldLog(warningEvent), true);
        expect(filter.shouldLog(errorEvent), true);
      });
      
      test('should allow all levels when no minimum is set', () {
        final filter = EnhancedLogFilter();
        
        expect(filter.shouldLog(debugEvent), true);
        expect(filter.shouldLog(infoEvent), true);
        expect(filter.shouldLog(warningEvent), true);
        expect(filter.shouldLog(errorEvent), true);
      });
    });

    group('Time filtering', () {
      test('should filter by time window', () {
        final oldEvent = LogEvent(
          level: Level.info,
          message: 'Old message',
          time: DateTime.now().subtract(const Duration(hours: 2)),
        );
        
        final recentEvent = LogEvent(
          level: Level.info,
          message: 'Recent message',
          time: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        
        final filter = EnhancedLogFilter(
          timeWindow: const Duration(hours: 1),
        );
        
        expect(filter.shouldLog(oldEvent), false);
        expect(filter.shouldLog(recentEvent), true);
      });
    });

    group('Logger name filtering', () {
      test('should filter by allowed logger names', () {
        final filter = EnhancedLogFilter(
          allowedLoggerNames: ['TestLogger', 'AuthLogger'],
        );
        
        expect(filter.shouldLog(eventWithLoggerName), true);
        expect(filter.shouldLog(infoEvent), false); // no logger name
      });
      
      test('should filter by blocked logger names', () {
        final filter = EnhancedLogFilter(
          blockedLoggerNames: ['TestLogger'],
        );
        
        expect(filter.shouldLog(eventWithLoggerName), false);
        expect(filter.shouldLog(infoEvent), true); // no logger name
      });
    });

    group('Custom label filtering', () {
      test('should filter by required labels', () {
        final filter = EnhancedLogFilter(
          requiredLabels: {'service': 'auth'},
        );
        
        expect(filter.shouldLog(eventWithLabels), true);
        expect(filter.shouldLog(infoEvent), false); // no labels
      });
    });

    group('Message length filtering', () {
      test('should filter by maximum message length', () {
        final filter = EnhancedLogFilter(
          maxMessageLength: 20,
        );
        
        final shortMsg = LogEvent(
          level: Level.info,
          message: 'Short',
          time: testTime,
        );
        
        final longMsg = LogEvent(
          level: Level.info,
          message: 'This is a very long message that exceeds the maximum length',
          time: testTime,
        );
        
        expect(filter.shouldLog(shortMsg), true);
        expect(filter.shouldLog(longMsg), false);
      });
    });

    group('Factory methods', () {
      test('debug factory should create appropriate filter', () {
        final filter = EnhancedLogFilter.debug();
        
        expect(filter.shouldLog(debugEvent), true);
        expect(filter.shouldLog(infoEvent), true);
        expect(filter.shouldLog(eventWithError), true);
      });
      
      test('production factory should create appropriate filter', () {
        final filter = EnhancedLogFilter.production();
        
        expect(filter.shouldLog(debugEvent), false);
        expect(filter.shouldLog(infoEvent), false);
        expect(filter.shouldLog(warningEvent), true);
        expect(filter.shouldLog(errorEvent), true);
      });
      
      test('errorsOnly factory should create appropriate filter', () {
        final filter = EnhancedLogFilter.errorsOnly();
        
        expect(filter.shouldLog(debugEvent), false);
        expect(filter.shouldLog(infoEvent), false);
        expect(filter.shouldLog(warningEvent), false);
        expect(filter.shouldLog(errorEvent), true);
      });
    });
  });

  group('CompositeLogFilter', () {
    test('should use AND logic by default', () {
      final levelFilter = EnhancedLogFilter(minLevel: Level.warning);
      final lengthFilter = EnhancedLogFilter(maxMessageLength: 50);
      final composite = CompositeLogFilter([levelFilter, lengthFilter]);
      
      final shortWarning = LogEvent(
        level: Level.warning,
        message: 'Short warning',
        time: DateTime.now(),
      );
      
      final longWarning = LogEvent(
        level: Level.warning,
        message: 'This is a very long warning message that exceeds the maximum length limit',
        time: DateTime.now(),
      );
      
      expect(composite.shouldLog(shortWarning), true); // passes both
      expect(composite.shouldLog(longWarning), false); // fails length filter
    });
    
    test('should return true for empty filter list', () {
      final composite = CompositeLogFilter([]);
      
      final testEvent = LogEvent(
        level: Level.debug,
        message: 'Test message',
        time: DateTime.now(),
      );
      
      expect(composite.shouldLog(testEvent), true);
    });
  });
}
