import 'dart:ui' show PointerDeviceKind;
import 'package:carpenter/carpenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('action shortcut appears in menu and icon hover', (tester) async {
    final action = CarpenterActionDescriptor(
      id: 'save',
      label: 'Сохранить',
      icon: GravityIcons.floppyDisk,
      shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
      onInvoke: () {},
    );
    await tester.pumpWidget(
      CarpenterApp(
        child: Column(
          children: [
            CarpenterMenu(items: [CarpenterMenuItem(action: action)]),
            CarpenterIconButton.fromAction(action),
          ],
        ),
      ),
    );
    final label = CarpenterHotkeyFormatter(
      platform: defaultTargetPlatform,
    ).formatActivator(action.shortcut!);
    expect(find.text(label), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(CarpenterIconButton)));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Сохранить · $label'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 1280.0]) {
    testWidgets('editor dialog adapts and preserves Escape at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var open = true;
      final input = TextEditingController();
      addTearDown(input.dispose);
      await tester.pumpWidget(
        CarpenterApp(
          child: StatefulBuilder(
            builder: (context, setState) => CarpenterDialog(
              open: open,
              onOpenChanged: (value) => setState(() => open = value),
              presentation: CarpenterDialogPresentation.editor,
              title: 'Форма',
              content: CarpenterInput(
                controller: input,
                placeholder: 'Название',
              ),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final form = tester.getRect(find.byType(CarpenterInput));
      expect(form.right, lessThanOrEqualTo(width));
      expect(form.left, width == 390 ? lessThan(40) : greaterThan(500));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(open, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('header identity wraps with long titles on compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      CarpenterApp(
        child: CarpenterEntityHeader(
          title: 'Юридическое лицо с длинным названием',
          leading: const CarpenterAvatar(initials: 'СК'),
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'edit',
              label: 'Редактировать',
              onInvoke: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('СК'), findsOneWidget);
  });
}
