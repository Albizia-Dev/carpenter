import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/messenger/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';
import 'messenger_workspace_test.dart' show host, composerInput;

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (name: 'wide', size: const Size(1280, 800), dark: false, scale: 1.0),
    (name: 'narrow_dark', size: const Size(390, 844), dark: true, scale: 2.0),
  ]) {
    testWidgets('file message and draft ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const AttachmentMessageScenario(),
          dark: variant.dark,
          scale: variant.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(CarpenterMessageComposer)).bottom,
        closeTo(variant.size.height, 1),
      );
      await expectLater(
        find.byType(CarpenterMessengerWorkspace),
        matchesGoldenFile('message_attachments_${variant.name}.png'),
      );
    });
  }
  testWidgets('captionless keyboard send and retry retain the file', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AttachmentMessageScenario()));
    await tester.pumpAndSettle();
    await tester.tap(composerInput);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterAttachmentTray), findsNothing);
    expect(find.text('Спецификация оборудования.pdf · 540 КБ'), findsOneWidget);
    expect(find.text('Нет подтверждения'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Отправлено'), findsOneWidget);
    expect(find.text('Спецификация оборудования.pdf · 540 КБ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('remove by keyboard preserves caption and answer', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AttachmentMessageScenario()));
    await tester.pumpAndSettle();
    await tester.enterText(composerInput, 'Только подпись');
    await tester.tap(find.text('Нужен ответ'));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Убрать'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterAttachmentTray), findsNothing);
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Только подпись',
    );
    expect(
      tester
          .widget<CarpenterMessageComposer>(
            find.byType(CarpenterMessageComposer),
          )
          .needAnswer,
      isTrue,
    );
    await tester.tap(composerInput);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Спецификация оборудования.pdf · 540 КБ'), findsNothing);
    expect(find.text('Только подпись'), findsWidgets);
  });
  testWidgets('failed and cancelled files expose distinct remove actions', (
    tester,
  ) async {
    final removed = <String>[];
    await tester.pumpWidget(
      host(
        CarpenterAttachmentTray(
          items: const [
            CarpenterAttachmentItem(
              id: 'failed',
              name: 'Смета.pdf',
              phase: CarpenterMessengerUploadPhase.failed,
              detail: 'Нет подтверждения',
            ),
            CarpenterAttachmentItem(
              id: 'cancelled',
              name: 'План.pdf',
              phase: CarpenterMessengerUploadPhase.cancelled,
              detail: '',
            ),
          ],
          onRetry: (_) {},
          onRemove: removed.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Убрать'), findsNWidgets(2));
    await tester.tap(find.text('Убрать').last);
    expect(removed, ['cancelled']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty composer without files still cannot send', (tester) async {
    var sends = 0;
    await tester.pumpWidget(
      host(
        CarpenterMessageComposer(
          text: '',
          needAnswer: false,
          onTextChanged: (_) {},
          onNeedAnswerChanged: (_) {},
          onSend: () => sends++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(composerInput);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sends, 0);
  });
}
