import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long press selects and left swipe requests reply', (
    tester,
  ) async {
    var selection = false;
    var replies = 0;
    await tester.pumpWidget(
      _host(
        CarpenterMessageBubble(
          message: CarpenterMessageView(
            id: 'message',
            authorId: 'anna',
            authorLabel: 'Анна',
            body: 'Проверьте',
            own: false,
            sentAt: DateTime(2026, 9, 24, 10),
          ),
          selected: false,
          selectionMode: false,
          onSelectionChanged: (selected) => selection = selected,
          onReplyRequested: () => replies++,
        ),
      ),
    );

    await tester.longPress(find.text('Проверьте'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    expect(selection, isTrue);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('message-bubble-message'))),
    );
    await gesture.moveBy(const Offset(-96, 0));
    await gesture.up();
    await tester.pump();
    expect(replies, 1);
  });

  testWidgets('vertical movement does not trigger reply', (tester) async {
    var replies = 0;
    await tester.pumpWidget(
      _host(
        CarpenterMessageBubble(
          message: CarpenterMessageView(
            id: 'message',
            authorId: 'anna',
            authorLabel: 'Анна',
            body: 'Проверьте',
            own: false,
            sentAt: DateTime(2026, 9, 24, 10),
          ),
          selected: false,
          selectionMode: false,
          onReplyRequested: () => replies++,
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('message-bubble-message'))),
    );
    await gesture.moveBy(const Offset(-16, 96));
    await gesture.up();
    await tester.pump();
    expect(replies, 0);
  });

  testWidgets('tap adds another message while selection mode is active', (
    tester,
  ) async {
    var selected = <String>{'first'};
    late StateSetter rebuild;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return CarpenterMessageBubble(
              message: CarpenterMessageView(
                id: 'second',
                authorId: 'anna',
                authorLabel: 'Анна',
                body: 'Второе',
                own: false,
                sentAt: DateTime(2026, 9, 24, 10),
              ),
              selected: selected.contains('second'),
              selectionMode: selected.isNotEmpty,
              onSelectionChanged: (value) => rebuild(() {
                selected = {...selected};
                if (value) {
                  selected.add('second');
                } else {
                  selected.remove('second');
                }
              }),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Второе'));
    await tester.pump();
    expect(selected, contains('second'));
  });
}

Widget _host(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
        ),
      ),
    ),
  ),
);
