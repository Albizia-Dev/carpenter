import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Finds constructor/call references reachable through catalog source imports.
///
/// This is source-example coverage, not proof that a widget renders in every
/// state. Runtime registry tests separately verify live catalog registration.
Map<String, Object?> collectWidgetbook(String root, Iterable<String> widgets) {
  final expected = widgets.toSet();
  final references = <String, Set<String>>{};
  final visited = <String>{};
  final library = p.join(root, 'widgetbook', 'lib');
  void visit(String path) {
    path = p.normalize(path);
    if (!p.isWithin(library, path)) {
      throw StateError('Widgetbook import escapes lib: $path');
    }
    if (!visited.add(path)) return;
    final file = File(path);
    if (!file.existsSync()) throw StateError('Missing catalog source: $path');
    final unit = parseString(content: file.readAsStringSync(), path: path).unit;
    final visitor = _Calls(expected);
    unit.accept(visitor);
    for (final name in visitor.names) {
      references
          .putIfAbsent(name, () => {})
          .add(p.relative(path, from: root).replaceAll('\\', '/'));
    }
    for (final directive in unit.directives) {
      if (directive is! UriBasedDirective) continue;
      if (directive is! ImportDirective &&
          directive is! ExportDirective &&
          directive is! PartDirective)
        continue;
      final uri = directive.uri.stringValue;
      if (uri == null) continue;
      if (uri.startsWith('package:carpenter_widgetbook/')) {
        visit(
          p.join(
            library,
            uri.substring('package:carpenter_widgetbook/'.length),
          ),
        );
      } else if (!Uri.parse(uri).hasScheme) {
        visit(p.join(p.dirname(path), uri));
      }
    }
  }

  visit(p.join(library, 'catalog.dart'));
  final missing = expected.difference(references.keys.toSet()).toList()..sort();
  return {
    'schemaVersion': 1,
    'measurement': 'constructor references in catalog source dependency graph',
    'publicWidgets': expected.length,
    'referencedWidgets': references.length,
    'unreferencedWidgets': missing,
    'references': {
      for (final name in references.keys.toList()..sort())
        name: references[name]!.toList()..sort(),
    },
  };
}

final class _Calls extends RecursiveAstVisitor<void> {
  _Calls(this.expected);
  final Set<String> expected;
  final Set<String> names = {};
  void add(String name) {
    if (expected.contains(name)) names.add(name);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Without resolution, `const Widget.named()` may be parsed as a
    // prefixed type. Inspect type-name segments, never generic arguments.
    for (final name
        in node.constructorName.type.toSource().split('<').first.split('.')) {
      add(name);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    add(node.methodName.name);
    final target = node.target;
    if (target is SimpleIdentifier) add(target.name);
    super.visitMethodInvocation(node);
  }
}

/// A named, reviewable debt inventory; never a percentage threshold.
Map<String, Object?> debtSnapshot(
  Map<String, Object?> api,
  Map<String, Object?> widgetbook,
) {
  final symbols = (api['symbols'] as List).cast<Map<String, Object?>>();
  return {
    'schemaVersion': 1,
    'description':
        'Known incomplete documentation. New or changed undocumented API and newly unreferenced widgets fail CI. --strict still fails until all debt is removed.',
    'undocumented': {
      for (final symbol in symbols)
        if (symbol['generated'] == false && symbol['documented'] == false)
          symbol['id'] as String: sha256
              .convert(
                utf8.encode(
                  (symbol['signature'] as String)
                      .replaceAll(RegExp(r'\s+'), ' ')
                      .trim(),
                ),
              )
              .toString(),
    },
    'unreferencedWidgets': widgetbook['unreferencedWidgets'],
    'generatedFiles':
        symbols
            .where((s) => s['generated'] == true)
            .map((s) => s['file'] as String)
            .toSet()
            .toList()
          ..sort(),
  };
}

/// Requires the baseline to shrink with improvements, not just avoid growth.
List<String> compareDebt(
  Map<String, dynamic> baseline,
  Map<String, Object?> current,
) {
  if (baseline['schemaVersion'] != 1) return ['Unsupported baseline schema'];
  final errors = <String>[];
  final before = Map<String, String>.from(baseline['undocumented'] as Map);
  final after = Map<String, String>.from(current['undocumented'] as Map);
  for (final entry in after.entries) {
    if (before[entry.key] != entry.value) {
      errors.add('New or changed undocumented API: ${entry.key}');
    }
  }
  for (final key in before.keys.where((key) => !after.containsKey(key))) {
    errors.add('Resolved/stale documentation debt: $key (update the baseline)');
  }
  for (final field in ['unreferencedWidgets', 'generatedFiles']) {
    final old = Set<String>.from(baseline[field] as List);
    final next = Set<String>.from(current[field] as List);
    for (final value in next.difference(old)) {
      errors.add('New $field entry: $value');
    }
    for (final value in old.difference(next)) {
      errors.add('Resolved/stale $field entry: $value (update the baseline)');
    }
  }
  return errors;
}
