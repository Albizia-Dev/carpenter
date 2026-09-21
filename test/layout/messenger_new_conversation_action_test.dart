import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('optional new conversation action invokes its host callback', (
    tester,
  ) async {
    var invocations = 0;
    await tester.pumpWidget(
      _harness(_workspace(onNewConversation: () => invocations++)),
    );

    await tester.tap(find.bySemanticsLabel('Новый разговор'));

    expect(invocations, 1);
  });

  testWidgets('new conversation action is absent when callback is null', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(_workspace()));

    expect(find.bySemanticsLabel('Новый разговор'), findsNothing);
  });
}

Widget _workspace({VoidCallback? onNewConversation}) => SizedBox(
  width: 1000,
  height: 700,
  child: CarpenterMessengerWorkspace(
    conversations: const [],
    selectedId: null,
    messages: const [],
    draft: '',
    needAnswer: false,
    onSelected: (_) {},
    onDraftChanged: (_) {},
    onNeedAnswerChanged: (_) {},
    onSend: null,
    onRetry: (_) {},
    onNewConversation: onNewConversation,
  ),
);

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
