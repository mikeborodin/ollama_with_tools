import 'package:dart_console/dart_console.dart';

extension Color on Console {
  void writeGreen(String value) {
    setForegroundColor(ConsoleColor.green);
    writeLine(value);
    resetColorAttributes();
  }

  void writeYellow(String value) {
    setForegroundColor(ConsoleColor.yellow);
    writeLine(value);
    resetColorAttributes();
  }
}
