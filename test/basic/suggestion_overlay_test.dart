import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/internal/selection/menu_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('combo box suggestions match the field width', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 360,
          child: CarpenterComboBox<int>(
            controller: controller,
            value: null,
            onChanged: (_) {},
            onQueryChanged: (_) {},
            open: true,
            onOpenChanged: (_) {},
            options: const [
              CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
              CarpenterOption(id: 'b', value: 2, label: 'Bravo'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fieldWidth = tester.getSize(find.byType(CarpenterFieldShell)).width;
    final menuWidth = tester.getSize(find.byType(MenuPanel)).width;
    expect(menuWidth, fieldWidth);
    expect(tester.takeException(), isNull);
  });
}
