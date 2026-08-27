import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _icon = IconData(
  0xe001,
  fontFamily: 'MaterialIcons',
  matchTextDirection: true,
);

void main() {
  Widget harness(
    Widget child, {
    CarpenterThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: Directionality(textDirection: direction, child: child),
    ),
  );

  testWidgets('resolves semantic size and content color', (tester) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      harness(
        const CarpenterIcon(
          _icon,
          size: IconSize.large,
          colorRole: ContentColorRole.secondary,
        ),
        theme: theme,
      ),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    final context = tester.element(find.byType(CarpenterIcon));
    expect(icon.size, context.units(theme.sizes.icon(IconSize.large)));
    expect(icon.color, theme.content.secondary);
  });

  testWidgets('meaningful icon exposes label and decorative icon does not', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Column(
          children: [
            CarpenterIcon(_icon, semanticLabel: 'Direction'),
            CarpenterIcon(_icon),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Direction'), findsOneWidget);
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons.first.semanticLabel, 'Direction');
    expect(icons.last.semanticLabel, isNull);
  });

  testWidgets('preserves directional glyph behavior in RTL', (tester) async {
    await tester.pumpWidget(
      harness(const CarpenterIcon(_icon), direction: TextDirection.rtl),
    );
    expect(
      tester.widget<Icon>(find.byType(Icon)).icon!.matchTextDirection,
      isTrue,
    );
    expect(find.byType(Transform), findsOneWidget);
  });

  testWidgets('works in dark high contrast', (tester) async {
    final theme = CarpenterThemeData.dark(contrast: ContrastMode.high);
    await tester.pumpWidget(harness(const CarpenterIcon(_icon), theme: theme));
    expect(tester.widget<Icon>(find.byType(Icon)).color, theme.content.primary);
  });
}
