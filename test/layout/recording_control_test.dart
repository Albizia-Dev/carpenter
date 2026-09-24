import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

Widget _host(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(child: Center(child: child)),
      ),
    ),
  ),
);
