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
                loadState: CarpenterMediaLoadState.originalLoading,
                transferPhase: CarpenterMediaTransferPhase.uploading,
                transferProgress: .62,
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
    expect(find.text('Отправляем · 62%'), findsOneWidget);
    expect(
      tester.widget<CarpenterProgress>(find.byType(CarpenterProgress)).value,
      .62,
    );
    await tester.tap(find.bySemanticsLabel('Отправить'));
    expect(sends, [CarpenterSendMode.ordinary]);
  });

  testWidgets('long press exposes important and answer modes without a split', (
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

    expect(find.byType(CarpenterIconButton), findsNWidgets(2));
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

  testWidgets('composer focus belongs to the complete input surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(text: 'Текст'),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onTextChanged: (_) {},
          onSendRequested: (_) {},
          onAttachmentsRequested: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Сообщение'));
    await tester.pump();

    final attachCenter = tester.getCenter(
      find.bySemanticsLabel('Прикрепить файлы'),
    );
    final sendCenter = tester.getCenter(find.bySemanticsLabel('Отправить'));
    expect((attachCenter.dy - sendCenter.dy).abs(), lessThanOrEqualTo(2));
    expect(
      find.byKey(const ValueKey('composer-input-surface')),
      findsOneWidget,
    );
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
