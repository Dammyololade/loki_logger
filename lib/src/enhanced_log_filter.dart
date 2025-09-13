import 'package:loki_logger/src/log_event.dart';
import 'package:loki_logger/src/log_level.dart';
import 'package:loki_logger/src/log_filter.dart';

/// Enhanced filter that combines multiple filtering criteria
class EnhancedLogFilter extends LogFilter {
  final Level? minLevel;
  final Level? maxLevel;
  final Duration? timeWindow;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? allowedLoggerNames;
  final List<String>? blockedLoggerNames;
  final RegExp? messagePattern;
  final Map<String, String>? requiredLabels;
  final List<String>? excludePatterns;
  final int? maxMessageLength;
  final bool includeErrors;
  final bool includeStackTraces;

  EnhancedLogFilter({
    this.minLevel,
    this.maxLevel,
    this.timeWindow,
    this.startTime,
    this.endTime,
    this.allowedLoggerNames,
    this.blockedLoggerNames,
    this.messagePattern,
    this.requiredLabels,
    this.excludePatterns,
    this.maxMessageLength,
    this.includeErrors = true,
    this.includeStackTraces = true,
  });

  @override
  bool shouldLog(LogEvent event) {
    // Level filtering
    if (minLevel != null && event.level < minLevel!) {
      return false;
    }
    
    if (maxLevel != null && event.level > maxLevel!) {
      return false;
    }

    // Time-based filtering
    if (!_passesTimeFilter(event.time)) {
      return false;
    }

    // Logger name filtering
    if (!_passesLoggerNameFilter(event.loggerName)) {
      return false;
    }

    // Message pattern filtering
    if (!_passesMessageFilter(event.message)) {
      return false;
    }

    // Custom labels filtering
    if (!_passesLabelFilter(event.customLabels)) {
      return false;
    }

    // Error and stack trace filtering
    if (!_passesErrorFilter(event)) {
      return false;
    }

    // Message length filtering
    if (!_passesLengthFilter(event.message)) {
      return false;
    }

    return true;
  }

  bool _passesTimeFilter(DateTime eventTime) {
    if (startTime != null && eventTime.isBefore(startTime!)) {
      return false;
    }
    
    if (endTime != null && eventTime.isAfter(endTime!)) {
      return false;
    }
    
    if (timeWindow != null) {
      final now = DateTime.now();
      final windowStart = now.subtract(timeWindow!);
      if (eventTime.isBefore(windowStart)) {
        return false;
      }
    }
    
    return true;
  }

  bool _passesLoggerNameFilter(String? loggerName) {
    if (allowedLoggerNames != null && allowedLoggerNames!.isNotEmpty) {
      if (loggerName == null || !allowedLoggerNames!.contains(loggerName)) {
        return false;
      }
    }
    
    if (blockedLoggerNames != null && loggerName != null) {
      if (blockedLoggerNames!.contains(loggerName)) {
        return false;
      }
    }
    
    return true;
  }

  bool _passesMessageFilter(String message) {
    if (messagePattern != null && !messagePattern!.hasMatch(message)) {
      return false;
    }
    
    if (excludePatterns != null) {
      for (final pattern in excludePatterns!) {
        if (message.toLowerCase().contains(pattern.toLowerCase())) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool _passesLabelFilter(Map<String, String>? labels) {
    if (requiredLabels != null && requiredLabels!.isNotEmpty) {
      if (labels == null) {
        return false;
      }
      
      for (final entry in requiredLabels!.entries) {
        if (!labels.containsKey(entry.key) || labels[entry.key] != entry.value) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool _passesErrorFilter(LogEvent event) {
    if (!includeErrors && event.error != null) {
      return false;
    }
    
    if (!includeStackTraces && event.stackTrace != null) {
      return false;
    }
    
    return true;
  }

  bool _passesLengthFilter(String message) {
    if (maxMessageLength != null && message.length > maxMessageLength!) {
      return false;
    }
    
    return true;
  }

  /// Creates a filter for debugging purposes (info level and above)
  factory EnhancedLogFilter.debug() {
    return EnhancedLogFilter(
      minLevel: Level.debug,
      includeErrors: true,
      includeStackTraces: true,
    );
  }

  /// Creates a filter for production (warning level and above, no debug info)
  factory EnhancedLogFilter.production() {
    return EnhancedLogFilter(
      minLevel: Level.warning,
      includeErrors: true,
      includeStackTraces: false,
      excludePatterns: ['debug', 'trace'],
    );
  }

  /// Creates a filter for recent logs (last hour)
  factory EnhancedLogFilter.recent() {
    return EnhancedLogFilter(
      timeWindow: const Duration(hours: 1),
      minLevel: Level.info,
    );
  }

  /// Creates a filter for error logs only
  factory EnhancedLogFilter.errorsOnly() {
    return EnhancedLogFilter(
      minLevel: Level.error,
      includeErrors: true,
      includeStackTraces: true,
    );
  }
}

/// Composite filter that combines multiple filters with AND/OR logic
class CompositeLogFilter extends LogFilter {
  final List<LogFilter> filters;
  final bool useAndLogic;

  CompositeLogFilter(this.filters, {this.useAndLogic = true});

  @override
  bool shouldLog(LogEvent event) {
    if (filters.isEmpty) {
      return true;
    }

    if (useAndLogic) {
      // All filters must pass (AND logic)
      return filters.every((filter) => filter.shouldLog(event));
    } else {
      // At least one filter must pass (OR logic)
      return filters.any((filter) => filter.shouldLog(event));
    }
  }
}
