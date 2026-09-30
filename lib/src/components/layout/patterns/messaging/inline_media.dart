import 'dart:ui';
import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../../foundation/icon_data.dart';
import '../../../basic/button/button.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/loader.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../behaviour/dialog.dart';
import 'messaging_models.dart';

typedef CarpenterMediaPreviewBuilder =
    Widget? Function(BuildContext context, CarpenterMediaView media);
typedef CarpenterMediaExpandedPreviewBuilder =
    Widget? Function(BuildContext context, CarpenterMediaView media);
typedef CarpenterMediaSeekRequested =
    void Function(String mediaId, Duration position);
typedef CarpenterMediaSpeedChanged =
    void Function(String mediaId, double speed);
typedef CarpenterMediaFocusChanged =
    void Function(String mediaId, bool focused);

/// Supported global playback-rate cycle for audio, voice and video circles.
abstract final class CarpenterPlaybackSpeeds {
  static const values = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

  static double next(double current) {
    final index = values.indexWhere((value) => value > current);
    return index < 0 ? values.first : values[index];
  }
}

/// Controlled inline media chrome. Preview bytes, original loading and decoder
/// state are supplied by the host; Carpenter performs no network or playback.
final class CarpenterInlineMedia extends StatelessWidget {
  const CarpenterInlineMedia({
    super.key,
    required this.view,
    this.preview,
    this.expandedPreview,
    this.onLoadRequested,
    this.onPlayPauseRequested,
    this.onSeekRequested,
    this.onSpeedChanged,
    this.onFocusChanged,
  });

  final CarpenterMediaView view;
  final Widget? preview;
  final Widget? expandedPreview;
  final VoidCallback? onLoadRequested;
  final VoidCallback? onPlayPauseRequested;
  final ValueChanged<Duration>? onSeekRequested;
  final ValueChanged<double>? onSpeedChanged;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final transferStatus = _transferStatus(context);
    if (_isVisual) {
      final action = _visualStateAction(context);
      final media = Stack(
        alignment: Alignment.center,
        children: [_presentation(context), ?action],
      );
      if (view.kind == CarpenterMediaKind.videoCircle) return media;
      final radius = BorderRadius.circular(
        context.units(theme.shapes.radius(ShapeRole.rounded)),
      );
      return DecoratedBox(
        key: ValueKey('inline-media-bubble-${view.id}'),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.overlay.border,
            width: context.units(theme.shapes.fieldBorderWidth),
          ),
          borderRadius: radius,
        ),
        position: DecorationPosition.foreground,
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              media,
              if (transferStatus != null)
                ColoredBox(
                  color: theme.surface.subtle,
                  child: Padding(
                    padding: EdgeInsets.all(gap),
                    child: transferStatus,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.subtle,
        borderRadius: BorderRadius.circular(
          context.units(theme.shapes.radius(ShapeRole.rounded)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _nonVisualPresentation(context),
            if (_hasPlayback) ...[
              SizedBox(height: context.units(theme.spacing.xsmall)),
              _playbackControls(context),
            ],
            if (transferStatus != null) ...[
              SizedBox(height: context.units(theme.spacing.xsmall)),
              transferStatus,
            ],
          ],
        ),
      ),
    );
  }

  Widget _nonVisualPresentation(BuildContext context) {
    final action = _loadAction(context);
    final presentation = _presentation(context);
    if (view.kind != CarpenterMediaKind.file) {
      return Stack(
        children: [
          presentation,
          if (action != null)
            PositionedDirectional(top: 0, end: 0, child: action),
        ],
      );
    }
    final theme = CarpenterTheme.of(context);
    return SizedBox(
      width: context.units(theme.sizes.layoutSecondary),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: presentation),
          if (action != null) ...[
            SizedBox(width: context.units(theme.spacing.small)),
            action,
          ],
        ],
      ),
    );
  }

  bool get _hasPlayback =>
      view.kind == CarpenterMediaKind.audio ||
      view.kind == CarpenterMediaKind.voice;

  bool get _isVisual =>
      view.kind == CarpenterMediaKind.image ||
      view.kind == CarpenterMediaKind.video ||
      view.kind == CarpenterMediaKind.videoCircle;

  Widget _presentation(BuildContext context) => switch (view.kind) {
    CarpenterMediaKind.image => _visualPreview(context, blurred: true),
    CarpenterMediaKind.video => _videoPreview(context),
    CarpenterMediaKind.audio ||
    CarpenterMediaKind.voice => _audioPreview(context),
    CarpenterMediaKind.videoCircle => _videoCircle(context),
    CarpenterMediaKind.file => _filePreview(context),
  };

  Widget? _loadAction(BuildContext context) {
    if (view.loadState == CarpenterMediaLoadState.originalLoading) {
      return CarpenterLoader(
        semanticLabel: view.kind == CarpenterMediaKind.file
            ? 'Скачивание: ${view.label}'
            : 'Загрузка оригинала: ${view.label}',
      );
    }
    if (view.loadState == CarpenterMediaLoadState.failed) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowRotateRight,
        semanticLabel: view.kind == CarpenterMediaKind.file
            ? 'Повторить скачивание: ${view.label}'
            : 'Повторить загрузку: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.warning,
        prominence: ActionProminence.high,
        size: ControlSize.small,
      );
    }
    if (view.requiresExplicitOriginalLoad) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowDownToLine,
        semanticLabel: view.kind == CarpenterMediaKind.file
            ? 'Скачать и открыть: ${view.label}'
            : 'Загрузить оригинал: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.primary,
        prominence: ActionProminence.high,
        size: ControlSize.small,
      );
    }
    return null;
  }

  Widget? _transferStatus(BuildContext context) {
    final phase = view.transferPhase;
    if (phase == null) return null;
    final progress = _normalizedProgress(view.transferProgress);
    final active = switch (phase) {
      CarpenterMediaTransferPhase.preparingUpload ||
      CarpenterMediaTransferPhase.uploading ||
      CarpenterMediaTransferPhase.verifyingUpload ||
      CarpenterMediaTransferPhase.downloading => true,
      _ => false,
    };
    final label = switch (phase) {
      CarpenterMediaTransferPhase.preparingUpload => 'Готовим файл…',
      CarpenterMediaTransferPhase.uploading =>
        progress == null
            ? 'Отправляем…'
            : 'Отправляем · ${(progress * 100).round()}%',
      CarpenterMediaTransferPhase.verifyingUpload => 'Проверяем файл…',
      CarpenterMediaTransferPhase.downloading =>
        progress == null
            ? 'Скачиваем…'
            : 'Скачиваем · ${(progress * 100).round()}%',
      CarpenterMediaTransferPhase.uploadFailed => 'Не удалось отправить',
      CarpenterMediaTransferPhase.downloadFailed => 'Не удалось скачать',
      CarpenterMediaTransferPhase.uploadCancelled => 'Отправка отменена',
      CarpenterMediaTransferPhase.sourceRequired => 'Выберите файл повторно',
    };
    final semanticLabel = '$label ${view.label}';
    return Column(
      key: ValueKey('media-transfer-status-${view.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phase == CarpenterMediaTransferPhase.uploadFailed ||
            phase == CarpenterMediaTransferPhase.downloadFailed)
          CarpenterText.feedback(
            label,
            role: TypographyRole.caption,
            feedbackRole: FeedbackColorRole.danger,
            semanticsLabel: semanticLabel,
          )
        else
          CarpenterText.caption(
            label,
            colorRole: ContentColorRole.secondary,
            semanticsLabel: semanticLabel,
          ),
        if (active) ...[
          SizedBox(
            height: context.units(CarpenterTheme.of(context).spacing.xsmall),
          ),
          CarpenterProgress(
            value:
                phase == CarpenterMediaTransferPhase.uploading ||
                    phase == CarpenterMediaTransferPhase.downloading
                ? progress
                : null,
            semanticLabel: semanticLabel,
          ),
        ],
      ],
    );
  }

  static double? _normalizedProgress(double? value) =>
      value == null || !value.isFinite
      ? null
      : value.clamp(0.0, 1.0).toDouble();

  Widget? _visualStateAction(BuildContext context) {
    if (view.loadState == CarpenterMediaLoadState.originalLoading) {
      return CarpenterLoader(semanticLabel: 'Загрузка: ${view.label}');
    }
    if (view.loadState == CarpenterMediaLoadState.failed) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowRotateRight,
        semanticLabel: 'Повторить загрузку: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.warning,
        prominence: ActionProminence.filled,
        size: ControlSize.large,
      );
    }
    if (_visualNeedsLoad && view.kind != CarpenterMediaKind.videoCircle) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowDownToLine,
        semanticLabel: 'Загрузить: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.primary,
        prominence: ActionProminence.filled,
        size: ControlSize.large,
      );
    }
    return null;
  }

  bool get _visualNeedsLoad =>
      view.loadState == CarpenterMediaLoadState.previewReady &&
      view.originalBytes == null &&
      onLoadRequested != null;

  Widget _visualPreview(BuildContext context, {required bool blurred}) {
    final compact = _visualContent(context, blurred: blurred);
    if (_visualNeedsLoad) {
      return Semantics(
        button: true,
        label: 'Загрузить: ${view.label}',
        onTap: onLoadRequested,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onLoadRequested,
          child: compact,
        ),
      );
    }
    if (onFocusChanged == null) return compact;
    return CarpenterDialog(
      open: view.focused,
      onOpenChanged: onFocusChanged!,
      title: view.label,
      semanticLabel: 'Просмотр ${view.label}',
      dismissPolicy: DialogDismissPolicy.escapeOnly,
      presentation: CarpenterDialogPresentation.immersive,
      content: InteractiveViewer(
        minScale: .5,
        maxScale: 5,
        boundaryMargin: EdgeInsets.all(
          context.units(CarpenterTheme.of(context).spacing.large),
        ),
        child: Center(
          child: _visualContent(context, blurred: false, expanded: true),
        ),
      ),
      child: Semantics(
        button: true,
        label: 'Открыть ${view.label}',
        onTap: () => onFocusChanged!(true),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onFocusChanged!(true),
          child: compact,
        ),
      ),
    );
  }

  Widget _visualContent(
    BuildContext context, {
    required bool blurred,
    bool expanded = false,
  }) {
    final theme = CarpenterTheme.of(context);
    final bytes = view.originalBytes ?? view.previewBytes;
    final content =
        (expanded ? expandedPreview : null) ??
        preview ??
        (bytes == null
            ? null
            : Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: theme.surface.base,
                  child: const Center(
                    child: CarpenterIcon(
                      GravityIcons.picture,
                      semanticLabel: 'Превью недоступно',
                      size: IconSize.large,
                    ),
                  ),
                ),
              )) ??
        ColoredBox(
          color: theme.surface.base,
          child: const Center(
            child: CarpenterIcon(
              GravityIcons.picture,
              semanticLabel: 'Превью изображения',
              size: IconSize.large,
            ),
          ),
        );
    final shouldBlur =
        blurred &&
        view.loadState != CarpenterMediaLoadState.ready &&
        view.loadState != CarpenterMediaLoadState.originalLoading;
    final ratio =
        view.aspectRatio ??
        (view.kind == CarpenterMediaKind.video ? 16 / 9 : 4 / 3);
    final maxWidth = expanded
        ? MediaQuery.sizeOf(context).width
        : context.units(theme.sizes.layoutSecondary);
    final maxHeight = expanded
        ? MediaQuery.sizeOf(context).height
        : context.units(theme.sizes.layoutNavigationSide);
    final visual = ClipRRect(
      borderRadius: BorderRadius.circular(
        context.units(theme.shapes.radius(ShapeRole.rounded)),
      ),
      child: shouldBlur
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: context.units(theme.spacing.medium),
                sigmaY: context.units(theme.spacing.medium),
              ),
              child: content,
            )
          : content,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: AspectRatio(
        key: ValueKey('inline-media-aspect-${view.id}'),
        aspectRatio: ratio.clamp(.35, 3.0),
        child: visual,
      ),
    );
  }

  Widget _videoPreview(BuildContext context) => Stack(
    alignment: AlignmentDirectional.topStart,
    children: [
      _visualPreview(context, blurred: false),
      if (view.duration case final duration?)
        Padding(
          padding: EdgeInsets.all(
            context.units(CarpenterTheme.of(context).spacing.small),
          ),
          child: CarpenterText.caption(
            _duration(duration),
            colorRole: ContentColorRole.inverse,
            emphasis: TypographyEmphasis.strong,
          ),
        ),
    ],
  );

  Widget _audioPreview(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final waveformHeight = context.units(
      theme.sizes.control(ControlSize.medium),
    );
    return SizedBox(
      width: context.units(theme.sizes.layoutSecondary),
      child: Row(
        children: [
          CarpenterIconButton(
            icon: view.playing ? GravityIcons.pause : GravityIcons.play,
            semanticLabel: view.playing
                ? 'Пауза: ${view.label}'
                : 'Воспроизвести: ${view.label}',
            onPressed: onPlayPauseRequested,
            colorRole: ActionColorRole.primary,
            prominence: ActionProminence.high,
          ),
          SizedBox(width: context.units(theme.spacing.small)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (view.kind == CarpenterMediaKind.audio)
                  CarpenterText.label(
                    view.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                LayoutBuilder(
                  builder: (context, constraints) => Semantics(
                    slider: onSeekRequested != null,
                    label: 'Позиция: ${view.label}',
                    value:
                        '${_duration(view.position)} из ${_duration(view.duration ?? Duration.zero)}',
                    increasedValue: onSeekRequested == null
                        ? null
                        : _duration(
                            _relativePosition(const Duration(seconds: 10)),
                          ),
                    decreasedValue: onSeekRequested == null
                        ? null
                        : _duration(
                            _relativePosition(const Duration(seconds: -10)),
                          ),
                    onIncrease: onSeekRequested == null
                        ? null
                        : () => _seekRelative(const Duration(seconds: 10)),
                    onDecrease: onSeekRequested == null
                        ? null
                        : () => _seekRelative(const Duration(seconds: -10)),
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: onSeekRequested == null
                          ? null
                          : (details) => _seek(
                              details.localPosition.dx,
                              constraints.maxWidth,
                            ),
                      onPointerMove: onSeekRequested == null
                          ? null
                          : (details) => _seek(
                              details.localPosition.dx,
                              constraints.maxWidth,
                            ),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: waveformHeight,
                        child: CustomPaint(
                          key: ValueKey(
                            view.waveform.isEmpty
                                ? 'media-timeline-${view.id}'
                                : 'media-waveform-${view.id}',
                          ),
                          painter: _WaveformPainter(
                            samples: view.waveform,
                            color: theme.content.resolve(
                              ContentColorRole.secondary,
                            ),
                            playedColor: theme.actions.primary.normal,
                            strokeWidth: context.units(
                              theme.shapes.fieldBorderWidth,
                            ),
                            progress:
                                view.duration == null ||
                                    view.duration == Duration.zero
                                ? 0
                                : view.position.inMilliseconds /
                                      view.duration!.inMilliseconds,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCircle(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final compactExtent = context.units(theme.sizes.tableColumn);
    return _circleVisual(context, compactExtent);
  }

  Widget _circleVisual(BuildContext context, double extent) {
    final theme = CarpenterTheme.of(context);
    final progress = view.duration == null || view.duration == Duration.zero
        ? 0.0
        : (view.position.inMilliseconds / view.duration!.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final bytes = view.originalBytes ?? view.previewBytes;
    final content =
        preview ??
        (bytes == null
            ? null
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: theme.surface.base),
              )) ??
        ColoredBox(color: theme.surface.base);
    final actionLabel = _visualNeedsLoad
        ? 'Загрузить и воспроизвести: ${view.label}'
        : view.playing
        ? 'Пауза: ${view.label}'
        : 'Воспроизвести: ${view.label}';
    void activate() {
      if (_visualNeedsLoad) {
        onLoadRequested?.call();
        return;
      }
      if (onPlayPauseRequested case final play?) {
        play();
      } else if (!view.focused) {
        onFocusChanged?.call(true);
      }
    }

    final progressPadding = context.units(theme.shapes.fieldBorderWidth) * 2;
    final totalExtent = extent + progressPadding * 2;
    final canSeek =
        onSeekRequested != null &&
        view.duration != null &&
        view.duration != Duration.zero;

    return Semantics(
      button: onPlayPauseRequested != null || onFocusChanged != null,
      label: '$actionLabel, ${_duration(view.position)}',
      value: canSeek
          ? '${_duration(view.position)} из ${_duration(view.duration!)}'
          : null,
      increasedValue: canSeek
          ? _duration(_relativePosition(const Duration(seconds: 10)))
          : null,
      decreasedValue: canSeek
          ? _duration(_relativePosition(const Duration(seconds: -10)))
          : null,
      onTap: activate,
      onIncrease: canSeek
          ? () => _seekRelative(const Duration(seconds: 10))
          : null,
      onDecrease: canSeek
          ? () => _seekRelative(const Duration(seconds: -10))
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: activate,
        onPanStart: canSeek
            ? (details) => _seekCircle(details.localPosition, totalExtent)
            : null,
        onPanUpdate: canSeek
            ? (details) => _seekCircle(details.localPosition, totalExtent)
            : null,
        child: CustomPaint(
          key: ValueKey('inline-media-circle-progress-${view.id}'),
          foregroundPainter: _CircularProgressPainter(
            progress: progress,
            color: theme.actions.primary.normal,
            trackColor: theme.overlay.border,
            strokeWidth: context.units(theme.shapes.fieldBorderWidth) * 2,
          ),
          child: Padding(
            padding: EdgeInsets.all(progressPadding),
            child: SizedBox.square(
              key: ValueKey('inline-media-circle-${view.id}'),
              dimension: extent,
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(child: content),
                    Center(
                      child: IgnorePointer(
                        child: CarpenterIcon(
                          view.playing
                              ? GravityIcons.circlePauseFill
                              : GravityIcons.circlePlayFill,
                          size: IconSize.large,
                          colorRole: ContentColorRole.inverse,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filePreview(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extension = _extension(view.label);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarpenterIcon(
          _fileIcon(extension),
          semanticLabel: extension.isEmpty ? 'Файл' : 'Файл $extension',
          size: IconSize.large,
        ),
        SizedBox(width: context.units(theme.spacing.small)),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterText.label(
                view.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (extension.isNotEmpty) ...[
                    CarpenterText.caption(extension),
                    SizedBox(width: context.units(theme.spacing.xsmall)),
                  ],
                  CarpenterText.caption(_bytes(view.byteLength)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    if (onLoadRequested == null) return content;
    return Semantics(
      button: true,
      label: 'Открыть ${view.label}',
      onTap: onLoadRequested,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onLoadRequested,
        child: content,
      ),
    );
  }

  void _seek(double localX, double width) {
    final duration = view.duration;
    if (duration == null || duration == Duration.zero || width <= 0) return;
    final fraction = (localX / width).clamp(0.0, 1.0);
    onSeekRequested?.call(
      Duration(milliseconds: (duration.inMilliseconds * fraction).round()),
    );
  }

  void _seekCircle(Offset localPosition, double extent) {
    final duration = view.duration;
    if (duration == null || duration == Duration.zero || extent <= 0) return;
    final center = Offset(extent / 2, extent / 2);
    final vector = localPosition - center;
    var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final fraction = (angle / (math.pi * 2)).clamp(0.0, 1.0);
    onSeekRequested?.call(
      Duration(milliseconds: (duration.inMilliseconds * fraction).round()),
    );
  }

  void _seekRelative(Duration delta) {
    onSeekRequested?.call(_relativePosition(delta));
  }

  Duration _relativePosition(Duration delta) {
    final duration = view.duration;
    if (duration == null || duration == Duration.zero) return view.position;
    final requested = view.position + delta;
    return requested < Duration.zero
        ? Duration.zero
        : requested > duration
        ? duration
        : requested;
  }

  Widget _playbackControls(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    final audioLike =
        view.kind == CarpenterMediaKind.audio ||
        view.kind == CarpenterMediaKind.voice;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!audioLike) ...[
          CarpenterIconButton(
            icon: view.playing ? GravityIcons.pause : GravityIcons.play,
            semanticLabel: view.playing
                ? 'Пауза: ${view.label}'
                : 'Воспроизвести: ${view.label}',
            onPressed: onPlayPauseRequested,
            prominence: ActionProminence.ghost,
            size: ControlSize.small,
          ),
          SizedBox(width: gap),
        ],
        CarpenterText.caption(
          '${_duration(view.position)} / ${_duration(view.duration ?? Duration.zero)}',
        ),
        if (onSpeedChanged != null) ...[
          SizedBox(width: gap),
          CarpenterButton.text(
            label: '${_playbackRate(view.playbackRate)}×',
            size: ControlSize.small,
            onPressed: () => onSpeedChanged!(
              CarpenterPlaybackSpeeds.next(view.playbackRate),
            ),
          ),
        ],
      ],
    );
  }
}

String _duration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

final class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.samples,
    required this.color,
    required this.playedColor,
    required this.strokeWidth,
    required this.progress,
  });

  final List<int> samples;
  final Color color;
  final Color playedColor;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      final center = size.height / 2;
      final played = size.width * progress.clamp(0.0, 1.0);
      final trackPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth * 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, center),
        Offset(size.width, center),
        trackPaint,
      );
      if (played > 0) {
        canvas.drawLine(
          Offset(0, center),
          Offset(played, center),
          Paint()
            ..color = playedColor
            ..strokeWidth = strokeWidth * 2
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    final values = samples;
    final slot = size.width / values.length;
    final maximum = values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    for (var index = 0; index < values.length; index++) {
      final height = size.height * (values[index] / maximum).clamp(.12, 1);
      final x = slot * index + slot / 2;
      final paint = Paint()
        ..color = x / size.width <= progress ? playedColor : color
        ..strokeWidth = math.min(strokeWidth * 2, slot * .5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.playedColor != playedColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

String _playbackRate(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

final class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final bounds = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawOval(
      bounds,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      bounds,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

String _extension(String label) {
  final dot = label.lastIndexOf('.');
  if (dot < 0 || dot == label.length - 1) return '';
  return label.substring(dot + 1).toUpperCase();
}

CarpenterIconSource _fileIcon(String extension) => switch (extension) {
  'PDF' => GravityIcons.fileLetterP,
  'DOC' || 'DOCX' => GravityIcons.fileLetterW,
  'XLS' || 'XLSX' => GravityIcons.fileLetterX,
  'ZIP' || 'RAR' || '7Z' => GravityIcons.fileZipper,
  'TXT' || 'RTF' => GravityIcons.fileText,
  _ => GravityIcons.file,
};

String _bytes(int value) {
  if (value < 1024) return '$value Б';
  final kilobytes = value / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes == kilobytes.roundToDouble() ? kilobytes.toInt() : kilobytes.toStringAsFixed(1)} КБ';
  }
  final megabytes = kilobytes / 1024;
  return '${megabytes == megabytes.roundToDouble() ? megabytes.toInt() : megabytes.toStringAsFixed(1)} МБ';
}
