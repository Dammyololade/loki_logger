import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:loki_logger/src/loki_config.dart';

class LokiClient {

  /// Configuration for the logger to connect to Loki Server
  final LokiConfig config;

  /// Queue of log entries waiting to be sent
  final List<Map<String, dynamic>> _queue = [];

  /// Timer for batch sending
  Timer? _batchTimer;

  LokiClient({required this.config} ){
    if (config.batching) {
      _batchTimer = Timer.periodic(
        Duration(seconds: config.interval),
            (_) => _sendBatch(),
      );
    }
  }

  /// Logs a message to Loki
  ///
  /// [level] is the log level (info, warn, error, etc.)
  /// [message] is the log message
  /// [error] is an optional error object
  /// [stackTrace] is an optional stack trace
  /// [time] is an optional timestamp (current time used if not provided)
  /// [loggerName] is an optional logger name
  /// [customLabels] allows adding custom labels to this specific log
  void log({
    required String level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
    String? loggerName,
    Map<String, String>? customLabels,
  }) {
    final timestamp =
    config.replaceTimestamp ? DateTime.now() : (time ?? DateTime.now());
    final nanoseconds = timestamp.microsecondsSinceEpoch * 1000;

    // Combine message with error and stack trace if present
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStack Trace: $stackTrace';
    }

    // Prepare log entry
    final entry = {
      'timestamp': nanoseconds.toString(),
      'message': fullMessage,
      'labels': _prepareLabels(level, loggerName, customLabels),
    };

    if (config.batching) {
      _queue.add(entry);
    } else {
      _sendLogs([entry]);
    }
  }

  /// Prepares the labels for a log entry
  String _prepareLabels(
      String level,
      String? loggerName,
      Map<String, String>? customLabels,
      ) {
    final allLabels = <String, String>{'level': level};

    // Add logger name if provided
    if (loggerName != null) {
      allLabels['logger'] = loggerName;
    }

    // Add global labels
    if (config.labels != null) {
      allLabels.addAll(config.labels!);
    }

    // Add custom labels for this log
    if (customLabels != null) {
      allLabels.addAll(customLabels);
    }

    // Format labels as Loki expects: {key="value",key2="value2"}
    final formattedLabels = allLabels.entries
        .map((e) => '${e.key}="${e.value}"')
        .join(',');

    return '{$formattedLabels}';
  }

  /// Sends a batch of logs to Loki
  Future<void> _sendBatch() async {
    if (_queue.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();

    await _sendLogs(batch);
  }

  /// Sends logs to Loki server
  Future<void> _sendLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;
    final http.Response response;

    try {
      // Prepare streams for Loki API
      final streams = logs.fold<Map<String, List<List<String>>>>({}, (
          map,
          log,
          ) {
        final labels = log['labels'] as String;
        final entry = <String>[log['timestamp'], log['message']];

        if (!map.containsKey(labels)) {
          map[labels] = [];
        }
        map[labels]!.add(entry);
        return map;
      });

      // Format for Loki API
      final streamsData =
      streams.entries.map((entry) {
        // Parse the label string into a proper Map
        final labelStr = entry.key.substring(
          1,
          entry.key.length - 1,
        ); // Remove the surrounding braces
        final labelPairs = labelStr.split(',');
        final labelMap = <String, String>{};

        for (final pair in labelPairs) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            // Extract key and value, removing quotes
            final key = parts[0].trim();
            final value = parts[1].trim();
            // Remove surrounding quotes from value
            final cleanValue =
            value.startsWith('"') && value.endsWith('"')
                ? value.substring(1, value.length - 1)
                : value;
            labelMap[key] = cleanValue;
          }
        }

        return {'stream': labelMap, 'values': entry.value};
      }).toList();

      final payload = {'streams': streamsData};

      // Prepare request
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (config.basicAuth != null) {
        final encodedAuth = base64Encode(utf8.encode(config.basicAuth!));
        headers['Authorization'] = 'Basic $encodedAuth';
      }

      // Send to Loki
      final uri = Uri.parse('${config.host}/loki/api/v1/push');
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(milliseconds: config.timeout ?? 30000));
    } catch (e) {
      // If not clearing on error, add logs back to queue
      if (!config.clearOnError && config.batching) {
        _queue.addAll(logs);
      }
      rethrow;
    }

    if (response.statusCode >= 400) {
      throw Exception(
        'LokiLogger: Error sending logs: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Disposes resources used by this logger
  void dispose() {
    _batchTimer?.cancel();
    _sendBatch(); // Send any remaining logs
  }
}
