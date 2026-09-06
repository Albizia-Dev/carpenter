import 'dart:io';

import 'package:carpenter_documentation_tools/inventory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('carpenter_api_'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String content) {
    final file = File(p.join(root.path, 'lib', path));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  Map<String, Object?> collect() => ApiInventory(root.path).collect();
  List<Map<String, Object?>> symbols() =>
      (collect()['symbols'] as List).cast<Map<String, Object?>>();
  Set<String> names() => symbols().map((s) => s['name'] as String).toSet();

  test('collects explicit public members with documentation and metadata', () {
    write('carpenter.dart', '''
/// A documented model.
@deprecated
class Model {
  /// Constructs a model.
  const Model();
  Model._();
  /// Stored value.
  final int value = 1;
  int _hidden = 0;
  /// Reads the value.
  int get current => value;
  /// Assigns the value.
  set current(int value) {}
  /// Performs an operation.
  void run() {}
  void _helper() {}
}
''');
    expect(names(), {
      'Model',
      'Model.new',
      'Model.value',
      'Model.current',
      'Model.run',
    });
    expect(symbols().every((s) => s['documented'] == true), isTrue);
    expect(symbols().where((s) => s['name'] == 'Model.current').length, 2);
    expect(
      symbols().firstWhere((s) => s['name'] == 'Model')['signature'],
      'class Model',
    );
  });

  test('follows exports but not unrelated imports', () {
    write(
      'carpenter.dart',
      "import 'private.dart'; export 'a.dart' show Kept;",
    );
    write('private.dart', 'class ImportedOnly {}');
    write('a.dart', "export 'b.dart' hide Hidden; class Other {}");
    write('b.dart', 'class Kept {} class Hidden {}');
    expect(names(), {'Kept'});
  });

  test('terminates export cycles and deduplicates repeated paths', () {
    write('carpenter.dart', "export 'a.dart'; export './a.dart';");
    write('a.dart', "export 'b.dart'; class A {}");
    write('b.dart', "export 'a.dart'; class B {}");
    expect(names(), {'A', 'B'});
    expect(symbols().length, 2);
  });

  test('parts belong to their library and respect its export combinators', () {
    write('carpenter.dart', "export 'a.dart' show PartModel;");
    write('a.dart', "part 'a_part.dart'; class Other {}");
    write('a_part.dart', "part of 'a.dart'; class PartModel { void run() {} }");
    expect(names(), {'PartModel', 'PartModel.run'});
    expect(symbols().every((s) => s['file'] == 'lib/a_part.dart'), isTrue);
  });

  test('external re-exports are not counted as authored documentation', () {
    write(
      'carpenter.dart',
      "export 'package:carpenter_units/carpenter_units.dart'; export 'dart:async';",
    );
    expect(symbols(), isEmpty);
    expect(collect()['externalExports'], [
      'dart:async',
      'package:carpenter_units/carpenter_units.dart',
    ]);
  });

  test('local package URIs resolve from lib', () {
    write('carpenter.dart', "export 'package:carpenter/src/model.dart';");
    write('src/model.dart', 'class Model {}');
    expect(names(), {'Model'});
  });

  test('generated declarations have a separate denominator', () {
    write('carpenter.dart', "export 'tokens.g.dart'; class Manual {}");
    write('tokens.g.dart', 'class Tokens { static const value = 1; }');
    expect(collect()['summary'], {
      'ownedSymbols': 1,
      'documentedSymbols': 0,
      'undocumentedSymbols': 1,
      'generatedSymbols': 2,
      'publicWidgets': 0,
    });
  });

  test('private declarations and their public members do not leak', () {
    write(
      'carpenter.dart',
      'class _Private { void publicMember() {} } void _top() {}',
    );
    expect(symbols(), isEmpty);
  });

  test('visits enums, extensions, typedefs and every variable declaration', () {
    write('carpenter.dart', '''
enum Mode { first, second; int get rank => index; }
extension Label on String { String get label => this; }
typedef Builder = String Function(int value);
const one = 1, two = 2;
''');
    expect(names(), {
      'Mode',
      'Mode.first',
      'Mode.second',
      'Mode.rank',
      'Label',
      'Label.label',
      'Builder',
      'one',
      'two',
    });
  });

  test('conditional exports conservatively include both implementations', () {
    write('carpenter.dart', "export 'a.dart' if (dart.library.io) 'b.dart';");
    write('a.dart', 'class BrowserOnly {}');
    write('b.dart', 'class NativeOnly {}');
    expect(names(), {'BrowserOnly', 'NativeOnly'});
  });

  test('only concrete public widget classes enter the visual denominator', () {
    write('carpenter.dart', '''
abstract class Base extends StatelessWidget {}
class Concrete extends Base {}
class Direct extends StatefulWidget {}
class _Private extends StatelessWidget {}
class Descriptor {}
''');
    expect(collect()['publicWidgets'], ['Concrete', 'Direct']);
  });

  test('a normal comment does not count as DartDoc', () {
    write('carpenter.dart', '// Not documentation.\nclass Model {}');
    expect(symbols().single['documented'], isFalse);
  });

  test('malformed source and missing exports fail closed', () {
    write('carpenter.dart', 'class {');
    expect(collect, throwsA(anything));
    write('carpenter.dart', "export 'missing.dart';");
    expect(collect, throwsStateError);
  });

  test('exports cannot leave the package library', () {
    write('carpenter.dart', "export '../outside.dart';");
    expect(collect, throwsStateError);
  });

  test('repeated collection is deterministic', () {
    write('carpenter.dart', 'class Z {} class A {}');
    final inventory = ApiInventory(root.path);
    expect(inventory.collect(), inventory.collect());
    expect(names(), {'A', 'Z'});
  });
  test('top-level getter and setter are independently documented', () {
    write('carpenter.dart', "export 'accessors.dart' show value;");
    write('accessors.dart', 'int get value => 1; set value(int next) {}');
    expect(symbols().map((s) => s['kind']), containsAll(['getter', 'setter']));
    expect(symbols(), hasLength(2));
  });

  test('conditional same-named implementations are both inventoried', () {
    write('carpenter.dart', "export 'a.dart' if (dart.library.io) 'b.dart';");
    write('a.dart', 'class Model {}');
    write('b.dart', 'class Model {}');
    expect(symbols(), hasLength(2));
    expect(
      symbols().map((s) => s['file']),
      containsAll(['lib/a.dart', 'lib/b.dart']),
    );
  });

  test('a public widget may derive from a private implementation base', () {
    write(
      'carpenter.dart',
      'class _Base extends StatelessWidget {} class Public extends _Base {}',
    );
    expect(collect()['publicWidgets'], ['Public']);
  });

  test('package URIs cannot escape lib either', () {
    write('carpenter.dart', "export 'package:carpenter/../outside.dart';");
    expect(collect, throwsStateError);
  });
}
