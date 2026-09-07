import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('remembered explorer location survives primary navigation', (
    tester,
  ) async {
    var current = 'general';
    const remembered = CarpenterExplorerDestination<String>(
      location: 'folder-7',
      label: 'Specifications',
    );

    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) =>
              CarpenterExplorerLocationStrip<String>(
                primaryDestinations: const [
                  CarpenterExplorerDestination<String>(
                    location: 'general',
                    label: 'General',
                  ),
                  CarpenterExplorerDestination<String>(
                    location: 'p',
                    label: 'Stage P',
                  ),
                  CarpenterExplorerDestination<String>(
                    location: 'r',
                    label: 'Stage R',
                  ),
                ],
                rememberedDestination: remembered,
                current: current,
                onChanged: (next) => setState(() => current = next),
              ),
        ),
      ),
    );

    expect(find.text('Specifications'), findsOneWidget);
    await tester.tap(find.text('Stage P'));
    await tester.pump();
    expect(current, 'p');
    expect(find.text('Specifications'), findsOneWidget);

    await tester.tap(find.text('Specifications'));
    await tester.pump();
    expect(current, 'folder-7');
    expect(find.text('Specifications'), findsOneWidget);
  });
}
