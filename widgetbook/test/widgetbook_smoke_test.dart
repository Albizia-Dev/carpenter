import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/widgetbook.dart';
import 'package:carpenter_widgetbook/addons/carpenter_addons.dart';
import 'package:carpenter_widgetbook/catalog.dart';
import 'package:carpenter_widgetbook/helpers/layout_viewport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  testWidgets('Widgetbook app uses the tested catalog', (tester) async {
    final app = createCarpenterWidgetbook() as Widgetbook;
    expect(identical(app.directories, carpenterCatalog), isTrue);
    await tester.pumpWidget(app);
    expect(find.byType(Widgetbook), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('catalog has stable groups, unique names, and canonical playgrounds', () {
    expect(carpenterCatalog.map((node) => node.name), [
      'Foundation',
      'Components',
      'Collections',
      'Overlays',
      'Layout',
      'Pages',
      'Application',
      'Examples',
    ]);
    final componentNames = <String>{};
    final caseBuilders = <Object>{};
    void visit(WidgetbookNode node, String parent) {
      final path = '$parent/${node.name}';
      expect(node.name.trim(), node.name);
      final children = node.children!;
      expect(children, isNotEmpty, reason: path);
      expect(
        children.map((child) => child.name).toSet(),
        hasLength(children.length),
        reason: 'Duplicate path: $path',
      );
      if (node is WidgetbookComponent) {
        expect(
          componentNames.add(node.name),
          isTrue,
          reason: 'Component registered more than once: $path',
        );
        for (final useCase in node.useCases) {
          expect(useCase.name.trim(), useCase.name);
          caseBuilders.add(useCase.builder);
          expect(
            useCase.name,
            matches(
              r'^(Playground|Accessibility|(Reference|Variants|States|Edge cases|Scenario) · .+)$',
            ),
            reason: path,
          );
        }
        if (!path.startsWith('/Foundation/')) {
          expect(node.useCases.first.name, 'Playground', reason: path);
          expect(
            node.useCases.where((item) => item.name == 'Playground'),
            hasLength(1),
            reason: path,
          );
        }
      } else {
        for (final child in children) {
          visit(child, path);
        }
      }
    }

    for (final group in carpenterCatalog) {
      visit(group, '');
    }
    expect(componentNames, isNot(contains('Tree table contracts')));
    expect(
      componentNames,
      containsAll(['Tree table', 'Payment list', 'Project page']),
    );
    // Inventory before reorganization: 99 components, 178 scenarios.
    // Contract demos now belong to Tree table; no scenario was removed.
    expect(componentNames, hasLength(99));
    expect(caseBuilders, hasLength(179));
  });

  test(
    'shared environment covers all brightness, density, and contrast axes',
    () {
      expect(carpenterAddons.whereType<ViewportAddon>(), hasLength(1));
      expect(carpenterAddons.first, isA<ViewportAddon>());
      expect(
        carpenterAddons.whereType<ThemeAddon<CarpenterThemeData>>(),
        hasLength(1),
      );
      expect(carpenterThemes, hasLength(8));
      expect(carpenterThemes.map((theme) => theme.name).toSet(), hasLength(8));
      expect(
        carpenterThemes.map((theme) => theme.name),
        containsAll(['Light', 'Dark', 'High contrast', 'High contrast dark']),
      );
    },
  );

  test(
    'fixed viewport presets remain available for explicit regression cases',
    () {
      expect(LayoutViewportPreset.off.dimensions, isNull);
      expect(LayoutViewportPreset.mobilePortrait.dimensions?.$1.value, 24.375);
      expect(LayoutViewportPreset.desktopLarge.dimensions?.$2.value, 67.5);
    },
  );
}
