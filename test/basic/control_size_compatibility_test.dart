import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = [CarpenterOption(id: 'one', value: 1, label: 'One')];

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'same-role controls align in one row at ${textScale * 100}% text scale',
      (tester) async {
        final inputController = TextEditingController(text: 'Value');
        addTearDown(inputController.dispose);

        for (var index = 0; index < ControlSize.values.length; index++) {
          final controlSize = ControlSize.values[index];
          final fieldSize = FieldSize.values[index];
          await tester.pumpWidget(
            _harness(
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CarpenterInput(
                      controller: inputController,
                      size: fieldSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CarpenterSelect<int>(
                      value: 1,
                      onChanged: (_) {},
                      open: false,
                      onOpenChanged: (_) {},
                      options: options,
                      size: fieldSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CarpenterButton(
                    label: 'Run',
                    size: controlSize,
                    onInvoke: _noop,
                  ),
                  const SizedBox(width: 8),
                  CarpenterRadioGroup<int>(
                    value: 1,
                    onChanged: (_) {},
                    orientation: Axis.horizontal,
                    children: [
                      CarpenterRadio(
                        value: 1,
                        label: 'Radio',
                        size: controlSize,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  CarpenterSwitch(
                    value: true,
                    label: 'Switch',
                    size: controlSize,
                    onChanged: (_) {},
                  ),
                ],
              ),
              textScale: textScale,
            ),
          );

          final buttonVisual = _singleAnimatedContainer(
            tester,
            find.byType(CarpenterButton),
          );
          final inputVisual = _singleAnimatedContainer(
            tester,
            find.byType(CarpenterInput),
          );
          final selectVisual = _singleAnimatedContainer(
            tester,
            find.byType(CarpenterSelect<int>),
          );
          final radioVisual = _singleAnimatedContainer(
            tester,
            find.byType(CarpenterRadio<int>),
          );
          final switchVisuals = find.descendant(
            of: find.byType(CarpenterSwitch),
            matching: find.byType(AnimatedContainer),
          );
          final switchTrack = switchVisuals.first;

          final buttonHeight = tester.getSize(buttonVisual).height;
          expect(
            tester.getSize(inputVisual).height,
            buttonHeight,
            reason: '${controlSize.name} input height',
          );
          expect(
            tester.getSize(selectVisual).height,
            buttonHeight,
            reason: '${controlSize.name} select height',
          );
          expect(
            tester.getSize(radioVisual).height,
            lessThanOrEqualTo(buttonHeight),
            reason: '${controlSize.name} radio indicator',
          );
          expect(
            tester.getSize(switchTrack).height,
            lessThanOrEqualTo(buttonHeight),
            reason: '${controlSize.name} switch track',
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}

Finder _singleAnimatedContainer(WidgetTester tester, Finder owner) {
  final finder = find.descendant(
    of: owner,
    matching: find.byType(AnimatedContainer),
  );
  expect(finder, findsOneWidget);
  return finder;
}

Widget _harness(Widget child, {required double textScale}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 780, child: child)),
      ),
    ),
  ),
);

void _noop() {}
