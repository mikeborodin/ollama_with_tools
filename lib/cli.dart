import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:ollama_dart/ollama_dart.dart';
import 'package:ollama_tools/logger.dart';
import 'package:ollama_tools/request.dart';

import 'create_request.dart';
import 'state.dart';

StreamSubscription? requestSub;
StreamSubscription? stdInSub;

Future<void> main(List<String> args) async {
  final console = Console();
  final ollamaClient = OllamaClient();
  console.rawMode = false;
  console.writeLine('');
  console.clearScreen();
  console.resetCursorPosition();

  console.writeLine('Welcome to Ollama CLI, type your message:');

  final parser = ArgParser()..addFlag('json', abbr: 'j', defaultsTo: false);

  final argResults = parser.parse(args);
  final answerJson = argResults.flag('json');

  final state = State(
    messages: [],
    input: '',
    toolsEnabled: true,
    answerJson: answerJson,
  );

  final requestQueue = StreamController<GenerateChatCompletionRequest>();

  requestSub = executeRequests(
    requestQueue,
    state,
    ollamaClient,
    console,
  ).listen((event) {});

  queueInput(
    argResults.arguments.lastOrNull,
    console,
    state,
    ollamaClient,
    requestQueue,
  );
}

void queueInput(
  String? initialInput,
  Console console,
  State state,
  OllamaClient ollamaClient,
  StreamController<GenerateChatCompletionRequest> requestQueue,
) {
  if (initialInput != null) {
    console.writeYellow(initialInput);
    state.messages.add(Message(
      role: MessageRole.user,
      content: initialInput,
    ));
    requestQueue.add(createRequest(state));
  }

  stdInSub = stdin.listen((line) {
    final string = utf8.decode(line).substring(0, line.length - 1);

    if (string == 'tt') {
      state.toolsEnabled = !state.toolsEnabled;
      console.writeYellow('tools status:${state.toolsEnabled}');
    } else if (string == 'd') {
      state.messages.removeLast();
      console.writeYellow('Removed last ❌');
    } else if (string == 'dd') {
      state.messages.clear();
      console.clearScreen();
      console.writeYellow('Cleared messages ❌');
    } else {
      console.writeYellow('sending "$string"');
      state.messages.add(Message(
        role: MessageRole.user,
        content: string,
      ));
      requestQueue.add(createRequest(state));
    }
  });
}

Stream<void> executeRequests(
  StreamController<GenerateChatCompletionRequest> requests,
  State state,
  OllamaClient ollamaClient,
  Console console,
) async* {
  await for (final request in requests.stream) {
    // console.writeLine('User: ${request.messages.lastOrNull?.content}');

    if (state.toolsEnabled) {
      console.writeLine('Model (with tools):');
    } else {
      console.writeLine('Model :');
    }
    final response = await ollamaClient.generateChatCompletion(request: request);

    final responseMessage = response.message;

    for (final line in responseMessage.content.split('\n')) {
      console.writeGreen(line);
    }

    if (responseMessage.toolCalls != null && responseMessage.toolCalls!.isNotEmpty) {
      final List<Message> pendingMessagesFromTools = [];

      for (final tool in responseMessage.toolCalls!) {
        final name = tool.function?.name;

        if (name == TOOL_LIST_FILES) {
          final out = await getDirectoryStructure();
          pendingMessagesFromTools.add(
            Message(
              role: MessageRole.tool,
              content: out,
            ),
          );

          console.writeYellow('Tool result from $name ${tool.function?.arguments} $out');
        }
        if (name == TOOL_CURRENT_READ) {
          final path = tool.function?.arguments['path']!;
          if (path == null) continue;

          final out = await getFileFromPath(path!);
          console.writeYellow('Tool result from $name ${tool.function?.arguments}');
          for (final line in out.split('\n')) {
            console.writeYellow(line);
          }

          pendingMessagesFromTools.add(
            Message(
              role: MessageRole.tool,
              content: out,
            ),
          );
        }
        if (name == TOOL_WRITE) {
          final path = tool.function?.arguments['path']!;
          final data = tool.function?.arguments['data']!;
          if (path == null) continue;
          if (data == null) continue;

          final out = await writeToFile(path!, data!);

          console.writeYellow('Tool result from $name ${tool.function?.arguments} $out');

          pendingMessagesFromTools.add(
            Message(
              role: MessageRole.tool,
              content: out,
            ),
          );
        }
        if (name == TOOL_BASH) {
          final command = tool.function?.arguments['command']!;
          if (command == null) continue;

          final out = await runBash(command!);

          console.writeYellow('Tool result from $name ${tool.function?.arguments}\n$out');

          pendingMessagesFromTools.add(
            Message(
              role: MessageRole.tool,
              content: out,
            ),
          );
        }
      }
      state.messages.addAll(pendingMessagesFromTools);

      requests.add(createRequest(state));
    }
  }
}
