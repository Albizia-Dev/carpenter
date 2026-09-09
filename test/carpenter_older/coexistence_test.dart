import 'package:carpenter/carpenter.dart' as current;
import 'package:carpenter/carpenter_older.dart' as older;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('both public APIs retain their own button and theme contracts', (
    tester,
  ) async {
    var currentInvocations = 0;
    var olderInvocations = 0;

    await tester.pumpWidget(
      older.CarpenterScope.fromConfig(
        config: const older.CarpenterConfig(),
        child: carpenterHarness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              older.CarpenterButton(
                label: 'Legacy',
                onPressed: () => olderInvocations++,
              ),
              current.CarpenterButton(
                label: 'Current',
                onInvoke: () => currentInvocations++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(older.CarpenterButton));
    expect(olderInvocations, 1);
    expect(currentInvocations, 0);

    await tester.tap(find.byType(current.CarpenterButton));
    expect(olderInvocations, 1);
    expect(currentInvocations, 1);
    expect(tester.takeException(), isNull);
  });
}
