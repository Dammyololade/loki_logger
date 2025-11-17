import 'dart:io';

import 'package:loki_logger/src/log_output.dart';

/// Outputs logs to a file
///
/// Example usage:
/// ```dart
/// final logger = LokiLogger(
///   output: FileLogOutput('/path/to/logs/app.log'),
///   printer: PrettyPrinter(),
/// );
/// logger.i('This will be written to the file');
/// ```
///
/// TODO: Add file rotation support (max file size, rotation count)
/// TODO: Implement async buffered writes for better performance
/// TODO: Add proper error handling and retry logic
/// TODO: Implement dispose() method to close file handle and flush buffers
/// TODO: Add file path validation and directory creation
class FileLogOutput extends LogOutput {
  final String filePath;
  // TODO: Add file handle management and proper resource cleanup
  IOSink? _sink;

  FileLogOutput(this.filePath) {
    // TODO: Validate file path and create parent directories if needed
    // TODO: Initialize file handle with proper error handling
    try {
      final file = File(filePath);
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      // TODO: Proper error handling - should we throw or log silently?
      // For now, just print to console as fallback
      // ignore: avoid_print
      print('FileLogOutput: Failed to open file $filePath: $e');
    }
  }

  @override
  void output(List<String> lines) {
    // TODO: Add buffering mechanism for better performance
    // TODO: Handle write errors gracefully
    if (_sink == null) {
      // Fallback to console if file couldn't be opened
      for (final line in lines) {
        // ignore: avoid_print
        print(line);
      }
      return;
    }

    try {
      for (final line in lines) {
        _sink!.writeln(line);
      }
      // TODO: Implement periodic flush instead of flushing on every write
      _sink!.flush();
    } catch (e) {
      // TODO: Implement retry logic or error recovery
      // ignore: avoid_print
      print('FileLogOutput: Error writing to file: $e');
    }
  }

  // TODO: Add dispose() method to properly close file handle
  // void dispose() {
  //   _sink?.flush();
  //   _sink?.close();
  //   _sink = null;
  // }
}

