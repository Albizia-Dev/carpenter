import 'dart:io';

const _sourceDirectory = 'assets/icons/gravity';
const _outputFile = 'lib/src/components/basic/gravity_icons.g.dart';

const _reservedWords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

void main() {
  final directory = Directory(_sourceDirectory);
  if (!directory.existsSync()) {
    stderr.writeln('Missing $_sourceDirectory');
    exitCode = 1;
    return;
  }

  final names = directory
      .listSync(followLinks: false)
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('.svg'))
      .map((name) => name.substring(0, name.length - 4))
      .toList()
    ..sort();

  final identifiers = <String, String>{};
  for (final name in names) {
    final identifier = _identifier(name);
    final previous = identifiers[identifier];
    if (previous != null) {
      stderr.writeln(
        'Gravity icon identifier collision: $previous and $name -> $identifier',
      );
      exitCode = 1;
      return;
    }
    identifiers[identifier] = name;
  }

  final output = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/generate_gravity_icons.dart')
    ..writeln()
    ..writeln("import 'gravity_icon.dart';")
    ..writeln()
    ..writeln('/// Bundled Gravity UI icon catalog.')
    ..writeln('abstract final class GravityIcons {');

  for (final entry in identifiers.entries) {
    output
      ..writeln('  /// `${entry.value}.svg`.')
      ..writeln(
        "  static const ${entry.key} = GravityIconData('${entry.value}');",
      );
  }

  output
    ..writeln()
    ..writeln('  /// Every bundled Gravity icon, sorted by asset name.')
    ..writeln('  static const values = <GravityIconData>[');

  for (final identifier in identifiers.keys) {
    output.writeln('    $identifier,');
  }

  output
    ..writeln('  ];')
    ..writeln('}');

  final file = File(_outputFile);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(output.toString());
  stdout.writeln('Generated ${names.length} Gravity icons -> $_outputFile');
}

String _identifier(String name) {
  final parts = name.split('-').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Icon name must not be empty');
  }

  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    buffer
      ..write(part[0].toUpperCase())
      ..write(part.substring(1));
  }

  var identifier = buffer.toString();
  if (RegExp(r'^\d').hasMatch(identifier)) {
    identifier = 'icon$identifier';
  }
  if (_reservedWords.contains(identifier)) {
    identifier = '${identifier}Icon';
  }
  return identifier;
}
