import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message attachment reports its stable id by pointer', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _harness(
        CarpenterMessageBubble(
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
        CarpenterMessageBubble(
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
        const CarpenterMessageBubble(
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
