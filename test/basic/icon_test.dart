import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _icon = IconData(
  0xe001,
  fontFamily: 'MaterialIcons',
  matchTextDirection: true,
);
const _customIcon = _TestIconData();

final class _TestIconData extends CarpenterIconData {
  const _TestIconData();

  @override
  Widget buildIcon(
    BuildContext context, {
    required double size,
    required Color color,
    String? semanticLabel,
  }) => _TestRenderedIcon(
    size: size,
    color: color,
    semanticLabel: semanticLabel,
  );
}

final class _TestRenderedIcon extends StatelessWidget {
  const _TestRenderedIcon({
    required this.size,
    required this.color,
    required this.semanticLabel,
  });

  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: SizedBox.square(
      dimension: size,
      child: ColoredBox(color: color),
    ),
  );
}

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

  testWidgets('renders custom CarpenterIconData with resolved properties', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      harness(
        const CarpenterIcon(
          _customIcon,
          size: IconSize.large,
          colorRole: ContentColorRole.secondary,
          semanticLabel: 'Custom icon',
        ),
        theme: theme,
      ),
    );

    final rendered = tester.widget<_TestRenderedIcon>(
      find.byType(_TestRenderedIcon),
    );
    final context = tester.element(find.byType(CarpenterIcon));
    expect(rendered.size, context.units(theme.sizes.icon(IconSize.large)));
    expect(rendered.color, theme.content.secondary);
    expect(rendered.semanticLabel, 'Custom icon');
  });

  testWidgets('custom icon source works in action icon slots', (tester) async {
    await tester.pumpWidget(
      harness(
        CarpenterButton(
          label: 'Action',
          icon: _customIcon,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byType(_TestRenderedIcon), findsOneWidget);
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
