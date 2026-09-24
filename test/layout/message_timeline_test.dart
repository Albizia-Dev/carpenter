import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      final avatarBottom = tester
          .getBottomLeft(find.byType(CarpenterConversationAvatar))
          .dy;
      final secondBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('message-bubble-second')))
          .dy;
      expect((avatarBottom - secondBottom).abs(), lessThanOrEqualTo(2));
    },
  );
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
