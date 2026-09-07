import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('four explorer destinations remain reachable in bounded width', (
    tester,
  ) async {
    var selected = 'common';
    await tester.pumpWidget(
      carpenterHarness(
        SizedBox(
          width: 420,
          child: CarpenterExplorerLocationStrip<String>(
            value: selected,
            onChanged: (value) => selected = value,
            destinations: const [
              CarpenterExplorerDestination(value: 'common', label: 'Common'),
              CarpenterExplorerDestination(value: 'p', label: 'Stage P'),
              CarpenterExplorerDestination(value: 'r', label: 'Stage R'),
            ],
            remembered: const CarpenterExplorerDestination(
              value: 'folder',
              label: 'Specifications',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Specifications'));
    await tester.pump();
    expect(selected, 'folder');
    expect(tester.takeException(), isNull);
  });
}
