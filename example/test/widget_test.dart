import 'package:carpenter_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('development example renders every S2 section', (tester) async {
    await tester.pumpWidget(const CoreComponentsExample());
    expect(find.text('Core components'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Icons'), findsOneWidget);
    expect(find.text('Statuses'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1200),
    );
    await tester.pump();
    expect(find.text('Fields'), findsOneWidget);
    expect(find.text('Value controls'), findsOneWidget);
    expect(find.text('Icon buttons'), findsOneWidget);
  });
}
