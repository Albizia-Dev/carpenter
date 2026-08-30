import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('drag controller tracks session target and completion', () {
    final controller = CarpenterDragController();
    const payload = CarpenterDragPayload<String>(
      id: 'a',
      data: 'A',
      allowedOperations: {
        CarpenterDragOperation.move,
        CarpenterDragOperation.copy,
      },
    );

    controller.begin(
      payload: payload,
      operation: CarpenterDragOperation.copy,
      sourceId: 'source',
    );
    expect(controller.isDragging, isTrue);
    expect(controller.session?.sourceId, 'source');
    expect(controller.session?.operation, CarpenterDragOperation.copy);

    controller.hover(
      targetId: 'target',
      position: CarpenterDropPosition.before,
      accepted: true,
    );
    expect(controller.session?.targetId, 'target');
    expect(controller.session?.dropPosition, CarpenterDropPosition.before);
    expect(controller.session?.targetAccepts, isTrue);

    controller.leave('target');
    expect(controller.session?.targetId, isNull);
    expect(controller.session?.dropPosition, isNull);

    controller.complete();
    expect(controller.session, isNull);
    controller.dispose();
  });

  test('drag controller rejects unsupported operations', () {
    final controller = CarpenterDragController();
    const payload = CarpenterDragPayload<String>(data: 'A');

    expect(
      () => controller.begin(
        payload: payload,
        operation: CarpenterDragOperation.copy,
      ),
      throwsArgumentError,
    );
    controller.dispose();
  });

  testWidgets('draggable and drop target complete a typed inside drop', (
    tester,
  ) async {
    CarpenterDropDetails<String>? dropped;
    final controller = CarpenterDragController();

    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterDragScope(
          controller: controller,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarpenterDraggable<String>(
                sourceId: 'source',
                payload: const CarpenterDragPayload<String>(data: 'payload'),
                child: const SizedBox(
                  width: 100,
                  height: 80,
                  child: Center(child: Text('Drag')),
                ),
              ),
              CarpenterDropTarget<String>(
                targetId: 'target',
                onDrop: (details) => dropped = details,
                builder: (context, state) => SizedBox(
                  width: 180,
                  height: 120,
                  child: Center(
                    child: Text(
                      state.hovering
                          ? '${state.accepts}:${state.position?.name}'
                          : 'Drop',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final source = tester.getCenter(find.text('Drag'));
    final target = tester.getCenter(find.text('Drop'));
    final gesture = await tester.startGesture(source);
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();

    expect(controller.session?.targetId, 'target');
    expect(controller.session?.targetAccepts, isTrue);
    expect(controller.session?.dropPosition, CarpenterDropPosition.inside);

    await gesture.up();
    await tester.pump();

    expect(dropped?.payload.data, 'payload');
    expect(dropped?.targetId, 'target');
    expect(dropped?.position, CarpenterDropPosition.inside);
    expect(controller.session, isNull);

    controller.dispose();
  });
}
