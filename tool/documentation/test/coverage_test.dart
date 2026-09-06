import 'dart:io';

import 'package:carpenter_documentation_tools/coverage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  Map<String, Object?> debt({
    Map<String, String> docs = const {},
    List<String> widgets = const [],
    List<String> generated = const [],
  }) => {
    'schemaVersion': 1,
    'undocumented': docs,
    'unreferencedWidgets': widgets,
    'generatedFiles': generated,
  };
  test('unchanged named debt passes but new or modified API fails', () {
    final baseline = debt(docs: {'A': 'original'});
    expect(compareDebt(baseline, baseline), isEmpty);
    expect(compareDebt(baseline, debt(docs: {'A': 'changed'})), isNotEmpty);
    expect(
      compareDebt(baseline, debt(docs: {'A': 'original', 'B': 'new'})),
      isNotEmpty,
    );
  });
  test('improvements require ratcheting the debt inventory down', () {
    expect(compareDebt(debt(docs: {'A': 'old'}), debt()), hasLength(1));
  });
  test('new generated files and unreferenced widgets cannot pass silently', () {
    expect(compareDebt(debt(), debt(widgets: ['Widget'])), hasLength(1));
    expect(
      compareDebt(debt(), debt(generated: ['tokens.g.dart'])),
      hasLength(1),
    );
  });
  test('unsupported baseline schema fails closed', () {
    expect(compareDebt({...debt(), 'schemaVersion': 9}, debt()), isNotEmpty);
  });
  test(
    'signature whitespace is immaterial but API changes invalidate debt',
    () {
      Map<String, Object?> snapshot(String signature) => debtSnapshot(
        {
          'symbols': [
            {
              'id': 'A',
              'signature': signature,
              'generated': false,
              'documented': false,
            },
          ],
        },
        {'unreferencedWidgets': <String>[]},
      );
      expect(snapshot('void  run( )'), snapshot('void\n run( )'));
      expect(
        snapshot('void run(int a)'),
        isNot(snapshot('void run(String a)')),
      );
    },
  );
  test(
    'catalog references follow imports but ignore comments and type annotations',
    () {
      final root = Directory.systemTemp.createTempSync('catalog_audit_');
      addTearDown(() => root.deleteSync(recursive: true));
      void write(String name, String source) {
        final file = File(p.join(root.path, 'widgetbook/lib', name));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(source);
      }

      write('catalog.dart', "import 'cases.dart'; // Missing()\n");
      write(
        'cases.dart',
        'TypeOnly? value; final a = Direct(); final b = const Named.kind();',
      );
      final result = collectWidgetbook(root.path, [
        'Direct',
        'Named',
        'Missing',
        'TypeOnly',
      ]);
      expect(result['referencedWidgets'], 2);
      expect(result['unreferencedWidgets'], ['Missing', 'TypeOnly']);
    },
  );
}
