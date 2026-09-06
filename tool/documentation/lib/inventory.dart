import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:path/path.dart' as p;

/// Reads the package-owned namespace exposed by a Dart library.
///
/// Export combinators, transitive exports, export cycles and part files are
/// evaluated before declarations are counted. External package re-exports are
/// reported separately rather than being credited as Carpenter documentation.
final class ApiInventory {
  ApiInventory(this.root, {this.entrypoint = 'lib/carpenter.dart'});

  final String root;
  final String entrypoint;
  final Map<String, _Library> _libraries = {};
  final Set<String> externalExports = {};

  Map<String, Object?> collect() {
    _libraries.clear();
    externalExports.clear();
    final entry = p.normalize(p.join(root, entrypoint));
    _load(entry);
    final namespaces = <String, Map<String, Set<_Declaration>>>{
      for (final library in _libraries.values)
        library.path: {
          for (final item in library.declarations.entries)
            if (!item.key.startsWith('_')) item.key: {...item.value},
        },
    };
    // Union declarations until a fixed point. Count both sides of conditional
    // exports conservatively, including same-named implementations and paired
    // top-level accessors. Semantic export ambiguity remains an analyzer error.
    var changed = true;
    while (changed) {
      changed = false;
      for (final library in _libraries.values) {
        final target = namespaces[library.path]!;
        for (final edge in library.exports) {
          for (final item in namespaces[edge.path]!.entries) {
            if (!edge.accepts(item.key)) continue;
            final declarations = target.putIfAbsent(item.key, () => {});
            final previous = declarations.length;
            declarations.addAll(item.value);
            changed = changed || previous != declarations.length;
          }
        }
      }
    }
    final declarations =
        namespaces[entry]!.values.expand((set) => set).toSet().toList()..sort(
          (a, b) => '${a.path}:${a.name}'.compareTo('${b.path}:${b.name}'),
        );
    final symbols = <Map<String, Object?>>[];
    final widgets = <String>{};
    for (final declaration in declarations) {
      symbols.addAll(declaration.symbols(root));
      if (_isWidget(declaration, <String>{}) && !declaration.isAbstract) {
        widgets.add(declaration.name);
      }
    }
    symbols.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    final sortedWidgets = widgets.toList()..sort();
    final owned = symbols.where((s) => s['generated'] == false).toList();
    final missing = owned.where((s) => s['documented'] == false).toList();
    return {
      'schemaVersion': 1,
      'entrypoint': entrypoint,
      'summary': {
        'ownedSymbols': owned.length,
        'documentedSymbols': owned.length - missing.length,
        'undocumentedSymbols': missing.length,
        'generatedSymbols': symbols.length - owned.length,
        'publicWidgets': widgets.length,
      },
      'externalExports': externalExports.toList()..sort(),
      'publicWidgets': sortedWidgets,
      'symbols': symbols,
    };
  }

  void _load(String path) {
    if (_libraries.containsKey(path)) return;
    if (!File(path).existsSync())
      throw StateError('Missing exported file: $path');
    final library = _Library(path);
    _libraries[path] = library;
    _readUnit(library, path, <String>{});
    for (final edge in library.exports) {
      _load(edge.path);
    }
  }

  void _readUnit(_Library library, String path, Set<String> visited) {
    if (!visited.add(path)) return;
    final source = File(path).readAsStringSync();
    final result = parseString(content: source, path: path);
    for (final declaration in result.unit.declarations) {
      for (final name in _names(declaration)) {
        library.declarations
            .putIfAbsent(name, () => [])
            .add(_Declaration(name, path, source, declaration));
      }
    }
    for (final directive in result.unit.directives) {
      if (directive is ExportDirective) {
        final uris = [
          directive.uri.stringValue,
          ...directive.configurations.map((c) => c.uri.stringValue),
        ];
        for (final uri in uris.whereType<String>()) {
          final resolved = _resolve(path, uri);
          if (resolved == null) {
            externalExports.add(uri);
          } else {
            library.exports.add(_Export(resolved, directive.combinators));
          }
        }
      } else if (directive is PartDirective) {
        final uri = directive.uri.stringValue;
        final resolved = uri == null ? null : _resolve(path, uri);
        if (resolved == null) throw StateError('Unresolvable part in $path');
        _readUnit(library, resolved, visited);
      }
    }
  }

  String? _resolve(String from, String uri) {
    final parsed = Uri.parse(uri);
    if (parsed.hasScheme && !uri.startsWith('package:carpenter/')) return null;
    final resolved = uri.startsWith('package:carpenter/')
        ? p.normalize(
            p.join(root, 'lib', Uri.decodeComponent(uri.substring(18))),
          )
        : p.normalize(p.join(p.dirname(from), Uri.decodeComponent(uri)));
    if (!p.isWithin(p.join(root, 'lib'), resolved)) {
      throw StateError('Export escapes package lib: $from -> $uri');
    }
    return resolved;
  }

  bool _isWidget(_Declaration declaration, Set<String> visited) {
    if (!visited.add(declaration.name)) return false;
    final node = declaration.node;
    if (node is! ClassDeclaration || node.extendsClause == null) return false;
    final parent = node.extendsClause!.superclass.toSource().split('<').first;
    if (const {
      'Widget',
      'StatelessWidget',
      'StatefulWidget',
      'InheritedWidget',
      'InheritedNotifier',
      'InheritedModel',
      'ProxyWidget',
      'SingleChildRenderObjectWidget',
      'MultiChildRenderObjectWidget',
      'LeafRenderObjectWidget',
    }.contains(parent))
      return true;
    for (final library in _libraries.values) {
      for (final candidate
          in library.declarations[parent] ?? <_Declaration>[]) {
        if (_isWidget(candidate, {...visited})) return true;
      }
    }
    return false;
  }
}

Iterable<String> _names(CompilationUnitMember node) => switch (node) {
  ClassDeclaration() => [node.name.lexeme],
  EnumDeclaration() => [node.name.lexeme],
  MixinDeclaration() => [node.name.lexeme],
  ExtensionDeclaration() => [if (node.name != null) node.name!.lexeme],
  ExtensionTypeDeclaration() => [node.name.lexeme],
  ClassTypeAlias() => [node.name.lexeme],
  GenericTypeAlias() => [node.name.lexeme],
  FunctionTypeAlias() => [node.name.lexeme],
  FunctionDeclaration() => [node.name.lexeme],
  TopLevelVariableDeclaration() => node.variables.variables.map(
    (v) => v.name.lexeme,
  ),
  _ => throw UnsupportedError('Unsupported declaration: ${node.runtimeType}'),
};

final class _Library {
  _Library(this.path);
  final String path;
  final Map<String, List<_Declaration>> declarations = {};
  final List<_Export> exports = [];
}

final class _Export {
  _Export(this.path, this.combinators);
  final String path;
  final List<Combinator> combinators;
  bool accepts(String name) => combinators.every(
    (combinator) => switch (combinator) {
      ShowCombinator() => combinator.shownNames.any((n) => n.name == name),
      HideCombinator() => !combinator.hiddenNames.any((n) => n.name == name),
    },
  );
}

final class _Declaration {
  _Declaration(this.name, this.path, this.source, this.node);
  final String name;
  final String path;
  final String source;
  final CompilationUnitMember node;

  bool get isAbstract =>
      node is ClassDeclaration &&
      ((node as ClassDeclaration).abstractKeyword != null ||
          (node as ClassDeclaration).sealedKeyword != null);

  Iterable<Map<String, Object?>> symbols(String root) sync* {
    final kind = switch (node) {
      ClassDeclaration() => 'class',
      EnumDeclaration() => 'enum',
      MixinDeclaration() => 'mixin',
      ExtensionDeclaration() => 'extension',
      ExtensionTypeDeclaration() => 'extensionType',
      FunctionDeclaration n =>
        n.isGetter
            ? 'getter'
            : n.isSetter
            ? 'setter'
            : 'function',
      TopLevelVariableDeclaration() => 'variable',
      _ => 'typedef',
    };
    yield _symbol(root, node, name, kind);
    final members = switch (node) {
      ClassDeclaration n => n.members,
      EnumDeclaration n => n.members,
      MixinDeclaration n => n.members,
      ExtensionDeclaration n => n.members,
      ExtensionTypeDeclaration n => n.members,
      _ => <ClassMember>[],
    };
    if (node case EnumDeclaration n) {
      for (final constant in n.constants) {
        yield _symbol(
          root,
          constant,
          '$name.${constant.name.lexeme}',
          'enumValue',
        );
      }
    }
    for (final member in members) {
      if (member is ConstructorDeclaration) {
        final suffix = member.name?.lexeme ?? 'new';
        if (!suffix.startsWith('_')) {
          yield _symbol(root, member, '$name.$suffix', 'constructor');
        }
      } else if (member is MethodDeclaration) {
        if (!member.name.lexeme.startsWith('_')) {
          yield _symbol(
            root,
            member,
            '$name.${member.name.lexeme}',
            member.isGetter
                ? 'getter'
                : member.isSetter
                ? 'setter'
                : 'method',
          );
        }
      } else if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          if (!variable.name.lexeme.startsWith('_')) {
            yield _symbol(
              root,
              member,
              '$name.${variable.name.lexeme}',
              'field',
            );
          }
        }
      } else {
        throw UnsupportedError('Unsupported member: ${member.runtimeType}');
      }
    }
  }

  Map<String, Object?> _symbol(
    String root,
    AnnotatedNode declaration,
    String qualifiedName,
    String kind,
  ) {
    final file = p.relative(path, from: root).replaceAll('\\', '/');
    final doc = declaration.documentationComment?.tokens
        .map((t) => t.lexeme)
        .join('\n');
    final offset = declaration.firstTokenAfterCommentAndMetadata.offset;
    final end = switch (declaration) {
      MethodDeclaration n => n.body.offset,
      FunctionDeclaration n => n.functionExpression.body.offset,
      ConstructorDeclaration n => n.body.offset,
      ClassDeclaration n => n.leftBracket.offset,
      EnumDeclaration n => n.leftBracket.offset,
      MixinDeclaration n => n.leftBracket.offset,
      ExtensionDeclaration n => n.leftBracket.offset,
      _ => declaration.end,
    };
    return {
      'id': '$file::$kind:$qualifiedName',
      'name': qualifiedName,
      'kind': kind,
      'file': file,
      'line': '\n'.allMatches(source.substring(0, offset)).length + 1,
      'offset': declaration.beginToken.offset,
      'end': declaration.end,
      'signature': source.substring(offset, end).trim(),
      'documented':
          doc != null && doc.replaceAll(RegExp(r'[/\s*]'), '').isNotEmpty,
      'documentation': doc,
      'override': declaration.metadata.any((a) => a.name.name == 'override'),
      'generated':
          file.endsWith('.g.dart') || source.startsWith('// GENERATED CODE'),
    };
  }
}
