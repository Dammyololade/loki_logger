import 'package:loki_logger/loki_logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateMocks([LogOutput, LogFilter, LokiClient])
import 'logger_test.mocks.dart';

void main() {
  group('LokiLogger', () {
    late MockLogOutput mockOutput;
    late MockLogFilter mockFilter;
    late LokiLogger logger;

    setUp(() {
      mockOutput = MockLogOutput();
      mockFilter = MockLogFilter();
      logger = LokiLogger(
        name: 'TestLogger',
        filter: mockFilter,
        output: mockOutput,
      );
    });

    test('should not log when filter returns false', () {
      // Arrange
      when(mockFilter.shouldLog(any)).thenReturn(false);

      // Act
      logger.d('Test message');

      // Assert
      verifyNever(mockOutput.output(any));
    });

    test('should log when filter returns true', () {
      // Arrange
      when(mockFilter.shouldLog(any)).thenReturn(true);

      // Act
      logger.d('Test message');

      // Assert
      verify(mockOutput.output(any)).called(1);
    });

    test('should log with correct level', () {
      // Arrange
      when(mockFilter.shouldLog(any)).thenReturn(true);

      // Act
      logger.d('Debug message');
      logger.i('Info message');
      logger.w('Warning message');
      logger.e('Error message');
      logger.f('Fatal message');

      // Assert
      verify(mockOutput.output(any)).called(5);

      // Capture the log event to verify level
      final logEventCaptor = verify(mockFilter.shouldLog(captureAny)).captured;
      expect(logEventCaptor[0].level, equals(Level.debug));
      expect(logEventCaptor[1].level, equals(Level.info));
      expect(logEventCaptor[2].level, equals(Level.warning));
      expect(logEventCaptor[3].level, equals(Level.error));
      expect(logEventCaptor[4].level, equals(Level.fatal));
    });

    test('should include error and stack trace in log event', () {
      // Arrange
      when(mockFilter.shouldLog(any)).thenReturn(true);
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      // Act
      logger.e('Error occurred', error, stackTrace);

      // Assert
      final logEventCaptor =
          verify(mockFilter.shouldLog(captureAny)).captured.single;
      expect(logEventCaptor.error, equals(error));
      expect(logEventCaptor.stackTrace, equals(stackTrace));
    });

    test('should include custom labels in log event', () {
      // Arrange
      when(mockFilter.shouldLog(any)).thenReturn(true);
      final customLabels = {'key1': 'value1', 'key2': 'value2'};

      // Act
      logger.i('Info with labels', null, null, customLabels);

      // Assert
      final logEventCaptor =
          verify(mockFilter.shouldLog(captureAny)).captured.single;
      expect(logEventCaptor.customLabels, equals(customLabels));
    });

    test('should use LokiClient when config is provided', () {
      when(mockFilter.shouldLog(any)).thenReturn(true);
      const config = LokiConfig(host: 'http://localhost:3100');
      final loggerWithConfig = LokiLogger(
        name: 'LoggerWithConfig',
        filter: mockFilter,
        output: mockOutput,
        config: config,
      );

      // Just verify it doesn't throw an exception
      expect(() => loggerWithConfig.i('Test with config'), returnsNormally);
    });
  });

  group('LevelFilter', () {
    test('should filter based on level', () {
      final infoFilter = LevelFilter(Level.info);

      final traceEvent = LogEvent(level: Level.trace, message: 'Trace');
      final debugEvent = LogEvent(level: Level.debug, message: 'Debug');
      final infoEvent = LogEvent(level: Level.info, message: 'Info');
      final warningEvent = LogEvent(level: Level.warning, message: 'Warning');
      final errorEvent = LogEvent(level: Level.error, message: 'Error');

      expect(infoFilter.shouldLog(traceEvent), isFalse);
      expect(infoFilter.shouldLog(debugEvent), isFalse);
      expect(infoFilter.shouldLog(infoEvent), isTrue);
      expect(infoFilter.shouldLog(warningEvent), isTrue);
      expect(infoFilter.shouldLog(errorEvent), isTrue);
    });
  });
}
