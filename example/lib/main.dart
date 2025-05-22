import 'package:loki_logger/loki_logger.dart';

const host = 'http://localhost:3100';
const username = 'example';
const password = 'example';

void main() {
  // Setup the LokiLogger with our new Logger implementation
  final logger = LokiLogger(
    config: const LokiConfig(
      host: host,
      // Replace with your Loki server URL
      labels: {
        'app': 'flutter_test_app',
        'tag': 'Onboarding',
        'env': 'dev',
        'version': '1.0.0',
        'user': 'John Doe',
        'device': 'iPhone',
        'os': 'iOS',
        'os_version': '14.5',
      },
      // Global labels for all logs
      interval: 5,
      // Send logs every 5 seconds
      batching: true,
      // Use batching for better performance
      basicAuth: "$username:$password",
    ),
    // Basic authentication credentials
    name: 'TestApp', // Name for this logger instance
    // Optional: customize the printer
    printer: PrettyPrinter(
      methodCount: 2,
      // Number of method calls to be displayed
      errorMethodCount: 8,
      // Number of method calls if stacktrace is provided
      lineLength: 120,
      // Width of the output
      colors: true,
      // Colorful log messages
      printEmojis: true,
      // Print an emoji for each log message
      printTime: true, // Include timestamp in logs
    ),
  );

  // Log messages at different levels using the convenient shorthand methods
  logger.d('This is a debug message');
  logger.i('Application started');
  logger.w('Something might be wrong');

  try {
    // Simulate an error
    throw Exception('Something went wrong');
  } catch (e, stackTrace) {
    // Log the error with stack trace
    logger.e('Oops😳 an error occurred', e, stackTrace, {
      'sessionId': '9999990-09099439-2983727328',
    });
  }
}
