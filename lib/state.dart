import 'package:ollama_dart/ollama_dart.dart';

class State {
  List<Message> messages;
  String input;
  bool toolsEnabled;
  bool answerJson;

  State({
    required this.messages,
    required this.input,
    required this.toolsEnabled,
    required this.answerJson,
  });
}
