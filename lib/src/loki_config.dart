/// Configuration for [LokiLogger] to connect to Loki Server and send logs.
class LokiConfig {
  /// URL for Grafana Loki server
  final String host;

  /// The interval at which batched logs are sent in seconds
  final int interval;

  /// Whether to use batching for logs
  final bool batching;

  /// Whether to discard logs that result in an error during transport
  final bool clearOnError;

  /// Whether to replace log timestamps with current time
  final bool replaceTimestamp;

  /// Custom labels to attach to all logs
  final Map<String, String>? labels;

  /// Timeout for requests to Grafana Loki in milliseconds
  final int? timeout;

  /// Basic authentication credentials to access Loki over HTTP
  final String? basicAuth;

  const LokiConfig({
    required this.host,
    this.interval = 5,
    this.batching = true,
    this.clearOnError = false,
    this.replaceTimestamp = true,
    this.labels,
    this.timeout,
    this.basicAuth,
  });
}
