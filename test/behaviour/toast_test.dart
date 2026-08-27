import 'dart:ui' show PointerDeviceKind;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('queues beyond max visible and promotes after dismiss', (
    tester,
  ) async {
    final controller = CarpenterToasterController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterToastRegion(
          controller: controller,
          maxVisible: 2,
          child: const SizedBox(width: 800, height: 600),
        ),
      ),
    );
    for (var index = 1; index <= 3; index++) {
      controller.show(
        CarpenterToastDescriptor(
          id: index,
          message: 'Toast $index',
          duration: ToastDuration.persistent,
        ),
      );
    }
    await tester.pump();
    expect(find.text('Toast 1'), findsOneWidget);
    expect(find.text('Toast 2'), findsOneWidget);
    expect(find.text('Toast 3'), findsNothing);
    controller.dismiss(1);
    await tester.pump();
    expect(find.text('Toast 3'), findsOneWidget);
  });

  testWidgets('auto dismiss pauses on hover and resumes afterwards', (
    tester,
  ) async {
    final controller = CarpenterToasterController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterToastRegion(
          controller: controller,
          child: const SizedBox(width: 800, height: 600),
        ),
      ),
    );
    controller.show(
      const CarpenterToastDescriptor(id: 'timed', message: 'Timed toast'),
    );
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(
      location: tester.getCenter(find.text('Timed toast')),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Timed toast'), findsOneWidget);
    await mouse.moveTo(const Offset(10, 500));
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Timed toast'), findsNothing);
  });

  testWidgets('action invokes once, dismisses, and semantics announce', (
    tester,
  ) async {
    final controller = CarpenterToasterController();
    addTearDown(controller.dispose);
    var actions = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterToastRegion(
          controller: controller,
          child: const SizedBox(width: 800, height: 600),
        ),
      ),
    );
    controller.show(
      CarpenterToastDescriptor(
        id: 'action',
        title: 'Saved',
        message: 'Document saved',
        role: FeedbackColorRole.success,
        duration: ToastDuration.persistent,
        action: CarpenterActionDescriptor(
          id: 'undo',
          label: 'Undo',
          onInvoke: () => actions++,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label == 'Saved. Document saved',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(actions, 1);
    expect(find.text('Document saved'), findsNothing);
  });

  testWidgets('controller dismissAll clears transient state', (tester) async {
    final controller = CarpenterToasterController();
    addTearDown(controller.dispose);
    controller.show(const CarpenterToastDescriptor(id: 1, message: 'One'));
    controller.show(const CarpenterToastDescriptor(id: 2, message: 'Two'));
    expect(controller.toasts, hasLength(2));
    controller.dismissAll();
    expect(controller.toasts, isEmpty);
  });
}
