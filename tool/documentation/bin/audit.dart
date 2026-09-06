import 'dart:convert';
import 'dart:io';

import 'package:carpenter_documentation_tools/coverage.dart';
import 'package:carpenter_documentation_tools/inventory.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final positional = args.where((arg) => !arg.startsWith('--')).toList();
  final flags = args.where((arg) => arg.startsWith('--')).toSet();
  if (positional.length > 1 ||
      flags.difference({
        '--check',
        '--strict',
        '--write-baseline',
      }).isNotEmpty ||
      flags.contains('--check') && flags.contains('--write-baseline')) {
    stderr.writeln(
      'Usage: dart run bin/audit.dart [root] [--check|--strict|--write-baseline]',
    );
    exitCode = 64;
    return;
  }
  final root = p.normalize(
    p.absolute(positional.isEmpty ? '../..' : positional.single),
  );
  try {
    final api = ApiInventory(root).collect();
    final widgetbook = collectWidgetbook(
      root,
      (api['publicWidgets'] as List).cast<String>(),
    );
    final debt = debtSnapshot(api, widgetbook);
    const encoder = JsonEncoder.withIndent('  ');
    void write(String path, Object? content) {
      final file = File(p.join(root, path));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${encoder.convert(content)}\n');
    }

    write('build/documentation/api.json', api);
    write('build/documentation/widgetbook.json', widgetbook);
    final summary = api['summary'] as Map<String, int>;
    final report = StringBuffer('# Documentation coverage\n\n')
      ..writeln(
        'This report counts declarations and constructor references, not documentation quality, runtime behavior, accessibility, or visual correctness.\n',
      )
      ..writeln('| Metric | Count |')
      ..writeln('| --- | ---: |')
      ..writeln('| Owned public declarations | ${summary['ownedSymbols']} |')
      ..writeln('| With nonempty DartDoc | ${summary['documentedSymbols']} |')
      ..writeln('| Missing DartDoc | ${summary['undocumentedSymbols']} |')
      ..writeln(
        '| Generated declarations (separate) | ${summary['generatedSymbols']} |',
      )
      ..writeln('| Public concrete widgets | ${widgetbook['publicWidgets']} |')
      ..writeln(
        '| Referenced by catalog source | ${widgetbook['referencedWidgets']} |',
      )
      ..writeln(
        '\n## Public widgets without catalog-source constructor references\n',
      );
    for (final name in widgetbook['unreferencedWidgets'] as List) {
      report.writeln('- `$name`');
    }
    report.writeln(
      '\nScope and host widgets are included in the inventory. An absent standalone story is not automatically a visual defect. Classify remaining entries during review; do not hide them behind an aggregate percentage.',
    );
    File(
      p.join(root, 'build/documentation/coverage.md'),
    ).writeAsStringSync(report.toString());
    stdout.writeln(jsonEncode(summary));
    stdout.writeln(
      'Widgetbook source references: ${widgetbook['referencedWidgets']}/${widgetbook['publicWidgets']}',
    );
    final baselinePath = 'tool/documentation/coverage-baseline.json';
    if (flags.contains('--write-baseline')) {
      write(baselinePath, debt);
      stdout.writeln(
        'Updated $baselinePath. Review the diff; do not use this option in normal CI.',
      );
    }
    if (flags.contains('--check')) {
      final baseline =
          jsonDecode(File(p.join(root, baselinePath)).readAsStringSync())
              as Map<String, dynamic>;
      final errors = compareDebt(baseline, debt);
      if (errors.isNotEmpty) {
        for (final error in errors.take(30)) {
          stderr.writeln(error);
        }
        stderr.writeln(
          '${errors.length} coverage changes require review. See build/documentation/.',
        );
        exitCode = 1;
      }
    }
    if (flags.contains('--strict') &&
        (summary['undocumentedSymbols']! > 0 ||
            (widgetbook['unreferencedWidgets'] as List).isNotEmpty)) {
      stderr.writeln(
        'Full coverage is not complete. A passing baseline check is not full coverage.',
      );
      exitCode = 1;
    }
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exitCode = 1;
  }
}
