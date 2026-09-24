import 'dart:convert';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
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

  testWidgets(
    'video circle uses tap playback, focus overlay and perimeter progress',
    (tester) async {
      bool? focused;
      var plays = 0;
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
              duration: Duration(seconds: 20),
              position: Duration(seconds: 5),
            ),
            preview: const ColoredBox(color: Color(0xff334455)),
            onPlayPauseRequested: () => plays++,
            onFocusChanged: (value) => focused = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipOval), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('inline-media-circle-circle')))
            .width,
        greaterThan(160),
      );
      expect(
        find.byKey(const ValueKey('inline-media-circle-progress-circle')),
        findsOneWidget,
      );
      final overlayBackground = CarpenterThemeData.light().overlay.background;
      final framedOverlays = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((box) {
            final decoration = box.decoration;
            return decoration is BoxDecoration &&
                decoration.color == overlayBackground &&
                decoration.border != null;
          });
      expect(framedOverlays, isEmpty);
      expect(find.bySemanticsLabel('Уменьшить видеосообщение'), findsNothing);
      expect(find.bySemanticsLabel('Воспроизвести: Кружок'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('inline-media-circle-circle')).last,
      );
      expect(plays, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(focused, isFalse);
    },
  );

  testWidgets('waveform tap requests an exact playback position', (
    tester,
  ) async {
    Duration? requested;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: const CarpenterMediaView(
            id: 'voice',
            kind: CarpenterMediaKind.voice,
            label: 'Голосовое',
            byteLength: 1,
            loadState: CarpenterMediaLoadState.ready,
            duration: Duration(seconds: 40),
            waveform: [2, 8, 4, 10],
          ),
          onSeekRequested: (position) => requested = position,
        ),
      ),
    );

    final waveform = find.byKey(const ValueKey('media-waveform-voice'));
    final rect = tester.getRect(waveform);
    await tester.tapAt(Offset(rect.left + rect.width * .75, rect.center.dy));
    expect(requested, const Duration(seconds: 30));
  });

  testWidgets('file preview exposes type and byte metadata', (tester) async {
    await tester.pumpWidget(
      _host(
        const CarpenterInlineMedia(
          view: CarpenterMediaView(
            id: 'file',
            kind: CarpenterMediaKind.file,
            label: 'Смета.pdf',
            byteLength: 2048,
            loadState: CarpenterMediaLoadState.ready,
          ),
        ),
      ),
    );

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('2 КБ'), findsOneWidget);
  });

  testWidgets('media load states use compact top-right actions', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: const CarpenterMediaView(
            id: 'failed',
            kind: CarpenterMediaKind.image,
            label: 'Фото',
            byteLength: 2048,
            loadState: CarpenterMediaLoadState.failed,
          ),
          onLoadRequested: () => retries++,
        ),
      ),
    );

    expect(find.textContaining('Не удалось загрузить медиа'), findsNothing);
    expect(find.bySemanticsLabel('Повторить загрузку: Фото'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Повторить загрузку: Фото'));
    expect(retries, 1);

    await tester.pumpWidget(
      _host(
        const CarpenterInlineMedia(
          view: CarpenterMediaView(
            id: 'loading',
            kind: CarpenterMediaKind.image,
            label: 'Фото',
            byteLength: 2048,
            loadState: CarpenterMediaLoadState.originalLoading,
          ),
        ),
      ),
    );
    expect(find.textContaining('Загружаем оригинал'), findsNothing);
    final loader = tester.widget<CarpenterLoader>(find.byType(CarpenterLoader));
    expect(loader.semanticLabel, 'Загрузка оригинала: Фото');
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
        child: Overlay(
          key: UniqueKey(),
          initialEntries: [OverlayEntry(builder: (_) => Center(child: child))],
        ),
      ),
    ),
  ),
);
