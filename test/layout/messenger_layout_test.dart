import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wide keeps empty detail and narrow keeps selected detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        const CarpenterMessengerLayout(
          selectedConversationId: null,
          directory: Text('Список'),
          conversation: Text('Чат room'),
          emptyConversation: Text('Выберите чат'),
        ),
      ),
    );
    expect(find.text('Список'), findsOneWidget);
    expect(find.text('Выберите чат'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const CarpenterMessengerLayout(
          selectedConversationId: 'room',
          directory: Text('Список'),
          conversation: Text('Чат room'),
          emptyConversation: Text('Выберите чат'),
        ),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pump();
    expect(find.text('Чат room'), findsOneWidget);
    expect(find.text('Список'), findsNothing);

    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pump();
    expect(find.text('Список'), findsOneWidget);
    expect(find.text('Чат room'), findsOneWidget);
  });

  testWidgets('header only exposes supplied presence and pinned navigation', (
    tester,
  ) async {
    var pinnedIndex = -1;
    var calls = 0;
    await tester.pumpWidget(
      _host(
        CarpenterConversationHeader(
          title: 'Северный парк',
          avatar: const CarpenterConversationAvatar(
            name: 'Северный парк',
            shape: CarpenterConversationAvatarShape.room,
          ),
          presence: CarpenterPresenceKind.typing,
          onCall: () => calls++,
          pinnedMessages: CarpenterPinnedMessages(
            previews: const ['Первое', 'Второе'],
            currentIndex: 1,
            onSelected: (index) => pinnedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('печатает…'), findsOneWidget);
    expect(find.text('Второе'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Позвонить'));
    await tester.tap(find.text('Второе'));
    expect(calls, 1);
    expect(pinnedIndex, 1);

    await tester.pumpWidget(
      _host(
        const CarpenterConversationHeader(
          title: 'Анна',
          avatar: CarpenterConversationAvatar(
            name: 'Анна',
            shape: CarpenterConversationAvatarShape.person,
          ),
        ),
      ),
    );
    expect(find.text('печатает…'), findsNothing);
    expect(find.bySemanticsLabel('Позвонить'), findsNothing);
  });

  testWidgets('wide messenger exposes a controlled resizable split', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var position = 0.42;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return CarpenterMessengerLayout(
              selectedConversationId: 'room',
              splitPosition: position,
              onSplitPositionChanged: (value) =>
                  rebuild(() => position = value),
              directory: const Text('Список'),
              conversation: const Text('Чат'),
              emptyConversation: const Text('Пусто'),
            );
          },
        ),
      ),
    );

    await tester.drag(
      find.bySemanticsLabel('Изменить размеры областей'),
      const Offset(100, 0),
    );
    await tester.pump();
    expect(position, greaterThan(0.42));
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
        child: FocusScope(child: child),
      ),
    ),
  ),
);
