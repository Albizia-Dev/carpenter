import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  testWidgets(
    'link default stays undecorated through hover, focus, press and disable',
    (tester) async {
      final focus = FocusNode();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      try {
        for (final role in CarpenterLinkRole.values) {
          await tester.pumpWidget(
            carpenterHarness(
              CarpenterLink(
                label: 'Link',
                role: role,
                focusNode: focus,
                onInvoke: () {},
              ),
            ),
          );
          focus.requestFocus();
          await tester.pump();
          await mouse.moveTo(tester.getCenter(find.text('Link')));
          await mouse.down(tester.getCenter(find.text('Link')));
          await tester.pump();
          expect(
            tester.widget<Text>(find.text('Link')).style!.decoration,
            TextDecoration.none,
          );
          await mouse.up();
          await tester.pumpWidget(
            carpenterHarness(CarpenterLink(label: 'Link', role: role)),
          );
          expect(
            tester.widget<Text>(find.text('Link')).style!.decoration,
            TextDecoration.none,
          );
        }
        await tester.pumpWidget(const SizedBox());
      } finally {
        await mouse.removePointer();
        focus.dispose();
      }
    },
  );

  testWidgets(
    'selection radii and radio marks keep the same proportions across sizes',
    (tester) async {
      for (final theme in [
        CarpenterThemeData.light(),
        CarpenterThemeData.dark(density: CarpenterDensity.compact),
      ]) {
        for (final size in ControlSize.values) {
          for (final value in CheckboxValue.values) {
            await tester.pumpWidget(
              carpenterHarness(
                CarpenterCheckbox(
                  label: 'Choice',
                  size: size,
                  value: value,
                  onChanged: (_) {},
                ),
                theme: theme,
              ),
            );
            await tester.pumpAndSettle();
            final indicator = tester.widget<AnimatedContainer>(
              find.byType(AnimatedContainer).first,
            );
            final decoration = indicator.decoration! as BoxDecoration;
            final width = tester
                .getSize(find.byType(AnimatedContainer).first)
                .width;
            expect(
              (decoration.borderRadius! as BorderRadius).topLeft.x / width,
              closeTo(.2, .001),
              reason: size.name,
            );
          }
          await tester.pumpWidget(
            carpenterHarness(
              CarpenterRadioGroup<int>(
                value: 1,
                onChanged: (_) {},
                children: [
                  CarpenterRadio<int>(label: 'Choice', value: 1, size: size),
                ],
              ),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();
          final indicator = find.byType(AnimatedContainer).first;
          final dot = find
              .descendant(of: indicator, matching: find.byType(DecoratedBox))
              .last;
          expect(
            tester.getSize(dot).width / tester.getSize(indicator).width,
            closeTo(.6, .001),
            reason: size.name,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'notice tones, long content, action and close fit narrow RTL at 200 percent',
    (tester) async {
      for (final tone in CarpenterNoticeTone.values) {
        // Overlay.initialEntries are initial-only; mount each fixture afresh.
        await tester.pumpWidget(const SizedBox());
        var actionCalls = 0;
        var closeCalls = 0;
        await tester.pumpWidget(
          carpenterOverlayHarness(
            SingleChildScrollView(
              child: SizedBox(
                width: 280,
                child: CarpenterNotice(
                  title: 'Check the operation details',
                  message:
                      'Long explanation of the operation and the next step for the user.',
                  tone: tone,
                  action: CarpenterActionDescriptor(
                    id: 'retry',
                    label: 'Retry',
                    onInvoke: () => actionCalls++,
                  ),
                  onClose: () => closeCalls++,
                ),
              ),
            ),
            direction: TextDirection.rtl,
            textScale: 2,
          ),
        );
        expect(tester.getSize(find.byType(CarpenterNotice)).width, 280);
        await tester.ensureVisible(find.text('Retry'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CarpenterButton));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(CarpenterIconButton));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is CarpenterIconButton &&
                widget.semanticLabel == 'Закрыть уведомление',
          ),
        );
        expect(actionCalls, 1);
        expect(closeCalls, 1);
        expect(tester.takeException(), isNull, reason: tone.name);
      }
    },
  );

  testWidgets(
    'unknown and non-finite progress never announces a percentage and honors reduced motion',
    (tester) async {
      for (final value in <double?>[null, double.nan, double.infinity]) {
        await tester.pumpWidget(
          carpenterHarness(
            SizedBox(
              width: 240,
              child: CarpenterUploadProgress(
                value: value,
                semanticLabel: 'Transfer',
              ),
            ),
            disableAnimations: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Transfer')).value,
          isEmpty,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        carpenterHarness(
          const SizedBox(
            width: 240,
            child: CarpenterUploadProgress(
              value: .5,
              semanticLabel: 'Transfer',
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Transfer')).value,
        '50%',
      );
    },
  );
}
