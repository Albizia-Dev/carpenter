import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('room avatars are square and show mute state', (tester) async {
    await tester.pumpWidget(
      _host(
        const CarpenterConversationAvatar(
          name: 'Северный парк',
          shape: CarpenterConversationAvatarShape.room,
          muted: true,
        ),
      ),
    );
    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.bySemanticsLabel('Без звука'), findsOneWidget);
  });

  testWidgets('conversation row opens its host action menu', (tester) async {
    var muted = false;
    await tester.pumpWidget(
      _host(
        CarpenterConversationTile(
          title: 'Анна',
          preview: 'Проверьте документ',
          avatar: const CarpenterConversationAvatar(
            name: 'Анна',
            shape: CarpenterConversationAvatarShape.person,
          ),
          selected: false,
          onSelected: () {},
          unreadCount: 2,
          previewDelivery: CarpenterMessageDelivery.read,
          actions: [
            CarpenterMenuItem(
              action: CarpenterActionDescriptor(
                id: 'mute',
                label: 'Без звука',
                onInvoke: () => muted = true,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('Прочитано'), findsOneWidget);
    await tester.longPress(find.text('Анна').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Без звука').last);
    expect(muted, isTrue);
  });

  testWidgets('chat composer sends attachment only draft', (tester) async {
    var sends = 0;
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          text: '',
          hasAttachments: true,
          onTextChanged: (_) {},
          onSend: () => sends++,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Отправить'));
    expect(sends, 1);
  });

  testWidgets('voice playback reports seek and next speed', (tester) async {
    Duration? seek;
    double? speed;
    await tester.pumpWidget(
      _host(
        CarpenterVoiceControls(
          phase: CarpenterVoicePhase.idle,
          recordDuration: Duration.zero,
          position: const Duration(seconds: 20),
          duration: const Duration(minutes: 1),
          speed: 1,
          playingMessage: true,
          onSeek: (value) => seek = value,
          onSpeedChanged: (value) => speed = value,
        ),
      ),
    );
    await tester.tap(find.text('+15 с'));
    await tester.tap(find.text('Скорость 1.0×'));
    expect(seek, const Duration(seconds: 35));
    expect(speed, 1.25);
  });

  testWidgets('consecutive author block ends after twenty minutes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarpenterMessengerWorkspace(
          conversations: const [
            CarpenterConversationItem(id: 'room', title: 'Чат', subtitle: ''),
          ],
          selectedId: 'room',
          messages: [
            CarpenterMessageItem(
              id: 'first',
              author: 'Анна',
              authorKey: 'anna',
              text: 'Первое',
              status: '',
              sentAt: DateTime(2026, 9, 24, 10),
            ),
            CarpenterMessageItem(
              id: 'second',
              author: 'Анна',
              authorKey: 'anna',
              text: 'Второе',
              status: '',
              sentAt: DateTime(2026, 9, 24, 10, 19),
            ),
            CarpenterMessageItem(
              id: 'third',
              author: 'Анна',
              authorKey: 'anna',
              text: 'Третье',
              status: '',
              sentAt: DateTime(2026, 9, 24, 10, 41),
            ),
          ],
          draft: '',
          needAnswer: false,
          onSelected: (_) {},
          onDraftChanged: (_) {},
          onNeedAnswerChanged: (_) {},
          onSend: null,
          onRetry: (_) {},
        ),
      ),
    );
    final bubbles = tester.widgetList<CarpenterMessageBubble>(
      find.byType(CarpenterMessageBubble),
    );
    final grouped = {
      for (final bubble in bubbles) bubble.message.id: bubble.groupWithPrevious,
    };
    expect(grouped['second'], isTrue);
    expect(grouped['third'], isFalse);
  });

  testWidgets('split view retains selected detail across viewport changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        const CarpenterConversationSplitView(
          selected: true,
          master: Text('Список'),
          detail: Text('Чат'),
          emptyDetail: Text('Выберите чат'),
        ),
      ),
    );
    expect(find.text('Чат'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pump();
    expect(find.text('Чат'), findsOneWidget);
    expect(find.text('Список'), findsNothing);
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
          child: Overlay(
            initialEntries: [
              OverlayEntry(builder: (_) => SizedBox.expand(child: child)),
            ],
          ),
        ),
      ),
    ),
  ),
);
