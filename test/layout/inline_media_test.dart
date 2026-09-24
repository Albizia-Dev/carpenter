import 'dart:convert';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('playback speeds use the complete supported cycle', () {
    expect(CarpenterPlaybackSpeeds.values, [0.5, 0.75, 1, 1.25, 1.5, 2]);
  });

  testWidgets('image preview is blurred until the original is ready', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: CarpenterMediaView(
            id: 'image',
            kind: CarpenterMediaKind.image,
            label: 'Фото',
            byteLength: carpenterEagerMediaLimitBytes + 1,
            loadState: CarpenterMediaLoadState.previewReady,
            previewBytes: base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          ),
          onLoadRequested: () => loads++,
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Загрузить оригинал: Фото'));
    expect(loads, 1);
  });

  testWidgets(
    'video shows poster duration and audio uses compact external controls',
    (tester) async {
      var plays = 0;
      double? speed;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              CarpenterInlineMedia(
                view: const CarpenterMediaView(
                  id: 'video',
                  kind: CarpenterMediaKind.video,
                  label: 'Видео',
                  byteLength: 1,
                  loadState: CarpenterMediaLoadState.ready,
                  duration: Duration(minutes: 1, seconds: 30),
                ),
                preview: const ColoredBox(color: Color(0xff223344)),
                onPlayPauseRequested: () => plays++,
              ),
              CarpenterInlineMedia(
                view: const CarpenterMediaView(
                  id: 'audio',
                  kind: CarpenterMediaKind.audio,
                  label: 'Аудио',
                  byteLength: 1,
                  loadState: CarpenterMediaLoadState.ready,
                  duration: Duration(seconds: 42),
                  waveform: [2, 8, 4, 10],
                ),
                onPlayPauseRequested: () => plays++,
                onSpeedChanged: (value) => speed = value,
              ),
            ],
          ),
        ),
      );

      expect(find.text('01:30'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('media-waveform-audio')),
        findsOneWidget,
      );
      expect(find.text('−15 с'), findsNothing);
      expect(find.text('+15 с'), findsNothing);
      expect(
        tester.getCenter(find.text('1.0×')).dy,
        greaterThan(
          tester
              .getBottomLeft(find.byKey(const ValueKey('media-waveform-audio')))
              .dy,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Воспроизвести: Аудио'));
      await tester.tap(find.text('1.0×').last);
      expect(plays, 1);
      expect(speed, 1.25);
    },
  );

  testWidgets('video circle has a controlled focused presentation', (
    tester,
  ) async {
    bool? focused;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: const CarpenterMediaView(
            id: 'circle',
            kind: CarpenterMediaKind.videoCircle,
            label: 'Кружок',
            byteLength: 1,
            loadState: CarpenterMediaLoadState.ready,
            focused: true,
          ),
          preview: const ColoredBox(color: Color(0xff334455)),
          onFocusChanged: (value) => focused = value,
        ),
      ),
    );

    expect(find.byType(ClipOval), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('inline-media-circle-circle')))
          .width,
      greaterThan(160),
    );
    await tester.tap(find.bySemanticsLabel('Уменьшить видеосообщение'));
    expect(focused, isFalse);
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
        child: Center(child: child),
      ),
    ),
  ),
);
