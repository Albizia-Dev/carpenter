import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'stateful dialog builder captures scopes and returns a typed result',
    (tester) async {
      int? result;
      final theme = CarpenterThemeData.dark();
      await tester.pumpWidget(
        CarpenterApp(
          theme: theme,
          rem: const Px(20),
          child: Builder(
            builder: (context) => CarpenterButton(
              label: 'Open form',
              onInvoke: () async {
                result = await showCarpenterDialog<int>(
                  context: context,
                  builder: (context) {
                    expect(CarpenterTheme.of(context), same(theme));
                    expect(context.units(1.rem), 20);
                    var count = 0;
                    return StatefulBuilder(
                      builder: (context, update) => CarpenterDialog(
                        open: true,
                        onOpenChanged: (open) {
                          if (!open) Navigator.of(context).pop();
                        },
                        child: const SizedBox.shrink(),
                        title: 'Edit quantity',
                        content: CarpenterButton(
                          label: 'Quantity $count',
                          onInvoke: () => update(() => count++),
                        ),
                        actions: [
                          CarpenterActionDescriptor(
                            id: 'save',
                            label: 'Save',
                            onInvoke: () => Navigator.of(context).pop(count),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quantity 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 1);
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Edit quantity'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
