/// Interface for outputting log lines
abstract class LogOutput {
  void output(List<String> lines);
}

/// Outputs logs to the console
class ConsoleOutput extends LogOutput {
  @override
  void output(List<String> lines) {
    for (var line in lines) {
      // ignore: avoid_print
      print(line);
    }
  }
}
