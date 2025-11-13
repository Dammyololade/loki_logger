# Loki Logger

[![pub package](https://img.shields.io/pub/v/loki_logger.svg)](https://pub.dev/packages/loki_logger)

A powerful, flexible logging solution for Dart and Flutter applications with Grafana Loki integration. Inspired by [logger](https://pub.dev/packages/logger) for Dart.

## Features

- 📊 **Complete Logging Solution**: Local logging with formatting and filtering
- 🔄 **Grafana Loki Integration**: Send logs directly to your Loki server
- 🧩 **Modular Architecture**: Use components together or separately
- 🎨 **Pretty Printing**: Beautiful, formatted logs in the console
- 🔍 **Customizable Filtering**: Control which logs are processed
- 📦 **Batched Log Sending**: Efficient log transmission to Loki

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  loki_logger: ^latest_version
```

Then run:

```bash
$ flutter pub get
```

## Quick Start

```dart
// Create a simple logger
final logger = LokiLogger();

// Start logging!
logger.d("Debug message");
logger.i("Info message");
logger.w("Warning message");
logger.e("Error message", Exception("Something went wrong"));
```

## Usage Scenarios

### Local Logging Only

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

logger.i('Application started');
```

### Loki Integration

```dart
final logger = LokiLogger(
  name: 'AppLogger',
  config: LokiConfig(
    host: 'https://loki.example.com',
    labels: {'app': 'my_app', 'environment': 'production'},
    batching: true,
    interval: 10,
  ),
);

logger.i('User logged in');
```

### Using LokiClient Directly

```dart
final lokiClient = LokiClient(
  config: LokiConfig(
    host: 'https://loki.example.com',
    labels: {'app': 'my_app'},
  ),
);

lokiClient.log(
  level: 'info',
  message: 'User action',
  customLabels: {'user_id': '12345'},
);

// Don't forget to dispose when done
lokiClient.dispose();
```

## Configuration

### Log Levels

Loki Logger supports the following log levels (in order of verbosity):

- `Level.trace`: Detailed tracing information
- `Level.debug`: Debug information
- `Level.info`: General information
- `Level.warning`: Warnings
- `Level.error`: Errors
- `Level.fatal`: Critical errors

Set the global log level:

```dart
// In development
LokiLogger.level = Level.debug;

// In production
LokiLogger.level = Level.info;
```

### LokiConfig Options

```dart
LokiConfig(
  host: 'https://loki.example.com',  // Required
  interval: 10,                       // Seconds between batch sends
  batching: true,                     // Enable/disable batching
  clearOnError: false,                // Whether to discard logs on error
  replaceTimestamp: true,             // Replace log timestamps with current time
  labels: {'app': 'my_app'},          // Global labels
  timeout: 5000,                      // Request timeout in milliseconds
  basicAuth: 'username:password',     // Basic auth credentials
);
```

### Dynamic Label Management

You can add, remove, or reset labels at runtime. This is useful for adding contextual information like user IDs, session IDs, or other dynamic metadata:

```dart
final logger = LokiLogger(
  config: LokiConfig(
    host: 'https://loki.example.com',
    labels: {'app': 'my_app'},
  ),
);

// Add new labels (will be included in all subsequent logs)
logger.addLabels({
  'user_id': '12345',
  'session_id': 'abc-def-ghi',
});

logger.i('User action logged'); // Includes user_id and session_id labels

// Remove a specific label
logger.removeLabel('session_id');

logger.i('Another action'); // Only includes user_id label

// Reset all labels (removes all labels added via addLabels or config)
logger.resetLabels();

logger.i('Final action'); // No additional labels
```

**Note:** Labels added via `addLabels()` persist across all subsequent log calls until removed or reset. You can also add one-time labels to individual log calls using the `customLabels` parameter:

```dart
logger.i('Special event', null, null, {'event_type': 'purchase'});
```

## Best Practices

1. **Configure Appropriate Log Levels**: Use different levels for development and production
2. **Use Batching in Production**: More efficient for high-volume logging
3. **Add Contextual Information with Labels**: Enhance logs with metadata
4. **Include Error Objects and Stack Traces**: For better debugging
5. **Dispose Resources**: Clean up when using LokiClient directly

## Credits

This package was inspired by the [logger](https://pub.dev/packages/logger) package for Dart, originally created by Simon Choi and further developed by Harm Aarts. Loki Logger extends the functionality with Grafana Loki integration while maintaining a similar API.

## License

This project is licensed under the MIT License - see the LICENSE file for details.