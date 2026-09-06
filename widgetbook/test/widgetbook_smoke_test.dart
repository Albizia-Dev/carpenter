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

  test(
    'catalog has stable groups, unique names, and canonical playgrounds',
    () {
      expect(carpenterCatalog.map((node) => node.name), [
        'Foundation',
        'Basic',
        'Behaviour',
        'Collections',
        'Layout',
        'Page Patterns',
        'Samples',
      ]);
      final paths = <String>{};
      for (final group in carpenterCatalog) {
        final children = group.children!;
        expect(children, isNotEmpty, reason: group.name);
        expect(
          children.map((node) => node.name).toSet().length,
          children.length,
          reason: 'Duplicate component in ${group.name}',
        );
        for (final component in children.cast<WidgetbookComponent>()) {
          expect(component.name.trim(), component.name);
          expect(component.useCases, isNotEmpty, reason: component.name);
          expect(
            component.useCases.map((item) => item.name).toSet().length,
            component.useCases.length,
            reason: 'Duplicate case in ${component.name}',
          );
          for (final useCase in component.useCases) {
            expect(
              paths.add('${group.name}/${component.name}/${useCase.name}'),
              isTrue,
            );
            expect(useCase.name.trim(), useCase.name);
          }
          // Foundation pages compare tokens rather than instantiate one widget.
          if (group.name != 'Foundation') {
            expect(
              component.useCases.where((item) => item.name == 'Playground'),
              hasLength(1),
              reason: '${group.name}/${component.name}',
            );
          }
        }
      }
    },
  );

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
