import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/messenger/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';

Finder get composerInput => find.descendant(
  of: find.byType(CarpenterMessageComposer),
  matching: find.byType(EditableText),
);
Finder get searchInput => find.descendant(
  of: find.byType(CarpenterInput),
  matching: find.byType(EditableText),
);

Widget host(Widget child, {bool dark = false, double scale = 1}) => WidgetsApp(
  debugShowCheckedModeBanner: false,
  color: const Color(0xffeeeeee),
  builder: (context, _) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: (dark ? CarpenterThemeData.dark() : CarpenterThemeData.light())
          .copyWith(
            typography: const CarpenterTypographyTheme(fontFamily: 'Onest'),
          ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Overlay(
          key: ObjectKey(child),
          initialEntries: [OverlayEntry(builder: (_) => child)],
        ),
      ),
    ),
  ),
);
void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (name: 'wide', size: const Size(1280, 800), dark: false, scale: 1.0),
    (name: 'narrow', size: const Size(390, 844), dark: false, scale: 1.0),
    (
      name: 'dark_large_text',
      size: const Size(768, 1024),
      dark: true,
      scale: 2.0,
    ),
  ]) {
    testWidgets('messenger ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const MessengerScenario(showFailure: true),
          dark: variant.dark,
          scale: variant.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CarpenterMessengerWorkspace),
        matchesGoldenFile('images/messenger_${variant.name}.png'),
      );
    });
  }
  testWidgets('reply quote can be cancelled and sent on narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const MessengerScenario()));
    await tester.pumpAndSettle();
    await tester.enterText(composerInput, 'Проверю раздел сегодня');
    Future<void> reply() async {
      await tester.longPress(find.text('Проверю сегодня. Ответ напишу здесь.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ответить'));
      await tester.pumpAndSettle();
    }

    await reply();
    expect(
      tester
          .widget<CarpenterMessageComposer>(
            find.byType(CarpenterMessageComposer),
          )
          .replyPreview,
      contains('Ответ напишу здесь'),
    );
    await expectLater(
      find.byType(CarpenterMessengerWorkspace),
      matchesGoldenFile('images/messenger_reply.png'),
    );
    await tester.tap(find.bySemanticsLabel('Отменить ответ'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Проверю раздел сегодня',
    );
    expect(
      tester
          .widget<CarpenterMessageComposer>(
            find.byType(CarpenterMessageComposer),
          )
          .replyPreview,
      isNull,
    );
    await reply();
    await tester.tap(composerInput);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final bubble = tester
        .widgetList<CarpenterMessageBubble>(find.byType(CarpenterMessageBubble))
        .singleWhere((b) => b.message.text == 'Проверю раздел сегодня');
    expect(bubble.message.replyPreview, contains('Ответ напишу здесь'));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'distant reply reanchors lazy history and returns without losing draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(const MessengerScenario(distantReply: true)),
      );
      await tester.pumpAndSettle();
      const original =
          'Коллеги, проверьте состав документации перед передачей заказчику.';
      expect(find.text(original), findsNothing);
      await tester.enterText(composerInput, 'Не потерять черновик');
      await tester.tap(find.bySemanticsLabel('Перейти к исходному сообщению'));
      await tester.pumpAndSettle();
      expect(find.text(original).hitTestable(), findsOneWidget);
      expect(find.text('Исходное сообщение'), findsOneWidget);
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Не потерять черновик',
      );
      await expectLater(
        find.byType(CarpenterMessengerWorkspace),
        matchesGoldenFile('images/messenger_reply_original.png'),
      );
      await tester.drag(
        find.byType(CustomScrollView).last,
        const Offset(0, -420),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Обсуждение раздела').hitTestable(),
        findsWidgets,
      );
      await tester.tap(find.text('К последним сообщениям'));
      await tester.pumpAndSettle();
      expect(
        find.text('Возвращаюсь к первому вопросу.').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Исходное сообщение'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing reply original reports unavailable and leaves draft intact',
    (tester) async {
      final messages = <CarpenterMessageItem>[
        const CarpenterMessageItem(
          id: 'reply',
          author: 'Анна',
          text: 'Ответ',
          status: '',
          replyPreview: 'Недоступный оригинал',
          replyTargetId: 'missing',
        ),
      ];
      await tester.pumpWidget(
        host(
          CarpenterMessengerWorkspace(
            conversations: const [
              CarpenterConversationItem(
                id: 'room',
                title: 'Разговор',
                subtitle: '',
              ),
            ],
            selectedId: 'room',
            messages: messages,
            draft: 'Черновик',
            needAnswer: false,
            onSelected: (_) {},
            onDraftChanged: (_) {},
            onNeedAnswerChanged: (_) {},
            onSend: () {},
            onRetry: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Перейти к исходному сообщению'));
      await tester.pumpAndSettle();
      expect(
        find.text('Исходное сообщение не загружено или недоступно.'),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Черновик',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('host loads missing original then quote opens it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MessengerScenario(missingOriginal: true)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(composerInput, 'Черновик');
    await tester.tap(find.bySemanticsLabel('Перейти к исходному сообщению'));
    await tester.pumpAndSettle();
    expect(find.text('Оригинал загружен.'), findsNothing);

    expect(find.text('Восстановленный оригинал').hitTestable(), findsOneWidget);
    expect(find.text('Исходное сообщение'), findsOneWidget);
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Черновик',
    );
    expect(tester.takeException(), isNull);
  });
  for (final cancellation in ['button', 'scroll', 'room', 'failure']) {
    testWidgets(
      'late original does not navigate after $cancellation cancellation',
      (tester) async {
        late StateSetter rebuild;
        var loaded = false;
        var failed = false;
        var room = 'project';
        var requests = 0;
        final cancelled = <String>[];
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return CarpenterMessengerWorkspace(
                  conversations: const [
                    CarpenterConversationItem(
                      id: 'project',
                      title: 'Проект',
                      subtitle: '',
                    ),
                    CarpenterConversationItem(
                      id: 'anna',
                      title: 'Анна',
                      subtitle: '',
                    ),
                  ],
                  failedReplyMessageId: failed ? 'quote' : null,
                  selectedId: room,
                  messages: [
                    if (loaded)
                      const CarpenterMessageItem(
                        id: 'original',
                        author: 'Анна',
                        text: 'Оригинал',
                        status: '',
                      ),
                    CarpenterMessageItem(
                      id: 'quote',
                      author: 'Вы',
                      text: 'Ответ',
                      status: '',
                      replyPreview: 'Цитата',
                      replyTargetId: loaded ? 'original' : null,
                    ),
                  ],
                  draft: 'Черновик',
                  needAnswer: false,
                  onSelected: (value) => setState(() => room = value!),
                  onDraftChanged: (_) {},
                  onNeedAnswerChanged: (_) {},
                  onSend: () {},
                  onRetry: (_) {},
                  onCancelReplyLookup: cancelled.add,
                  onUnavailableReply: (_) => requests++,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel('Перейти к исходному сообщению'),
        );
        await tester.pumpAndSettle();
        expect(requests, 1);
        expect(find.text('Отменить переход'), findsOneWidget);
        if (cancellation == 'button') {
          await tester.tap(find.text('Отменить переход'));
        } else if (cancellation == 'failure') {
          rebuild(() => failed = true);
        } else if (cancellation == 'scroll') {
          await tester.drag(
            find.byType(CustomScrollView).last,
            const Offset(0, 150),
          );
        } else {
          rebuild(() => room = 'anna');
          await tester.pumpAndSettle();
          rebuild(() => room = 'project');
        }
        await tester.pumpAndSettle();
        expect(
          cancelled,
          cancellation == 'button' || cancellation == 'scroll'
              ? ['quote']
              : isEmpty,
        );
        rebuild(() => loaded = true);
        await tester.pumpAndSettle();
        expect(find.text('Исходное сообщение'), findsNothing);
        expect(find.text('К последним сообщениям'), findsNothing);
        expect(
          tester.widget<EditableText>(composerInput).controller.text,
          'Черновик',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('draft survives switching and Enter sends once', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const MessengerScenario()));
    await tester.pumpAndSettle();
    await tester.enterText(composerInput, 'Новый ответ');
    await tester.tap(find.text('Анна Смирнова').first);
    await tester.pumpAndSettle();
    expect(composerInput, findsOneWidget);
    expect(tester.widget<EditableText>(composerInput).controller.text, isEmpty);
    await tester.tap(find.text('Северный парк').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Новый ответ',
    );
    await tester.tap(composerInput);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Новый ответ'), findsOneWidget);
    expect(tester.widget<EditableText>(composerInput).controller.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Shift Enter and IME composition do not send', (tester) async {
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
    await tester.enterText(composerInput, 'Черновик');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(sends, 0);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Черновик',
        selection: TextSelection.collapsed(offset: 8),
        composing: TextRange(start: 0, end: 8),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sends, 0);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Черновик',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sends, 1);
  });
  testWidgets('narrow back preserves draft and failed fixture retries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const MessengerScenario(showFailure: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Не отправлено'), findsNothing);
    await tester.enterText(composerInput, 'Не потерять');
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CarpenterIconButton && w.semanticLabel == 'К разговорам',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Северный парк').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Не потерять',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'text-scale policy is opt-in and keeps default width classification',
    (tester) async {
      late CarpenterViewportClass normal;
      late CarpenterViewportClass accessible;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              normal = const CarpenterViewportPolicy().resolve(context, 768);
              accessible = const CarpenterViewportPolicy(
                accountForTextScale: true,
              ).resolve(context, 768);
              return const SizedBox.shrink();
            },
          ),
          scale: 2,
        ),
      );
      expect(normal, isNot(CarpenterViewportClass.narrow));
      expect(accessible, CarpenterViewportClass.narrow);
    },
  );
  testWidgets('history failure is recoverable without losing draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(const MessengerScenario(historyFailure: true, hasOlder: true)),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CarpenterMessengerWorkspace),
      matchesGoldenFile('images/messenger_history_failure.png'),
    );
    await tester.enterText(composerInput, 'Мой черновик');
    final anchor = tester.getTopLeft(
      find.text('Проверю сегодня. Ответ напишу здесь.'),
    );
    await tester.tap(find.text('Повторить загрузку'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить историю.'), findsNothing);
    expect(
      tester.widget<EditableText>(composerInput).controller.text,
      'Мой черновик',
    );
    expect(
      tester.getTopLeft(find.text('Проверю сегодня. Ответ напишу здесь.')),
      anchor,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'loading empty history does not claim the conversation is empty',
    (tester) async {
      await tester.pumpWidget(
        host(
          const MessengerScenario(initialRoom: 'anna', historyLoading: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Начните разговор'), findsNothing);
      expect(find.text('Загружаем сообщения…'), findsOneWidget);
      await tester.enterText(composerInput, 'Можно писать');
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Можно писать',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'grouped messages keep one author label and a readable workspace',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(const MessengerScenario(groupedMessages: true)),
      );
      await tester.pumpAndSettle();
      final bubbles = tester
          .widgetList<CarpenterMessageBubble>(
            find.byType(CarpenterMessageBubble),
          )
          .toList();
      expect(
        bubbles
            .singleWhere((b) => b.message.id == 'continuation')
            .groupWithPrevious,
        isTrue,
      );
      expect(
        bubbles.singleWhere((b) => b.message.id == 'two').groupWithPrevious,
        isFalse,
      );
      await expectLater(
        find.byType(CarpenterMessengerWorkspace),
        matchesGoldenFile('images/messenger_grouped.png'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'matching names never group different identities or different dates',
    (tester) async {
      final entries = [
        CarpenterMessageItem(
          id: 'a',
          author: 'Анна',
          authorKey: 'one',
          text: 'Первое',
          status: '',
          sentAt: DateTime(2026, 9, 11, 23, 58),
        ),
        CarpenterMessageItem(
          id: 'b',
          author: 'Анна',
          authorKey: 'two',
          text: 'Другая Анна',
          status: '',
          sentAt: DateTime(2026, 9, 11, 23, 59),
        ),
        CarpenterMessageItem(
          id: 'c',
          author: 'Анна',
          authorKey: 'two',
          text: 'На следующий день',
          status: '',
          sentAt: DateTime(2026, 9, 12, 0, 1),
        ),
      ];
      await tester.pumpWidget(
        host(
          CarpenterMessengerWorkspace(
            conversations: const [
              CarpenterConversationItem(
                id: 'room',
                title: 'Разговор',
                subtitle: 'Группа',
              ),
            ],
            selectedId: 'room',
            messages: entries,
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
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<CarpenterMessageBubble>(
              find.byType(CarpenterMessageBubble),
            )
            .every((b) => !b.groupWithPrevious),
        isTrue,
      );
    },
  );

  testWidgets('message actions copy text and dismiss with Escape', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(host(const MessengerScenario()));
    await tester.pumpAndSettle();
    expect(find.text('Скопировать сообщение'), findsNothing);
    Focus.of(
      tester.element(find.text('Проверю сегодня. Ответ напишу здесь.')),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Скопировать сообщение'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Скопировать сообщение'), findsNothing);
    await tester.tap(
      find.text('Проверю сегодня. Ответ напишу здесь.'),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Скопировать сообщение'));
    await tester.pumpAndSettle();
    expect(copied, 'Проверю сегодня. Ответ напишу здесь.');
    expect(find.text('Скопировать сообщение'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'directory search preserves selected detail and draft while filtering',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const MessengerScenario()));
      await tester.pumpAndSettle();
      await tester.enterText(composerInput, 'Мой черновик');
      await tester.enterText(searchInput, 'несуществующий');
      await tester.pumpAndSettle();
      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.text('Северный парк'), findsOneWidget);
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Мой черновик',
      );
      await expectLater(
        find.byType(CarpenterMessengerWorkspace),
        matchesGoldenFile('images/messenger_search_empty.png'),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is CarpenterIconButton && w.semanticLabel == 'Очистить поиск',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(searchInput).controller.text, isEmpty);
      expect(find.text('Ничего не найдено'), findsNothing);
      expect(find.text('Северный парк'), findsNWidgets(2));
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Мой черновик',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow search filters rooms and Escape clears without losing draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const MessengerScenario()));
      await tester.pumpAndSettle();
      await tester.enterText(composerInput, 'Вернуться к этому');
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is CarpenterIconButton && w.semanticLabel == 'К разговорам',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(searchInput, 'АННА');
      await tester.pumpAndSettle();
      expect(find.text('Анна Смирнова'), findsOneWidget);
      expect(find.text('Северный парк'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(searchInput).controller.text, isEmpty);
      await tester.tap(find.text('Северный парк'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(composerInput).controller.text,
        'Вернуться к этому',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
