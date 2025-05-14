# Loki Logger Documentation

## Overview

Loki Logger is a powerful logging solution for Dart and Flutter applications with Grafana Loki integration. It provides a flexible architecture that allows you to use its components together or separately based on your needs.

This documentation covers the two main classes:

1. **LokiLogger**: A complete logging solution that handles local logging with formatting and filtering
2. **LokiClient**: A dedicated client for sending logs to a Grafana Loki server

## LokiLogger Class

`LokiLogger` is the main class that brings together filtering, printing, and output functionality for logging.

### Class Structure

```dart
class LokiLogger {
  static Level level = Level.info;
  final LogFilter filter;
  final LogPrinter printer;
  final LogOutput output;
  final String? name;
  final LokiConfig? config;
  
  // Constructor and methods...
}
```

### Properties

- **level**: Static property that sets the global minimum log level
- **filter**: Determines which log events should be processed
- **printer**: Formats log events into strings
- **output**: Handles where the formatted logs are sent (e.g., console)
- **name**: Optional name for the logger instance
- **config**: Optional configuration for connecting to a Loki server

### Constructor

```dart
LokiLogger({
  this.name,
  this.config,
  LogFilter? filter,
  LogPrinter? printer,
  LogOutput? output,
}) : filter = filter ?? LevelFilter(level),
     printer = printer ?? PrettyPrinter(),
     output = output ?? ConsoleOutput();
```

The constructor allows you to customize all aspects of the logger. If not specified, it uses sensible defaults:
- A level filter based on the global level
- A pretty printer for formatted console output
- Console output for displaying logs

### Logging Methods

LokiLogger provides convenient shorthand methods for different log levels:

```dart
void t(String message, [Object? error, StackTrace? stackTrace]) // Trace
void d(String message, [Object? error, StackTrace? stackTrace]) // Debug
void i(String message, [Object? error, StackTrace? stackTrace]) // Info
void w(String message, [Object? error, StackTrace? stackTrace]) // Warning
void e(String message, [Object? error, StackTrace? stackTrace]) // Error
void f(String message, [Object? error, StackTrace? stackTrace]) // Fatal
```

All these methods call the main `log` method with the appropriate level.

### Main Log Method

```dart
void log(
  Level level,
  String message, [
  Object? error,
  StackTrace? stackTrace,
])
```

This method:
1. Creates a `LogEvent` with all the provided information
2. Checks if the event should be logged based on the filter
3. If it should be logged, formats the event using the printer and sends it to the output
4. If a Loki configuration is provided, also sends the log to the Loki server

## LokiClient Class

`LokiClient` is responsible for sending logs to a Grafana Loki server. It can be used independently or as part of the `LokiLogger`.

### Class Structure

```dart
class LokiClient {
  final LokiConfig config;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _batchTimer;
  
  // Constructor and methods...
}
```

### Properties

- **config**: Configuration for connecting to the Loki server
- **_queue**: Internal queue for batched logs
- **_batchTimer**: Timer for sending batched logs

### Constructor

```dart
LokiClient({required this.config}) {
  if (config.batching) {
    _batchTimer = Timer.periodic(
      Duration(seconds: config.interval),
      (_) => _sendBatch(),
    );
  }
}
```

The constructor initializes the client with the provided configuration and sets up a timer for batch sending if batching is enabled.

### Log Method

```dart
void log({
  required String level,
  required String message,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
  String? loggerName,
  Map<String, String>? customLabels,
})
```

This method:
1. Formats the log message with error and stack trace if provided
2. Creates a log entry with timestamp, message, and labels
3. Either adds the entry to the queue (if batching is enabled) or sends it immediately

### Internal Methods

- **_prepareLabels**: Formats labels for Loki in the required format
- **_sendBatch**: Sends all queued logs as a batch
- **_sendLogs**: Handles the actual HTTP request to the Loki server
- **dispose**: Cleans up resources and sends any remaining logs

## LokiConfig Class

`LokiConfig` contains all the configuration options for connecting to a Loki server.

### Properties

- **host**: URL for the Grafana Loki server (required)
- **interval**: The interval in seconds at which batched logs are sent (default: 5)
- **batching**: Whether to use batching for logs (default: true)
- **clearOnError**: Whether to discard logs that result in an error during transport (default: false)
- **replaceTimestamp**: Whether to replace log timestamps with current time (default: true)
- **labels**: Custom labels to attach to all logs (optional)
- **timeout**: Timeout for requests to Grafana Loki in milliseconds (optional)
- **basicAuth**: Basic authentication credentials to access Loki over HTTP (optional)

## Usage Scenarios

### Scenario 1: Using LokiLogger for Local Logging Only

If you only need local logging without sending logs to a Loki server:

```dart
final logger = LokiLogger(
  name: 'AppLogger',
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Log messages at different levels
logger.d('This is a debug message');
logger.i('Application started');
logger.w('Something might be wrong');

try {
  // Simulate an error
  throw Exception('Something went wrong');
} catch (e, stackTrace) {
  // Log the error with stack trace
  logger.e('An error occurred', e, stackTrace);
}
```

In this scenario, logs will only be printed to the console with the specified formatting.

### Scenario 2: Using LokiClient Directly with an Existing Logging System

If you already have a logging system and just want to add Loki integration:

```dart
// Create a Loki client
final lokiClient = LokiClient(
  config: LokiConfig(
    host: 'https://loki.example.com',
    labels: {'app': 'my_app', 'environment': 'production'},
    batching: true,
    interval: 10,
    basicAuth: 'username:password',
  ),
);

// Log directly to Loki
lokiClient.log(
  level: 'info',
  message: 'User logged in',
  customLabels: {'user_id': '12345'},
);

// Don't forget to dispose when done
lokiClient.dispose();
```

This approach allows you to integrate Loki with any existing logging framework by calling the `log` method directly.

### Scenario 3: Using LokiLogger with Loki Integration

For a complete solution that handles both local logging and sending to Loki:

```dart
final logger = LokiLogger(
  name: 'AppLogger',
  config: LokiConfig(
    host: 'https://loki.example.com',
    labels: {'app': 'my_app', 'environment': 'production'},
    batching: true,
    interval: 10,
    basicAuth: 'username:password',
  ),
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// Log messages at different levels
logger.d('This is a debug message');
logger.i('Application started');
logger.w('Something might be wrong');

try {
  // Simulate an error
  throw Exception('Something went wrong');
} catch (e, stackTrace) {
  // Log the error with stack trace
  logger.e('An error occurred', e, stackTrace);
}
```

In this scenario, logs will be both printed to the console and sent to the Loki server.

## Best Practices

### 1. Configure Appropriate Log Levels

Set the global log level based on your environment:

```dart
// In development
LokiLogger.level = Level.debug;

// In production
LokiLogger.level = Level.info;
```

### 2. Use Batching for Production

Batching logs is more efficient for production environments:

```dart
final config = LokiConfig(
  host: 'https://loki.example.com',
  batching: true,
  interval: 30, // Send logs every 30 seconds
);
```

### 3. Add Contextual Information with Labels

Use labels to add context to your logs:

```dart
// Global labels for all logs
final config = LokiConfig(
  host: 'https://loki.example.com',
  labels: {'app': 'my_app', 'version': '1.0.0'},
);

// Custom labels for specific logs
logger.log(
  level: Level.info,
  message: 'User action',
  customLabels: {'user_id': '12345', 'action': 'login'},
);
```

### 4. Properly Handle Errors

Always include error objects and stack traces when logging errors:

```dart
try {
  // Some operation that might fail
} catch (e, stackTrace) {
  logger.e('Operation failed', e, stackTrace);
}
```

### 5. Dispose Resources

If you're using the LokiClient directly, make sure to dispose it when done:

```dart
// When your application is shutting down
lokiClient.dispose();
```

## Conclusion

Loki Logger provides a flexible logging solution that can be adapted to various use cases. Whether you need a simple local logging system or a complete solution with Loki integration, you can configure the components to meet your specific requirements.

By understanding the different components and how they interact, you can create a logging strategy that works best for your application.