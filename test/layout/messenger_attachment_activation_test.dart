import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message bubble renders explicit delivery and edit metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const CarpenterLegacyMessageBubble(
          message: CarpenterMessageItem(
            id: 'own',
            author: 'Вы',
            text: 'Обновлённый текст',
            status: '',
            own: true,
            edited: true,
            delivery: CarpenterMessageDelivery.read,
            timeLabel: '12:30',
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Изменено'), findsOneWidget);
    expect(find.bySemanticsLabel('Прочитано'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
  });

  testWidgets('message menu starts controlled multi selection', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      _harness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterLegacyMessageBubble(
            message: const CarpenterMessageItem(
              id: 'one',
              author: 'Анна',
              text: 'Первое',
              status: '',
            ),
            selecting: selected,
            selected: selected,
            onSelect: () => setState(() => selected = !selected),
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Первое'));
    await tester.pump();
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
  });

  testWidgets('message attachment reports its stable id by pointer', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _harness(
        CarpenterLegacyMessageBubble(
          message: const CarpenterMessageItem(
            id: 'message-7',
            author: 'Анна',
            text: '',
            status: '',
            attachments: [
              CarpenterMessageAttachment(
                id: 'file-42',
                label: 'План работ.pdf · 2 МБ',
              ),
            ],
          ),
          onAttachmentSelected: selected.add,
        ),
      ),
    );

    await tester.tap(
      find.bySemanticsLabel('Открыть файл План работ.pdf · 2 МБ'),
    );

    expect(selected, ['file-42']);
  });

  testWidgets('message attachment uses the keyboard-capable action control', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        CarpenterLegacyMessageBubble(
          message: const CarpenterMessageItem(
            id: 'message-7',
            author: 'Анна',
            text: '',
            status: '',
            attachments: [
              CarpenterMessageAttachment(
                id: 'file-42',
                label: 'План работ.pdf',
              ),
            ],
          ),
          onAttachmentSelected: (_) {},
        ),
      ),
    );

    final attachment = find.bySemanticsLabel('Открыть файл План работ.pdf');
    expect(
      find.ancestor(of: attachment, matching: find.byType(CarpenterButton)),
      findsOneWidget,
    );
  });

  testWidgets('workspace reports message and attachment identities', (
    tester,
  ) async {
    final selected = <(String, String)>[];
    await tester.pumpWidget(
      _harness(
        SizedBox(
          width: 1000,
          height: 700,
          child: CarpenterMessengerWorkspace(
            conversations: const [
              CarpenterConversationItem(
                id: 'room',
                title: 'Документы',
                subtitle: 'Matrix',
              ),
            ],
            selectedId: 'room',
            messages: const [
              CarpenterMessageItem(
                id: 'message-7',
                author: 'Анна',
                text: '',
                status: '',
                attachments: [
                  CarpenterMessageAttachment(
                    id: 'file-42',
                    label: 'План работ.pdf',
                  ),
                ],
              ),
            ],
            draft: '',
            needAnswer: false,
            onSelected: (_) {},
            onDraftChanged: (_) {},
            onNeedAnswerChanged: (_) {},
            onSend: null,
            onRetry: (_) {},
            onMessageAttachmentSelected: (messageId, attachmentId) =>
                selected.add((messageId, attachmentId)),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Открыть файл План работ.pdf'));

    expect(selected, [('message-7', 'file-42')]);
  });

  testWidgets('legacy attachment labels remain display only', (tester) async {
    await tester.pumpWidget(
      _harness(
        const CarpenterLegacyMessageBubble(
          message: CarpenterMessageItem(
            id: 'message-7',
            author: 'Анна',
            text: '',
            status: '',
            attachmentLabels: ['Старый файл.pdf'],
          ),
        ),
      ),
    );

    expect(find.text('Старый файл.pdf'), findsOneWidget);
    expect(find.bySemanticsLabel('Открыть файл Старый файл.pdf'), findsNothing);
  });
}

Widget _harness(Widget child) => UnitsRoot(
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
