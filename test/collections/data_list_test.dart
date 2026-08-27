import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget subject({
    required CollectionSnapshot<String> snapshot,
    required CollectionSelection<String> selection,
    ValueChanged<CollectionSelection<String>>? onSelectionChanged,
  }) => carpenterHarness(
    SizedBox(
      height: 320,
      child: CarpenterDataList<String, String>(
        snapshot: snapshot,
        itemKey: (item) => item,
        itemSemanticLabel: (item) => item,
        itemBuilder: (context, item) => CarpenterText.body(item),
        selection: selection,
        onSelectionChanged: onSelectionChanged,
      ),
    ),
  );

  testWidgets('selection is controlled through stable item keys', (
    tester,
  ) async {
    var selection = CollectionSelection<String>.single();
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return subject(
            snapshot: CollectionSnapshot(items: const ['Alpha', 'Bravo']),
            selection: selection,
            onSelectionChanged: (value) => update(() => selection = value),
          );
        },
      ),
    );

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(selection.selectedKeys, {'Bravo'});

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selection.selectedKeys, {'Bravo'});
  });

  testWidgets('refresh and refresh failure preserve list items', (
    tester,
  ) async {
    final refreshing = CollectionSnapshot<String>(
      items: const ['Existing payment'],
      loadPhase: CollectionLoadPhase.refreshing,
      freshness: CollectionFreshness.stale,
    );
    await tester.pumpWidget(
      subject(
        snapshot: refreshing,
        selection: CollectionSelection<String>.none(),
      ),
    );
    expect(find.text('Existing payment'), findsOneWidget);
    expect(find.text('Refreshing data'), findsOneWidget);

    await tester.pumpWidget(
      subject(
        snapshot: refreshing.withLoadFailure(
          const CollectionFailure(error: 'timeout', message: 'Network timeout'),
        ),
        selection: CollectionSelection<String>.none(),
      ),
    );
    expect(find.text('Existing payment'), findsOneWidget);
    expect(find.text('Network timeout'), findsOneWidget);
  });

  testWidgets('exclusive loading, error, zero and empty states render', (
    tester,
  ) async {
    final states = <CollectionSnapshot<String>>[
      CollectionSnapshot.initialLoading(),
      CollectionSnapshot(
        initialFailure: const CollectionFailure(error: 'failure'),
      ),
      CollectionSnapshot(contentState: CollectionContentState.zero),
      CollectionSnapshot(contentState: CollectionContentState.emptyResult),
    ];
    for (final snapshot in states) {
      await tester.pumpWidget(
        subject(
          snapshot: snapshot,
          selection: CollectionSelection<String>.none(),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
