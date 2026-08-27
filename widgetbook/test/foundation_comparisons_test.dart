import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/basic/button.dart';
import 'package:carpenter_widgetbook/use_cases/basic/input.dart';
import 'package:carpenter_widgetbook/use_cases/foundation/colors.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation semantic color catalog renders theme roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        Builder(builder: foundationColorsComponent.useCases.first.builder),
      ),
    );

    expect(find.text('Layout surfaces'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Feedback pairs'), findsOneWidget);
    expect(find.text('Focus and borders'), findsOneWidget);
    expect(find.textContaining('#FF'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button and input comparisons cover every size role', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(Builder(builder: buttonComponent.useCases[1].builder)),
    );
    expect(
      find.byType(CarpenterButton),
      findsNWidgets(ControlSize.values.length),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _harness(Builder(builder: inputComponent.useCases[1].builder)),
    );
    expect(find.byType(EditableText), findsNWidgets(FieldSize.values.length));
    expect(tester.takeException(), isNull);
  });
}

Widget _harness(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(size: Size(1200, 900)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 1200, height: 900, child: child),
      ),
    ),
  ),
);
