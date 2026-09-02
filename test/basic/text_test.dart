import 'package:carpenter/carpenter.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('resolves role, emphasis, and content role from CarpenterTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const CarpenterText(
          'Carpenter',
          role: TypographyRole.title,
          emphasis: TypographyEmphasis.strong,
          colorRole: ContentColorRole.secondary,
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Carpenter'));
    expect(text.style!.fontSize, 20);
    expect(text.style!.fontWeight, FontWeight.w700);
    expect(text.style!.color, CarpenterThemeData.light().content.secondary);
  });

  testWidgets('forwards layout policy and semantic label', (tester) async {
    await tester.pumpWidget(
      harness(
        const CarpenterText.body(
          'Visible',
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          semanticsLabel: 'Spoken',
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Visible'));
    expect(text.textAlign, TextAlign.end);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, isFalse);
    expect(find.bySemanticsLabel('Spoken'), findsOneWidget);
  });

  testWidgets('inherits text scaling and RTL without Material theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const CarpenterText.body('Текст'),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    final renderParagraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(renderParagraph.textDirection, TextDirection.rtl);
    expect(renderParagraph.textScaler.scale(16), 32);
  });

  testWidgets('works in dark high-contrast theme', (tester) async {
    final theme = CarpenterThemeData.dark(contrast: ContrastMode.high);
    await tester.pumpWidget(
      harness(const CarpenterText.caption('Dark'), theme: theme),
    );
    expect(
      tester.widget<Text>(find.text('Dark')).style!.color,
      theme.content.primary,
    );
  });
}
