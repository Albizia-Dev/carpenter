import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(
    Widget child, {
    CarpenterThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child),
      ),
    ),
  );

  for (final role in FeedbackColorRole.values) {
    testWidgets('resolves ${role.name} feedback pair', (tester) async {
      final theme = CarpenterThemeData.light();
      await tester.pumpWidget(
        harness(
          CarpenterStatusIndicator(label: role.name, role: role),
          theme: theme,
        ),
      );
      final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final box = decoration.decoration as BoxDecoration;
      final text = tester.widget<Text>(find.text(role.name));
      expect(box.color, theme.feedback.resolve(role).background);
      expect(text.style!.color, theme.feedback.resolve(role).foreground);
      expect(find.bySemanticsLabel(role.name), findsOneWidget);
    });
  }

  testWidgets('long Cyrillic label wraps under tight width at 200% scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Align(
          child: SizedBox(
            width: 160,
            child: CarpenterStatusIndicator(
              label: 'Ожидает дополнительного согласования',
              role: FeedbackColorRole.warning,
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CarpenterStatusIndicator)).width, 160);
  });

  testWidgets('works in RTL dark high contrast', (tester) async {
    final theme = CarpenterThemeData.dark(contrast: ContrastMode.high);
    await tester.pumpWidget(
      harness(
        const CarpenterStatusIndicator(
          label: 'Готово',
          role: FeedbackColorRole.success,
        ),
        theme: theme,
        direction: TextDirection.rtl,
      ),
    );
    expect(
      tester.widget<Text>(find.text('Готово')).style!.color,
      theme.feedback.resolve(FeedbackColorRole.success).foreground,
    );
  });

  testWidgets('shape sides are independent logical sides', (tester) async {
    const indicator = CarpenterStatusIndicator(
      label: 'Joined status',
      role: FeedbackColorRole.info,
      shape: CarpenterShape(start: ShapeRole.circular, end: ShapeRole.none),
    );

    BorderRadius resolvedRadius() {
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final directional =
          (box.decoration as BoxDecoration).borderRadius!
              as BorderRadiusDirectional;
      return directional.resolve(
        Directionality.of(tester.element(find.byType(DecoratedBox))),
      );
    }

    await tester.pumpWidget(harness(indicator));
    expect(resolvedRadius().topLeft.x, greaterThan(0));
    expect(resolvedRadius().topRight, Radius.zero);

    await tester.pumpWidget(harness(indicator, direction: TextDirection.rtl));
    expect(resolvedRadius().topLeft, Radius.zero);
    expect(resolvedRadius().topRight.x, greaterThan(0));
  });
}
