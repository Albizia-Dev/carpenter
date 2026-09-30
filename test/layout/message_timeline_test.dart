import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('older-history loading is icon-only timeline chrome', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const CarpenterMessageHistoryLoading()));

    expect(find.byType(CarpenterLoader), findsOneWidget);
    expect(find.textContaining('Загрузка'), findsNothing);
  });

  testWidgets('jump to latest is icon-only and exposes unread count', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      _host(
        CarpenterJumpToLatest(newerCount: 7, onPressed: () => invoked = true),
      ),
    );

    expect(find.textContaining('К последним'), findsNothing);
    expect(find.text('7'), findsOneWidget);
    await tester.tap(
      find.bySemanticsLabel('К последним сообщениям, непрочитанных: 7'),
    );
    expect(invoked, isTrue);
  });

  test('group breaks at twenty minutes, date and system events', () {
    final first = _message('first', DateTime(2026, 9, 24, 10));
    final nineteenMinutesLater = _message(
      'second',
      DateTime(2026, 9, 24, 10, 19),
    );
    final twentyMinutesLater = _message('third', DateTime(2026, 9, 24, 10, 20));
    final nextDate = _message('next-date', DateTime(2026, 9, 25, 0));
    final systemEvent = CarpenterMessageView(
      id: 'system',
      authorId: 'system',
      authorLabel: '',
      body: 'Анна закрепила сообщение',
      own: false,
      sentAt: DateTime(2026, 9, 24, 10, 1),
      system: true,
    );

    expect(
      CarpenterMessageClusterPolicy.sameBlock(first, nineteenMinutesLater),
      isTrue,
    );
    expect(
      CarpenterMessageClusterPolicy.sameBlock(first, twentyMinutesLater),
      isFalse,
    );
    expect(CarpenterMessageClusterPolicy.sameBlock(first, nextDate), isFalse);
    expect(
      CarpenterMessageClusterPolicy.sameBlock(first, systemEvent),
      isFalse,
    );
  });

  testWidgets('metadata order and selection edge follow message alignment', (
    tester,
  ) async {
    final sentAt = DateTime(2026, 9, 24, 10);
    await tester.pumpWidget(
      _host(
        CarpenterMessageTimeline(
          messages: [
            CarpenterMessageView(
              id: 'incoming',
              authorId: 'anna',
              authorLabel: 'Анна',
              body: 'Входящее',
              own: false,
              sentAt: sentAt,
            ),
            CarpenterMessageView(
              id: 'own',
              authorId: 'me',
              authorLabel: 'Вы',
              body: 'Исходящее',
              own: true,
              sentAt: sentAt,
              meta: const CarpenterMessageMeta(
                important: true,
                requiresAnswer: true,
                edited: true,
                delivery: CarpenterDeliveryState.read,
              ),
            ),
          ],
          selectedIds: const {'incoming', 'own'},
          groupChat: true,
          metadataLeadingBuilder: (_, message) => [
            SizedBox(key: ValueKey('leading-${message.id}')),
          ],
          metadataTrailingBuilder: (_, message) => [
            SizedBox(key: ValueKey('trailing-${message.id}')),
          ],
          onSelectionChanged: (_, _) {},
        ),
      ),
    );

    final importantX = tester.getCenter(find.bySemanticsLabel('Важное')).dx;
    final answerX = tester
        .getCenter(find.bySemanticsLabel('Требует ответа'))
        .dx;
    final editedX = tester.getCenter(find.bySemanticsLabel('Изменено')).dx;
    final timeX = tester.getCenter(find.text('10:00').last).dx;
    final readX = tester.getCenter(find.bySemanticsLabel('Прочитано')).dx;
    expect(importantX, lessThan(answerX));
    expect(answerX, lessThan(editedX));
    expect(editedX, lessThan(timeX));
    expect(timeX, lessThan(readX));
    final leadingX = tester
        .getCenter(find.byKey(const ValueKey('leading-own')))
        .dx;
    final trailingX = tester
        .getCenter(find.byKey(const ValueKey('trailing-own')))
        .dx;
    expect(leadingX, lessThan(importantX));
    expect(readX, lessThan(trailingX));
    final ownDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('message-bubble-own')),
                )
                .decoration
            as BoxDecoration;
    expect(ownDecoration.border, isNotNull);

    final incomingCheck = tester.getCenter(
      find.byKey(const ValueKey('message-selection-incoming')),
    );
    final incomingBubble = tester.getCenter(
      find.byKey(const ValueKey('message-bubble-incoming')),
    );
    final ownCheck = tester.getCenter(
      find.byKey(const ValueKey('message-selection-own')),
    );
    final ownBubble = tester.getCenter(
      find.byKey(const ValueKey('message-bubble-own')),
    );
    expect(incomingCheck.dx, greaterThan(incomingBubble.dx));
    expect(ownCheck.dx, lessThan(ownBubble.dx));
  });

  testWidgets(
    'own bubbles pack to content and grouped avatar sits at block end',
    (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 600,
            child: CarpenterMessageTimeline(
              messages: [
                _message('first', DateTime(2026, 9, 24, 10)),
                _message('second', DateTime(2026, 9, 24, 10, 1)),
                CarpenterMessageView(
                  id: 'own-short',
                  authorId: 'me',
                  authorLabel: 'Вы',
                  body: 'Да',
                  own: true,
                  sentAt: DateTime(2026, 9, 24, 10, 2),
                ),
              ],
              selectedIds: const {},
              groupChat: true,
            ),
          ),
        ),
      );

      final ownWidth = tester
          .getSize(find.byKey(const ValueKey('message-bubble-own-short')))
          .width;
      expect(ownWidth, lessThan(300));
      final first = tester.getRect(
        find.byKey(const ValueKey('message-bubble-first')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('message-bubble-second')),
      );
      final own = tester.getRect(
        find.byKey(const ValueKey('message-bubble-own-short')),
      );
      final timeline = tester.getRect(find.byType(CarpenterMessageTimeline));
      expect(first.left, closeTo(second.left, 1));
      expect(timeline.right - own.right, lessThanOrEqualTo(20));
      final avatarBottom = tester
          .getBottomLeft(find.byType(CarpenterConversationAvatar))
          .dy;
      final secondBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('message-bubble-second')))
          .dy;
      expect((avatarBottom - secondBottom).abs(), lessThanOrEqualTo(2));
    },
  );

  testWidgets('message bubble supports intrinsic-height collection rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 600,
          child: IntrinsicHeight(
            child: CarpenterMessageBubble(
              message: _message('intrinsic', DateTime(2026, 9, 24, 10)),
              selected: false,
              selectionMode: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('message-bubble-intrinsic')),
      findsOneWidget,
    );
  });

  testWidgets('a single attachment is the bubble instead of nesting in one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 700,
          child: CarpenterMessageBubble(
            message: CarpenterMessageView(
              id: 'media-only',
              authorId: 'me',
              authorLabel: 'Вы',
              body: '',
              own: true,
              sentAt: DateTime(2026, 9, 30, 18, 37),
              media: const [
                CarpenterMediaView(
                  id: 'portrait',
                  kind: CarpenterMediaKind.image,
                  label: 'Фото',
                  byteLength: 1,
                  loadState: CarpenterMediaLoadState.ready,
                  pixelWidth: 900,
                  pixelHeight: 1600,
                ),
              ],
            ),
            selected: false,
            selectionMode: false,
            showAuthor: false,
          ),
        ),
      ),
    );

    final bubble = tester.getRect(
      find.byKey(const ValueKey('message-bubble-media-only')),
    );
    final media = tester.getRect(
      find.byKey(const ValueKey('message-media-portrait')),
    );
    expect(bubble.width, closeTo(media.width, 1));
    expect(bubble.height, closeTo(media.height, 1));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('message-bubble-media-only')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.border, isNull);
  });

  testWidgets('timeline reports the message id with an invoked link', (
    tester,
  ) async {
    (String, Uri)? invoked;
    await tester.pumpWidget(
      _host(
        CarpenterMessageTimeline(
          messages: [
            CarpenterMessageView(
              id: 'linked-message',
              authorId: 'anna',
              authorLabel: 'Анна',
              body: 'https://example.com',
              own: false,
              sentAt: DateTime(2026, 9, 29, 10),
            ),
          ],
          selectedIds: const {},
          groupChat: false,
          onLinkInvoked: (messageId, link) => invoked = (messageId, link),
        ),
      ),
    );

    await tester.tap(find.text('https://example.com'));

    expect(invoked, ('linked-message', Uri.parse('https://example.com')));
  });

  testWidgets(
    'selection tints each directional surface without flattening their identity',
    (tester) async {
      final sentAt = DateTime(2026, 9, 24, 10);
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final entry in const [
                (id: 'incoming-rest', own: false, selected: false),
                (id: 'incoming-selected', own: false, selected: true),
                (id: 'own-rest', own: true, selected: false),
                (id: 'own-selected', own: true, selected: true),
              ])
                CarpenterMessageBubble(
                  message: CarpenterMessageView(
                    id: entry.id,
                    authorId: entry.own ? 'me' : 'anna',
                    authorLabel: entry.own ? 'Вы' : 'Анна',
                    body: entry.id,
                    own: entry.own,
                    sentAt: sentAt,
                  ),
                  selected: entry.selected,
                  selectionMode: entry.selected,
                  onSelectionChanged: (_) {},
                ),
            ],
          ),
        ),
      );

      Color color(String id) =>
          (tester
                      .widget<DecoratedBox>(
                        find.byKey(ValueKey('message-bubble-$id')),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      expect(color('incoming-rest'), isNot(color('own-rest')));
      expect(color('incoming-selected'), isNot(color('incoming-rest')));
      expect(color('own-selected'), isNot(color('own-rest')));
      expect(color('incoming-selected'), isNot(color('own-selected')));
      expect(
        color('incoming-selected'),
        isNot(CarpenterThemeData.light().overlay.selected),
      );
    },
  );

  testWidgets('selection control hugs the opposite bubble edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarpenterMessageBubble(
          message: CarpenterMessageView(
            id: 'incoming-selected',
            authorId: 'anna',
            authorLabel: 'Анна',
            body: 'Проверьте',
            own: false,
            sentAt: DateTime(2026, 9, 24, 10),
          ),
          selected: true,
          selectionMode: true,
          onSelectionChanged: (_) {},
        ),
      ),
    );

    final bubble = tester.getRect(
      find.byKey(const ValueKey('message-bubble-incoming-selected')),
    );
    final selection = tester.getRect(
      find.byKey(const ValueKey('message-selection-incoming-selected')),
    );
    expect(selection.left - bubble.right, lessThanOrEqualTo(4));
  });
}

CarpenterMessageView _message(String id, DateTime sentAt) =>
    CarpenterMessageView(
      id: id,
      authorId: 'anna',
      authorLabel: 'Анна',
      body: id,
      own: false,
      sentAt: sentAt,
    );

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
