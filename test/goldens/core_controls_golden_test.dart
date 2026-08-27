import 'dart:ui' show PointerDeviceKind;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _arrow = IconData(0x2192, matchTextDirection: true);

void main() {
  Future<void> golden(
    WidgetTester tester, {
    required CarpenterThemeData theme,
    required TextDirection direction,
    required double textScale,
    required String file,
  }) async {
    tester.view.physicalSize = const Size(560, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UnitsRoot(
        rem: const Px(16),
        child: CarpenterTheme(
          data: theme,
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: Directionality(
              textDirection: direction,
              child: ColoredBox(
                key: const ValueKey('golden'),
                color: theme.surface.base,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: _GoldenScenario(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile(file),
    );
  }

  testWidgets('light standard controls', (tester) async {
    await golden(
      tester,
      theme: CarpenterThemeData.light(),
      direction: TextDirection.ltr,
      textScale: 1,
      file: 'goldens/core_controls_light.png',
    );
  });

  testWidgets('dark high-contrast RTL controls at 200%', (tester) async {
    await golden(
      tester,
      theme: CarpenterThemeData.dark(
        contrast: ContrastMode.high,
        density: CarpenterDensity.compact,
      ),
      direction: TextDirection.rtl,
      textScale: 2,
      file: 'goldens/core_controls_dark_hc_rtl_200.png',
    );
  });

  testWidgets('focused, hovered, and pressed action states', (tester) async {
    tester.view.physicalSize = const Size(560, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousStrategy;
    });
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      UnitsRoot(
        rem: const Px(16),
        child: CarpenterTheme(
          data: theme,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              key: const ValueKey('states-golden'),
              color: theme.surface.base,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CarpenterButton(
                      key: const ValueKey('focused'),
                      label: 'Focused',
                      focusNode: focusNode,
                      colorRole: ActionColorRole.primary,
                      prominence: ActionProminence.high,
                      onInvoke: _noop,
                    ),
                    const SizedBox(width: 16),
                    const CarpenterButton(
                      key: ValueKey('hovered'),
                      label: 'Hovered',
                      onInvoke: _noop,
                    ),
                    const SizedBox(width: 16),
                    const CarpenterIconButton(
                      key: ValueKey('pressed'),
                      icon: _arrow,
                      semanticLabel: 'Pressed',
                      colorRole: ActionColorRole.danger,
                      onInvoke: _noop,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump(const Duration(milliseconds: 200));

    final hover = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    addTearDown(hover.removePointer);
    await hover.addPointer(location: const Offset(900, 700));
    await tester.pump();
    await hover.moveTo(tester.getCenter(find.byKey(const ValueKey('hovered'))));

    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pressed'))),
      kind: PointerDeviceKind.touch,
      pointer: 2,
    );
    addTearDown(press.removePointer);
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey('states-golden')),
      matchesGoldenFile('goldens/action_control_states.png'),
    );
  });
}

final class _GoldenScenario extends StatelessWidget {
  const _GoldenScenario();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CarpenterText.title(
        'Core rendering',
        emphasis: TypographyEmphasis.strong,
      ),
      const SizedBox(height: 16),
      const CarpenterText.body('Текст и семантическая иконка'),
      const SizedBox(height: 12),
      const Row(
        children: [
          CarpenterIcon(_arrow, semanticLabel: 'Forward'),
          SizedBox(width: 8),
          CarpenterStatusIndicator(
            label: 'Готово',
            role: FeedbackColorRole.success,
          ),
          SizedBox(width: 8),
          CarpenterStatusIndicator(
            label: 'Внимание',
            role: FeedbackColorRole.warning,
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          CarpenterButton(
            label: 'Primary',
            colorRole: ActionColorRole.primary,
            prominence: ActionProminence.high,
            onInvoke: _noop,
          ),
          CarpenterButton(label: 'Neutral', onInvoke: _noop),
          CarpenterButton(
            label: 'Delete',
            colorRole: ActionColorRole.danger,
            prominence: ActionProminence.high,
            onInvoke: _noop,
          ),
          CarpenterButton(label: 'Disabled'),
          CarpenterButton(
            label: 'Running',
            executionPhase: ActionExecutionPhase.running,
            onInvoke: _noop,
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Row(
        children: [
          CarpenterIconButton(
            icon: _arrow,
            semanticLabel: 'Forward',
            onInvoke: _noop,
          ),
          CarpenterIconButton(
            icon: _arrow,
            semanticLabel: 'Delete',
            colorRole: ActionColorRole.danger,
            onInvoke: _noop,
          ),
          CarpenterIconButton(
            icon: _arrow,
            semanticLabel: 'Running',
            executionPhase: ActionExecutionPhase.running,
            onInvoke: _noop,
          ),
        ],
      ),
    ],
  );
}

void _noop() {}
