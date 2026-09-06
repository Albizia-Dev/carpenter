import 'dart:io';

import 'package:dart_style/dart_style.dart';

void main(List<String> args) {
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  for (final arg in args) {
    final entity = FileSystemEntity.typeSync(arg);
    final files = entity == FileSystemEntityType.directory
        ? Directory(arg)
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
        : <File>[File(arg)];
    for (final file in files) {
      final source = file.readAsStringSync();
      final formatted = formatter.format(source, uri: file.path);
      if (source != formatted) file.writeAsStringSync(formatted);
    }
  }
}
