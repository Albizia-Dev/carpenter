import 'dart:ui';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
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
            _presentation(context),
            if (view.loadState == CarpenterMediaLoadState.originalLoading)
              const CarpenterText.caption('Загружаем оригинал…'),
            if (view.loadState == CarpenterMediaLoadState.failed)
              const CarpenterText.feedback(
                'Не удалось загрузить медиа.',
                feedbackRole: FeedbackColorRole.danger,
              ),
            if (view.requiresExplicitOriginalLoad)
              CarpenterButton(
                label: 'Загрузить оригинал',
                semanticLabel: 'Загрузить оригинал: ${view.label}',
                onPressed: onLoadRequested,
                prominence: ActionProminence.ghost,
                size: ControlSize.small,
              ),
            if (_hasPlayback) _playbackControls(context),
          ],
        ),
      ),
    );
  }

  bool get _hasPlayback =>
      view.kind == CarpenterMediaKind.video ||
      view.kind == CarpenterMediaKind.audio ||
      view.kind == CarpenterMediaKind.voice ||
      view.kind == CarpenterMediaKind.videoCircle;

  Widget _presentation(BuildContext context) => switch (view.kind) {
    CarpenterMediaKind.image => _visualPreview(context, blurred: true),
    CarpenterMediaKind.video => _videoPreview(context),
    CarpenterMediaKind.audio ||
    CarpenterMediaKind.voice => _audioPreview(context),
    CarpenterMediaKind.videoCircle => _videoCircle(context),
    CarpenterMediaKind.file => _filePreview(context),
  };

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
                imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: content,
              )
            : content,
      ),
    );
  }

  Widget _videoPreview(BuildContext context) => Stack(
    alignment: AlignmentDirectional.bottomEnd,
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
    return SizedBox(
      height: context.units(theme.sizes.control(ControlSize.large)),
      width: context.units(theme.sizes.layoutSecondary),
      child: CustomPaint(
        key: ValueKey('media-waveform-${view.id}'),
        painter: _WaveformPainter(
          samples: view.waveform,
          color: theme.content.resolve(ContentColorRole.secondary),
          playedColor: theme.actions.primary.state,
          progress: view.duration == null || view.duration == Duration.zero
              ? 0
              : view.position.inMilliseconds / view.duration!.inMilliseconds,
        ),
      ),
    );
  }

  Widget _videoCircle(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extent = context.units(
      view.focused ? theme.sizes.layoutNavigationSide : theme.sizes.tableColumn,
    );
    final content = preview ?? ColoredBox(color: theme.surface.base);
    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        SizedBox.square(
          key: ValueKey('inline-media-circle-${view.id}'),
          dimension: extent,
          child: ClipOval(child: content),
        ),
        CarpenterIconButton(
          icon: view.focused
              ? GravityIcons.arrowsOppositeToDots
              : GravityIcons.arrowsExpand,
          semanticLabel: view.focused
              ? 'Уменьшить видеосообщение'
              : 'Увеличить видеосообщение',
          onPressed: onFocusChanged == null
              ? null
              : () => onFocusChanged!(!view.focused),
          prominence: ActionProminence.high,
          size: ControlSize.small,
        ),
      ],
    );
  }

  Widget _filePreview(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CarpenterIcon(
        GravityIcons.file,
        semanticLabel: 'Файл',
        size: IconSize.large,
      ),
      SizedBox(width: context.units(CarpenterTheme.of(context).spacing.small)),
      Flexible(
        child: CarpenterText.label(
          view.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _playbackControls(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CarpenterIconButton(
          icon: view.playing ? GravityIcons.pause : GravityIcons.play,
          semanticLabel: view.playing
              ? 'Пауза: ${view.label}'
              : 'Воспроизвести: ${view.label}',
          onPressed: onPlayPauseRequested,
          prominence: ActionProminence.ghost,
          size: ControlSize.small,
        ),
        CarpenterText.caption(
          '${_duration(view.position)} / ${_duration(view.duration ?? Duration.zero)}',
        ),
        CarpenterButton.text(
          label: '−15 с',
          size: ControlSize.small,
          onPressed: onSeekRequested == null
              ? null
              : () => onSeekRequested!(_seek(const Duration(seconds: -15))),
        ),
        CarpenterButton.text(
          label: '+15 с',
          size: ControlSize.small,
          onPressed: onSeekRequested == null
              ? null
              : () => onSeekRequested!(_seek(const Duration(seconds: 15))),
        ),
        CarpenterButton.text(
          label: '${view.playbackRate.toStringAsFixed(1)}×',
          size: ControlSize.small,
          onPressed: onSpeedChanged == null
              ? null
              : () => onSpeedChanged!(
                  CarpenterPlaybackSpeeds.next(view.playbackRate),
                ),
        ),
      ],
    );
  }

  Duration _seek(Duration delta) {
    final total = view.duration ?? Duration.zero;
    final milliseconds = (view.position.inMilliseconds + delta.inMilliseconds)
        .clamp(0, total.inMilliseconds);
    return Duration(milliseconds: milliseconds);
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
    required this.progress,
  });

  final List<int> samples;
  final Color color;
  final Color playedColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final values = samples.isEmpty ? const [2, 5, 3, 7, 4, 8] : samples;
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
        ..strokeWidth = slot * .35
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
      oldDelegate.samples != samples || oldDelegate.progress != progress;
}
