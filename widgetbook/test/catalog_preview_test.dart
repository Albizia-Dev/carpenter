import 'dart:io';

import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/addons/carpenter_addons.dart';
import 'package:carpenter_widgetbook/addons/text_direction_addon.dart';
import 'package:carpenter_widgetbook/helpers/catalog_group.dart';
import 'package:carpenter_widgetbook/helpers/preview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  testWidgets('registration preserves viewport constraints and design links', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final fullViewport in [false, true]) {
      BoxConstraints? received;
      final group = catalogGroup(
        name: 'Group',
        fullViewport: fullViewport,
        children: [
          WidgetbookFolder(
            name: 'Nested',
            children: [
              WidgetbookComponent(
                name: 'Component',
                useCases: [
                  WidgetbookUseCase(
                    name: 'Playground',
                    designLink: 'https://example.com/design',
                    builder: (_) => LayoutBuilder(
                      builder: (_, constraints) {
                        received = constraints;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final component =
          group.children!.single.children!.single as WidgetbookComponent;
      final useCase = component.useCases.single;
      expect(useCase.designLink, 'https://example.com/design');
      for (final size in [const Size(390, 844), const Size(1280, 800)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          _host(
            SizedBox.fromSize(
              size: size,
              child: Builder(builder: useCase.builder),
            ),
          ),
        );
        final inset = fullViewport ? 0.0 : 48.0;
        expect(received!.maxWidth, size.width - inset);
        expect(received!.maxHeight, size.height - inset);
        expect(received!.hasBoundedHeight, isTrue);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shared theme colors raw text in every Carpenter theme', (
    tester,
  ) async {
    final addon = carpenterAddons
        .whereType<ThemeAddon<CarpenterThemeData>>()
        .single;
    for (final theme in carpenterThemes) {
      Color? textColor;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => addon.themeBuilder(
              context,
              theme.data,
              Builder(
                builder: (context) {
                  textColor = DefaultTextStyle.of(context).style.color;
                  expect(CarpenterTheme.of(context), theme.data);
                  return const Text('Preview label');
                },
              ),
            ),
          ),
        ),
      );
      expect(textColor, theme.data.content.primary, reason: theme.name);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('direction addon aligns component previews to reading start', (
    tester,
  ) async {
    const key = ValueKey('probe');
    final addon = TextDirectionAddon();
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => addon.buildUseCase(
              context,
              preview(const SizedBox(key: key, width: 40, height: 20)),
              direction,
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(key)).dx,
        direction == TextDirection.ltr ? 0 : 760,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('catalog sources only consume the modern public Carpenter facade', () {
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final imports = RegExp(
        "(?:import|export) 'package:carpenter/([^']+)'",
      ).allMatches(file.readAsStringSync());
      for (final match in imports) {
        expect(match.group(1), 'carpenter.dart', reason: file.path);
      }
    }
  });
}

Widget _host(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(style: const TextStyle(), child: child),
  ),
);
