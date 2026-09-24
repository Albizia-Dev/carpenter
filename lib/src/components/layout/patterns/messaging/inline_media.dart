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
import '../../../basic/text.dart';
import '../../../behaviour/popover.dart';
import 'messaging_models.dart';

typedef CarpenterMediaPreviewBuilder =
    Widget Function(BuildContext context, CarpenterMediaView media);
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
    this.onLoadRequested,
    this.onPlayPauseRequested,
    this.onSeekRequested,
    this.onSpeedChanged,
    this.onFocusChanged,
  });

  final CarpenterMediaView view;
  final Widget? preview;
  final VoidCallback? onLoadRequested;
  final VoidCallback? onPlayPauseRequested;
  final ValueChanged<Duration>? onSeekRequested;
  final ValueChanged<double>? onSpeedChanged;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
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
                Stack(
                  children: [
                    _presentation(context),
                    if (_loadAction(context) case final action?)
                      PositionedDirectional(top: 0, end: 0, child: action),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_hasPlayback) ...[
          SizedBox(height: context.units(theme.spacing.xsmall)),
          _playbackControls(context),
        ],
      ],
    );
  }

  bool get _hasPlayback =>
      view.kind == CarpenterMediaKind.video ||
      view.kind == CarpenterMediaKind.audio ||
      view.kind == CarpenterMediaKind.voice;

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
        semanticLabel: 'Загрузка оригинала: ${view.label}',
      );
    }
    if (view.loadState == CarpenterMediaLoadState.failed) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowRotateRight,
        semanticLabel: 'Повторить загрузку: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.warning,
        prominence: ActionProminence.high,
        size: ControlSize.small,
      );
    }
    if (view.requiresExplicitOriginalLoad) {
      return CarpenterIconButton(
        icon: GravityIcons.arrowDownToLine,
        semanticLabel: 'Загрузить оригинал: ${view.label}',
        onPressed: onLoadRequested,
        colorRole: ActionColorRole.primary,
        prominence: ActionProminence.high,
        size: ControlSize.small,
      );
    }
    return null;
  }

  Widget _visualPreview(BuildContext context, {required bool blurred}) {
    final theme = CarpenterTheme.of(context);
    final bytes = view.originalBytes ?? view.previewBytes;
    final content =
        preview ??
        (bytes == null
            ? null
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        context.units(theme.shapes.radius(ShapeRole.rounded)),
      ),
      child: SizedBox(
        width: context.units(theme.sizes.layoutSecondary),
        height: context.units(theme.sizes.tableColumn),
        child: shouldBlur
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: context.units(theme.spacing.medium),
                  sigmaY: context.units(theme.spacing.medium),
                ),
                child: content,
              )
            : content,
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
                  builder: (context, constraints) => Listener(
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
                        key: ValueKey('media-waveform-${view.id}'),
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
    final focusedExtent = context.units(theme.sizes.layoutNavigationSide);
    final compact = view.focused
        ? SizedBox.square(dimension: compactExtent)
        : _circleVisual(context, compactExtent);
    return CarpenterPopover(
      open: view.focused,
      onOpenChanged: (focused) => onFocusChanged?.call(focused),
      anchorActivates: false,
      presentation: CarpenterPopoverPresentation.bare,
      anchor: compact,
      content: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPlayPauseRequested,
        child: _circleVisual(context, focusedExtent),
      ),
    );
  }

  Widget _circleVisual(BuildContext context, double extent) {
    final theme = CarpenterTheme.of(context);
    final progress = view.duration == null || view.duration == Duration.zero
        ? 0.0
        : (view.position.inMilliseconds / view.duration!.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final content = preview ?? ColoredBox(color: theme.surface.base);
    return Semantics(
      button: onPlayPauseRequested != null || onFocusChanged != null,
      label: '${view.label}, ${_duration(view.position)}',
      onTap: () {
        onPlayPauseRequested?.call();
        if (!view.focused) onFocusChanged?.call(true);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          onPlayPauseRequested?.call();
          if (!view.focused) onFocusChanged?.call(true);
        },
        child: CustomPaint(
          key: ValueKey('inline-media-circle-progress-${view.id}'),
          foregroundPainter: _CircularProgressPainter(
            progress: progress,
            color: theme.actions.primary.normal,
            trackColor: theme.overlay.border,
            strokeWidth: context.units(theme.shapes.fieldBorderWidth) * 2,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              context.units(theme.shapes.fieldBorderWidth) * 2,
            ),
            child: SizedBox.square(
              key: ValueKey('inline-media-circle-${view.id}'),
              dimension: extent,
              child: ClipOval(child: content),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filePreview(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extension = _extension(view.label);
    return Row(
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
  }

  void _seek(double localX, double width) {
    final duration = view.duration;
    if (duration == null || duration == Duration.zero || width <= 0) return;
    final fraction = (localX / width).clamp(0.0, 1.0);
    onSeekRequested?.call(
      Duration(milliseconds: (duration.inMilliseconds * fraction).round()),
    );
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
            label: '${view.playbackRate.toStringAsFixed(1)}×',
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
    final values = samples.isEmpty
        ? List<int>.generate(32, (index) => 2 + (index * 5) % 7)
        : samples;
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
