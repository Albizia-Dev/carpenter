import 'dart:ui' show PointerDeviceKind;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('types, reports changes, focuses, and submits', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final changes = <String>[];
    String? submitted;

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(
          controller: controller,
          label: 'Name',
          placeholder: 'Enter name',
          focusNode: focusNode,
          textInputAction: TextInputAction.done,
          onChanged: changes.add,
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Ada');
    expect(focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(controller.text, 'Ada');
    expect(changes, contains('Ada'));
    expect(submitted, 'Ada');

    await tester.pumpWidget(const SizedBox());
    controller.text = 'Caller still owns me';
    expect(controller.text, 'Caller still owns me');
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('mouse drag creates a text selection', (tester) async {
    final controller = TextEditingController(text: 'alpha beta gamma');
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(controller: controller, label: 'Selectable text'),
      ),
    );
    final editable = find.byType(EditableText);
    final origin = tester.getTopLeft(editable);
    final centerY = tester.getSize(editable).height / 2;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: origin + Offset(4, centerY));
    await mouse.down(origin + Offset(4, centerY));
    await mouse.moveTo(origin + Offset(96, centerY));
    await mouse.up();
    await tester.pump();

    expect(controller.selection.isValid, isTrue);
    expect(controller.selection.isCollapsed, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('disabled blocks editing and focus', (tester) async {
    final controller = TextEditingController(text: 'Locked');
    final focusNode = FocusNode();
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(
          controller: controller,
          label: 'Disabled field',
          availability: FieldAvailability.disabled,
          focusNode: focusNode,
        ),
      ),
    );

    await tester.tap(find.byType(EditableText), warnIfMissed: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    expect(controller.text, 'Locked');
    expect(focusNode.hasFocus, isFalse);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      matchesSemantics(
        label: 'Disabled field',
        isTextField: true,
        hasEnabledState: true,
        isReadOnly: true,
      ),
    );

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('readOnly remains focusable without changing value', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Reference');
    final focusNode = FocusNode();
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(
          controller: controller,
          label: 'Reference code',
          availability: FieldAvailability.readOnly,
          focusNode: focusNode,
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(focusNode.hasFocus, isTrue);
    expect(controller.text, 'Reference');

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('error and required semantics use field theme', (tester) async {
    final controller = TextEditingController();
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(
          controller: controller,
          label: 'Email',
          errorText: 'Invalid email',
          required: true,
        ),
        theme: theme,
      ),
    );

    expect(find.text('Invalid email'), findsOneWidget);
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, theme.fields.borderError);
    expect(find.bySemanticsLabel('Email'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('supports RTL and 200% text scale in dark high contrast', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'مرحبا Carpenter');
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterInput(
          controller: controller,
          label: 'الاسم',
          description: 'وصف طويل للحقل',
          leadingIcon: const IconData(0xe001, fontFamily: 'MaterialIcons'),
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
