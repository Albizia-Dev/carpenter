import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('short lists wrap content and long lists retain scrolling', (
    tester,
  ) async {
    Widget harness(int count) => CarpenterApp(
      child: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Align(
            alignment: Alignment.topCenter,
            child: CarpenterDataList<int, int>(
              shrinkWrap: true,
              snapshot: CollectionSnapshot(
                items: List.generate(count, (i) => i),
              ),
              itemKey: (i) => i,
              itemSemanticLabel: (i) => 'Row $i',
              selection: CollectionSelection.none(),
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Row $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(harness(1));
    expect(
      tester.getSize(find.byType(CarpenterDataList<int, int>)).height,
      lessThan(100),
    );
    await tester.pumpWidget(harness(30));
    expect(
      tester.getSize(find.byType(CarpenterDataList<int, int>)).height,
      300,
    );
    await tester.scrollUntilVisible(
      find.text('Row 29'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Row 29'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
