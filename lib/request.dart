// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';


Future<String> getDirectoryStructure() async {
  final out = await Process.run('fd', []);

  return out.stdout;
}

Future<String> runBash(String command) async {
  var indexOfFirstSpace = command.indexOf(' ');

  final bin = indexOfFirstSpace != -1 ? command.substring(0, indexOfFirstSpace) : command;
  final args = indexOfFirstSpace != -1 ? command.substring(indexOfFirstSpace + 1) : null;

  stdout.writeln('$bin+$args');
  try {
    final out = await Process.run(
      bin,
      args?.split(' ') ?? [],
    );
    final outError = out.stderr as String?;
    if (outError?.isNotEmpty == true) {
      return '[error]:\n ${outError}';
    } else {
      return out.stdout;
    }
  } catch (e) {
    return '[exception]: ${e.runtimeType} ${e.toString()}';
  }
}

Future<String> writeToFile(String path, String content) async {
  final file = File(path);
  try {
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    await file.writeAsString(content);
    return '[success]';
  } catch (e) {
    return '[error]: could not write the file';
  }
}

Future<String> getFileFromPath(String path) async {
  final out = await Process.run('cat', [path]);

  if (out.stderr != null && (out.stderr as String).contains('No such file or directory')) {
    return '[error]: file $path does not exist, you can try retrieving list of files.';
  }
  if (out.stderr != null) {
    return '[stderr]: ${out.stderr}';
  }
  return out.stdout;
}

