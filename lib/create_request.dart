// ignore_for_file: constant_identifier_names

import 'package:ollama_dart/ollama_dart.dart';
import 'package:ollama_tools/state.dart';

const TOOL_LIST_FILES = 'list_files';
const TOOL_CURRENT_READ = 'read_file';
const TOOL_WRITE = 'write_file';
const TOOL_BASH = 'evaluate_bash';

GenerateChatCompletionRequest createRequest(State state) {
  var tools = [
    Tool(
      type: ToolType.function,
      function: ToolFunction(
        name: TOOL_LIST_FILES,
        description: 'List files',
        parameters: {},
      ),
    ),
    Tool(
      type: ToolType.function,
      function: ToolFunction(
        name: TOOL_CURRENT_READ,
        description: 'Read contents of a file',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'relative file path to the file (can be taken from current directory list)',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      type: ToolType.function,
      function: ToolFunction(
        name: TOOL_WRITE,
        description: 'Write data to a file',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Relative file path',
            },
            'data': {
              'type': 'string',
              'description': 'Data to be stored',
            },
          },
          'required': ['path', 'content'],
        },
      ),
    ),
    Tool(
      type: ToolType.function,
      function: ToolFunction(
        name: TOOL_BASH,
        description: 'Evaluate bash command',
        parameters: {
          'type': 'object',
          'properties': {
            'command': {
              'type': 'string',
              'description': 'Bash command',
            },
          },
          'required': ['command'],
        },
      ),
    )
  ];
  return GenerateChatCompletionRequest(
    model: String.fromEnvironment('MODEL', defaultValue: 'llama3.1'),
    tools: state.toolsEnabled ? tools : null,
    messages: state.messages,
    format: state.answerJson ? ResponseFormat.json : null,
  );
}
