import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('host font families apply to every semantic typography path', (
    tester,
  ) async {
    const typography = CarpenterTypographyTheme(
      fontFamily: 'Arial',
      fontFamilyFallback: ['Noto Sans', 'sans-serif'],
    );
    await tester.pumpWidget(
      CarpenterApp(
        theme: CarpenterThemeData.light().copyWith(typography: typography),
        child: Builder(
          builder: (context) {
            final styles = [
              for (final role in TypographyRole.values)
                for (final emphasis in TypographyEmphasis.values)
                  typography.resolve(context, role, emphasis),
              for (final size in ControlSize.values)
                typography.action(context, size, TypographyEmphasis.regular),
              for (final size in FieldSize.values) ...[
                typography.fieldInput(
                  context,
                  size,
                  TypographyEmphasis.regular,
                ),
                typography.fieldLabel(
                  context,
                  size,
                  TypographyEmphasis.regular,
                ),
                typography.fieldSupporting(
                  context,
                  size,
                  TypographyEmphasis.regular,
                ),
              ],
              typography.status(context, TypographyEmphasis.regular),
              typography.menuItem(context, TypographyEmphasis.regular),
              typography.tooltip(context, TypographyEmphasis.regular),
              typography.dialogTitle(context, TypographyEmphasis.regular),
              typography.toastTitle(context, TypographyEmphasis.regular),
              typography.toastMessage(context, TypographyEmphasis.regular),
              typography.tableHeader(context, TypographyEmphasis.regular),
              typography.tableCell(context, TypographyEmphasis.regular),
            ];
            for (final style in styles) {
              expect(style.fontFamily, 'Arial');
              expect(style.fontFamilyFallback, ['Noto Sans', 'sans-serif']);
            }
            expect(
              const CarpenterTypographyTheme()
                  .resolve(
                    context,
                    TypographyRole.body,
                    TypographyEmphasis.regular,
                  )
                  .fontFamily,
              isNull,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
