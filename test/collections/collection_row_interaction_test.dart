import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('collection hover fills row without extra padding or movement', (
    tester,
  ) async {
    var invoked = 0;
    await tester.pumpWidget(
      CarpenterApp(
        child: Center(
          child: SizedBox(
            width: 390,
            height: 500,
            child: CarpenterDataList<int, int>(
              itemPadding: false,
              snapshot: CollectionSnapshot(items: const [1, 2]),
              itemKey: (i) => i,
              itemSemanticLabel: (i) => 'Row $i',
              selection: CollectionSelection.none(),
              itemBuilder: (_, i) => CarpenterListTile(
                key: ValueKey('tile-$i'),
                presentation: CarpenterListTilePresentation.collectionRow,
                title: Text('Row $i'),
                subtitle: const Text(
                  'Long content that wraps onto several lines in a narrow collection',
                ),
                onInvoke: () => invoked++,
              ),
            ),
          ),
        ),
      ),
    );
    final list = tester.getRect(find.byType(CarpenterDataList<int, int>));
    final first = tester.getRect(find.byKey(const ValueKey('tile-1')));
    final second = tester.getRect(find.byKey(const ValueKey('tile-2')));
    expect(first.left, list.left);
    expect(first.right, list.right);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(first.center);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('tile-1'))), first);
    expect(tester.getRect(find.byKey(const ValueKey('tile-2'))), second);
    final surfaces = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const ValueKey('tile-1')),
            matching: find.byType(Container),
          ),
        )
        .where((w) => w.decoration is BoxDecoration);
    expect(surfaces, isNotEmpty);
    expect(
      (surfaces.first.decoration! as BoxDecoration).borderRadius,
      BorderRadius.zero,
    );
    await tester.tapAt(first.center);
    expect(invoked, 1);
    await mouse.moveTo(second.center);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('tile-1'))), first);
    expect(tester.getRect(find.byKey(const ValueKey('tile-2'))), second);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
}
