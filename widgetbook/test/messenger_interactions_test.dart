import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('message menu, swipe and selection callbacks stay interactive', (
    tester,
  ) async {
    var selected = false;
    var replies = 0;
    await tester.pumpWidget(
      _host(
        CarpenterMessageBubble(
          message: CarpenterMessageView(
            id: 'message',
            authorId: 'anna',
            authorLabel: 'Анна',
            body: 'Проверьте',
            own: false,
            sentAt: DateTime(2026, 9, 24, 10),
          ),
          selected: false,
          selectionMode: false,
          onSelectionChanged: (value) => selected = value,
          onReplyRequested: () => replies++,
        ),
      ),
    );
    await tester.longPress(find.text('Проверьте'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    await tester.drag(
      find.byKey(const ValueKey('message-bubble-message')),
      const Offset(-96, 0),
    );
    expect(replies, 1);
  });

  testWidgets('recording hold locks and media focus toggles', (tester) async {
    final events = <String>[];
    var focused = false;
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterRecordingControl(
              view: const CarpenterRecordingView(
                kind: CarpenterRecordingKind.voice,
                phase: CarpenterRecordingPhase.idle,
              ),
              onStart: (_) => events.add('start'),
              onLock: (_) => events.add('lock'),
              onStop: (_) => events.add('stop'),
            ),
            CarpenterInlineMedia(
              view: const CarpenterMediaView(
                id: 'circle',
                kind: CarpenterMediaKind.videoCircle,
                label: 'Кружок',
                byteLength: 1,
                loadState: CarpenterMediaLoadState.ready,
              ),
              onFocusChanged: (value) => focused = value,
            ),
          ],
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarpenterRecordingControl)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await gesture.moveBy(const Offset(0, -80));
    await gesture.up();
    expect(events, containsAllInOrder(['start', 'lock']));
    expect(events, isNot(contains('stop')));
    await tester.tap(find.byKey(const ValueKey('inline-media-circle-circle')));
    expect(focused, isTrue);
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
              OverlayEntry(builder: (_) => Center(child: child)),
            ],
          ),
        ),
      ),
    ),
  ),
);
