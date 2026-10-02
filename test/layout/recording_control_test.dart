import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('focused recording supports keyboard capture without hold', (
    tester,
  ) async {
    final events = <String>[];
    final focus = FocusNode();
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          focusNode: focus,
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onStart: (_) => events.add('start'),
          onLock: (_) => events.add('lock'),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(events, ['start', 'lock']);
    await tester.pumpWidget(const SizedBox.shrink());
    focus.dispose();
  });

  testWidgets('uploading preview disables send and destructive recovery', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.preview,
            busy: true,
          ),
          onSend: (_) => events.add('send'),
          onCancel: (_) => events.add('cancel'),
        ),
      ),
    );
    final actions = tester.widgetList<CarpenterIconButton>(
      find.byType(CarpenterIconButton),
    );
    expect(actions.every((action) => action.onPressed == null), isTrue);
    expect(events, isEmpty);
  });

  testWidgets('pointer cancellation discards capture without preparing send', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onStart: (_) => events.add('start'),
          onStop: (_) => events.add('stop'),
          onCancel: (_) => events.add('cancel'),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarpenterRecordingControl)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await gesture.cancel();
    expect(events, ['start', 'cancel']);
  });

  testWidgets('preview requires explicit send and exposes recovery actions', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.preview,
            duration: Duration(seconds: 12),
          ),
          onPreview: (_) => events.add('preview'),
          onSend: (_) => events.add('send'),
          onRerecord: (_) => events.add('rerecord'),
          onCancel: (_) => events.add('cancel'),
          onStop: (_) => events.add('stop'),
        ),
      ),
    );
    expect(events, isEmpty);
    await tester.tap(find.bySemanticsLabel('Прослушать запись'));
    expect(events, ['preview']);
    await tester.tap(find.bySemanticsLabel('Отправить запись'));
    expect(events, ['preview', 'send']);
    expect(find.bySemanticsLabel('Завершить запись'), findsNothing);
    expect(find.bySemanticsLabel('Записать заново'), findsOneWidget);
  });

  testWidgets('tap switches mode and hold starts then locks recording', (
    tester,
  ) async {
    final modes = <CarpenterRecordingKind>[];
    final events = <String>[];
    const recordKey = ValueKey('recording-control');
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          key: recordKey,
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onModeChanged: modes.add,
          onStart: (kind) => events.add('start:${kind.name}'),
          onLock: (kind) => events.add('lock:${kind.name}'),
          onStop: (kind) => events.add('stop:${kind.name}'),
        ),
      ),
    );

    await tester.tap(find.byKey(recordKey));
    expect(modes, [CarpenterRecordingKind.video]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(recordKey)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    expect(events, contains('start:voice'));
    await gesture.moveBy(const Offset(0, -80));
    expect(events, contains('lock:voice'));
    await gesture.up();
    expect(events, isNot(contains('stop:voice')));
  });

  testWidgets('unavailable video mode is not offered', (tester) async {
    final modes = <CarpenterRecordingKind>[];
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
            videoAvailable: false,
          ),
          onModeChanged: modes.add,
          onStart: (_) {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Записать видеосообщение'), findsNothing);
    await tester.tap(find.byType(CarpenterRecordingControl));
    expect(modes, isEmpty);
  });

  testWidgets('slide left cancels a held recording without sending it', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        CarpenterRecordingControl(
          view: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onStart: (_) => events.add('start'),
          onStop: (_) => events.add('stop'),
          onCancel: (_) => events.add('cancel'),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarpenterRecordingControl)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await gesture.moveBy(const Offset(-80, 0));
    await gesture.up();

    expect(events, ['start', 'cancel']);
  });

  testWidgets('drag lock is an icon state without visible status prose', (
    tester,
  ) async {
    var phase = CarpenterRecordingPhase.idle;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterRecordingControl(
              view: CarpenterRecordingView(
                kind: CarpenterRecordingKind.voice,
                phase: phase,
              ),
              onStart: (_) =>
                  update(() => phase = CarpenterRecordingPhase.recording),
              onLock: (_) =>
                  update(() => phase = CarpenterRecordingPhase.locked),
              onStop: (_) {},
            );
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarpenterRecordingControl)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('recording-lock-indicator')),
      findsOneWidget,
    );
    expect(find.text('Запись закреплена'), findsNothing);
    expect(find.text('Идёт запись'), findsNothing);
    await gesture.up();
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
