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
class FileLogOutput extends LogOutput {
  final String filePath;
  IOSink? _sink;

  FileLogOutput(this.filePath) {
    try {
      final file = File(filePath);
      _sink = file.openWrite(mode: FileMode.append);
    } catch (e) {
      print('FileLogOutput: Failed to open file $filePath: $e');
    }
  }

  @override
  void output(List<String> lines) {
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
      _sink!.flush();
    } catch (e) {
      // ignore: avoid_print
      print('FileLogOutput: Error writing to file: $e');
    }
  }

  void dispose() {
    _sink?.flush();
    _sink?.close();
    _sink = null;
  }
}
