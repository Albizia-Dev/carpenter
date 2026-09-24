import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('composer grows to four lines and sends attachment-only draft', (
    tester,
  ) async {
    final sends = <CarpenterSendMode>[];
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(
            text: '',
            attachments: [
              CarpenterMediaView(
                id: 'photo',
                kind: CarpenterMediaKind.image,
                label: 'Фото.jpg',
                byteLength: 1024,
                loadState: CarpenterMediaLoadState.ready,
              ),
            ],
          ),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onTextChanged: (_) {},
          onSendRequested: sends.add,
        ),
      ),
    );

    expect(
      tester.widget<CarpenterTextArea>(find.byType(CarpenterTextArea)).maxLines,
      4,
    );
    await tester.tap(find.bySemanticsLabel('Отправить'));
    expect(sends, [CarpenterSendMode.ordinary]);
  });

  testWidgets('long press exposes working important and answer modes', (
    tester,
  ) async {
    final sends = <CarpenterSendMode>[];
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(text: 'Проверьте'),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onTextChanged: (_) {},
          onSendRequested: sends.add,
        ),
      ),
    );

    await tester.longPress(find.bySemanticsLabel('Отправить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Важное'));
    expect(sends, [CarpenterSendMode.important]);
  });

  testWidgets('read-only state has no active send, attach or record actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(text: '', readOnly: true),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onTextChanged: (_) {},
          onSendRequested: (_) {},
          onAttachmentsRequested: () {},
          onRecordingStart: (_) {},
        ),
      ),
    );

    expect(find.text('В этом чате доступно только чтение.'), findsOneWidget);
    expect(find.bySemanticsLabel('Отправить'), findsNothing);
    expect(find.bySemanticsLabel('Прикрепить файлы'), findsNothing);
    expect(find.byType(CarpenterRecordingControl), findsNothing);
  });

  testWidgets('composer controls form one seamless surface', (tester) async {
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(text: ''),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.recording,
            level: .5,
          ),
          onTextChanged: (_) {},
          onSendRequested: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('composer-input-surface')),
      findsOneWidget,
    );
    final record = tester.getSize(
      find.byKey(const ValueKey('recording-control-button')),
    );
    expect(record.width, greaterThan(record.height));
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
