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
    final bubble = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('inline-media-bubble-image')),
    );
    expect((bubble.decoration as BoxDecoration).border, isNotNull);
    expect(bubble.position, DecorationPosition.foreground);
    final action = find.bySemanticsLabel('Загрузить: Фото');
    expect(action, findsWidgets);
    expect(
      tester.getCenter(action.last).dx,
      closeTo(tester.getCenter(find.byType(ImageFiltered)).dx, 1),
    );
    await tester.tap(action.last);
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
        tester.getCenter(find.text('1×')).dy,
        greaterThan(
          tester
              .getBottomLeft(find.byKey(const ValueKey('media-waveform-audio')))
              .dy,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Воспроизвести: Аудио'));
      await tester.tap(find.text('1×').last);
      expect(plays, 1);
      expect(speed, 1.25);
    },
  );

  testWidgets(
    'video circle stays inline and delegates playback without a popover',
    (tester) async {
      var focused = false;
      var plays = 0;
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => CarpenterInlineMedia(
              view: CarpenterMediaView(
                id: 'circle',
                kind: CarpenterMediaKind.videoCircle,
                label: 'Кружок',
                byteLength: 1,
                loadState: CarpenterMediaLoadState.ready,
                focused: focused,
                duration: const Duration(seconds: 20),
                position: const Duration(seconds: 5),
                previewBytes: base64Decode(
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                ),
              ),
              expandedPreview: const SizedBox(
                key: ValueKey('circle-player'),
                width: 320,
                height: 240,
              ),
              onPlayPauseRequested: () => setState(() {
                plays++;
              }),
              onSeekRequested: seeks.add,
              onFocusChanged: (value) => setState(() => focused = value),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
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
      expect(
        find.bySemanticsLabel(RegExp(r'^Воспроизвести: Кружок')),
        findsOneWidget,
      );
      final circle = find.byKey(const ValueKey('inline-media-circle-circle'));
      final rect = tester.getRect(circle);
      await tester.tapAt(Offset(rect.left + 4, rect.center.dy));
      await tester.pumpAndSettle();
      expect(plays, 1);
      expect(focused, isFalse);
      expect(find.byKey(const ValueKey('circle-player')), findsNothing);

      final gesture = await tester.startGesture(rect.topCenter);
      await gesture.moveTo(rect.centerRight);
      await gesture.up();
      expect(seeks.last, const Duration(seconds: 5));
    },
  );

  testWidgets('video circle loads through its play affordance', (tester) async {
    var loads = 0;
    var plays = 0;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: CarpenterMediaView(
            id: 'circle-preview',
            kind: CarpenterMediaKind.videoCircle,
            label: 'Кружок',
            byteLength: carpenterEagerMediaLimitBytes + 1,
            loadState: CarpenterMediaLoadState.previewReady,
            duration: const Duration(seconds: 20),
            previewBytes: base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          ),
          onLoadRequested: () => loads++,
          onPlayPauseRequested: () => plays++,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Загрузить: Кружок'), findsNothing);
    final play = find.bySemanticsLabel(
      RegExp(r'^Загрузить и воспроизвести: Кружок'),
    );
    expect(play, findsOneWidget);
    await tester.tap(play);
    expect(loads, 1);
    expect(plays, 0);
  });

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

  testWidgets('missing waveform renders an honest seek timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarpenterInlineMedia(
          view: CarpenterMediaView(
            id: 'legacy-audio',
            kind: CarpenterMediaKind.audio,
            label: 'Запись.webm',
            byteLength: 1,
            loadState: CarpenterMediaLoadState.ready,
            duration: Duration(seconds: 17),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('media-timeline-legacy-audio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('media-waveform-legacy-audio')),
      findsNothing,
    );
  });

  testWidgets('visual media preserves metadata ratio and opens immersive', (
    tester,
  ) async {
    var focused = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CarpenterInlineMedia(
            view: CarpenterMediaView(
              id: 'portrait',
              kind: CarpenterMediaKind.image,
              label: 'Портрет.jpg',
              byteLength: 1,
              loadState: CarpenterMediaLoadState.ready,
              pixelWidth: 900,
              pixelHeight: 1600,
              focused: focused,
            ),
            preview: const ColoredBox(color: Color(0xff223344)),
            expandedPreview: const ColoredBox(
              key: ValueKey('expanded-portrait'),
              color: Color(0xff556677),
            ),
            onFocusChanged: (value) => setState(() => focused = value),
          ),
        ),
      ),
    );

    final ratio = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('inline-media-aspect-portrait')),
    );
    expect(ratio.aspectRatio, closeTo(900 / 1600, .001));
    await tester.tap(find.bySemanticsLabel('Открыть Портрет.jpg'));
    await tester.pumpAndSettle();
    expect(focused, isTrue);
    expect(find.byKey(const ValueKey('expanded-portrait')), findsOneWidget);
    expect(find.byType(CarpenterDialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      tester.getSize(find.byType(InteractiveViewer)).height,
      greaterThan(500),
    );
    expect(find.bySemanticsLabel('Закрыть просмотр'), findsOneWidget);
  });

  testWidgets('file preview exposes metadata and opens as one action', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: const CarpenterMediaView(
            id: 'file',
            kind: CarpenterMediaKind.file,
            label: 'Смета.pdf',
            byteLength: 2048,
            loadState: CarpenterMediaLoadState.ready,
          ),
          onLoadRequested: () => opens++,
        ),
      ),
    );

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('2 КБ'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Открыть Смета.pdf'));
    expect(opens, 1);
  });

  testWidgets('downloading file reserves action space and shows progress', (
    tester,
  ) async {
    const label =
        'Очень длинное название проектной документации и приложений.pdf';
    await tester.pumpWidget(
      _host(
        CarpenterInlineMedia(
          view: const CarpenterMediaView(
            id: 'downloading-file',
            kind: CarpenterMediaKind.file,
            label: label,
            byteLength: carpenterEagerMediaLimitBytes + 1,
            loadState: CarpenterMediaLoadState.originalLoading,
            transferPhase: CarpenterMediaTransferPhase.downloading,
            transferProgress: .42,
          ),
        ),
      ),
    );

    expect(find.text('Скачиваем · 42%'), findsOneWidget);
    final progress = tester.widget<CarpenterProgress>(
      find.descendant(
        of: find.byKey(
          const ValueKey('media-transfer-status-downloading-file'),
        ),
        matching: find.byType(CarpenterProgress),
      ),
    );
    expect(progress.value, .42);
    final nameRect = tester.getRect(find.text(label));
    final actionRect = tester.getRect(
      find.bySemanticsLabel('Скачивание: $label'),
    );
    expect(nameRect.right, lessThanOrEqualTo(actionRect.left));
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
    expect(loader.semanticLabel, 'Загрузка: Фото');
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
