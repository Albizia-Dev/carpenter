import 'dart:ui';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('list tile hover does not change row geometry', (tester) async {
    await tester.pumpWidget(
      carpenterHarness(
        SizedBox(
          key: const ValueKey<String>('row'),
          width: 320,
          child: CarpenterListTile(
            title: const CarpenterText.label('Stable row'),
            onInvoke: () {},
          ),
        ),
      ),
    );

    final row = find.byKey(const ValueKey<String>('row'));
    final initialRect = tester.getRect(row);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);

    for (var index = 0; index < 4; index++) {
      await mouse.moveTo(tester.getCenter(row));
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.getRect(row), initialRect);
      await mouse.moveTo(Offset(initialRect.right + 20, initialRect.bottom + 20));
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.getRect(row), initialRect);
    }

    await mouse.removePointer();
  });

  testWidgets('tree drop hover rebuilds only on meaningful target changes', (
    tester,
  ) async {
    final builds = <Object, int>{};
    const nodes = <CarpenterTreeNode<String>>[
      CarpenterTreeNode<String>(id: 'a', value: 'a', label: 'Alpha'),
      CarpenterTreeNode<String>(id: 'b', value: 'b', label: 'Beta'),
    ];

    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 320,
          child: CarpenterTreeView<String>(
            nodes: nodes,
            onDrop: (_) {},
            itemBuilder: (context, node, state) {
              builds[node.id] = (builds[node.id] ?? 0) + 1;
              return SizedBox(
                key: ValueKey<String>('tree-${node.id}'),
                height: 48,
                child: CarpenterText.label(node.label),
              );
            },
          ),
        ),
      ),
    );

    final source = find.byKey(const ValueKey<String>('tree-a'));
    final target = find.byKey(const ValueKey<String>('tree-b'));
    final initialRect = tester.getRect(target);
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();

    expect(tester.getRect(target), initialRect);
    final buildsAfterEnter = builds['b']!;
    final center = tester.getCenter(target);
    for (var delta = 1.0; delta <= 3.0; delta += 1.0) {
      await gesture.moveTo(center + Offset(0, delta));
      await tester.pump();
      expect(tester.getRect(target), initialRect);
    }
    expect(builds['b'], buildsAfterEnter);

    await gesture.up();
    await tester.pump();
  });
}
