import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/text.dart';

/// Presentation phase of a host-owned voice recording.
enum CarpenterVoicePhase {
  idle,
  requestingPermission,
  recording,
  paused,
  stopping,
  preview,
  failed,
}

/// Recording and playback actions; the host owns media and device access.
final class CarpenterVoiceControls extends StatelessWidget {
  const CarpenterVoiceControls({
    super.key,
    required this.phase,
    required this.recordDuration,
    required this.position,
    required this.duration,
    required this.speed,
    this.playingMessage = false,
    this.playing = false,
    this.seekStep = const Duration(seconds: 15),
    this.onRecord,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onCancel,
    this.onPreview,
    this.onAttach,
    this.onRerecord,
    this.onPlaybackPause,
    this.onSeek,
    this.onSpeedChanged,
  });

  final CarpenterVoicePhase phase;
  final Duration recordDuration;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool playingMessage;
  final bool playing;
  final Duration seekStep;
  final VoidCallback? onRecord;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;
  final VoidCallback? onPreview;
  final VoidCallback? onAttach;
  final VoidCallback? onRerecord;
  final VoidCallback? onPlaybackPause;
  final ValueChanged<Duration>? onSeek;
  final ValueChanged<double>? onSpeedChanged;

  static const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final effectiveDuration = duration > Duration.zero
        ? duration
        : recordDuration;
    final controls = <Widget>[];
    if (playingMessage) {
      controls.addAll([
        CarpenterText.caption(
          'Голосовое · ${_duration(position)} / ${_duration(effectiveDuration)}',
        ),
        CarpenterButton(
          label: playing ? 'Пауза' : 'Продолжить',
          onPressed: onPlaybackPause,
          prominence: ActionProminence.ghost,
        ),
      ]);
    } else {
      switch (phase) {
        case CarpenterVoicePhase.idle:
          controls.add(_button('Записать', onRecord));
        case CarpenterVoicePhase.requestingPermission:
          controls.add(
            const CarpenterText.caption('Запрашиваем доступ к микрофону…'),
          );
        case CarpenterVoicePhase.recording:
          controls.addAll([
            CarpenterText.caption('Запись · ${_duration(recordDuration)}'),
            _button('Пауза', onPause),
            _button('Завершить', onStop, high: true),
            _button('Отменить', onCancel),
          ]);
        case CarpenterVoicePhase.paused:
          controls.addAll([
            CarpenterText.caption('Пауза · ${_duration(recordDuration)}'),
            _button('Продолжить', onResume),
            _button('Завершить', onStop, high: true),
            _button('Отменить', onCancel),
          ]);
        case CarpenterVoicePhase.stopping:
          controls.add(const CarpenterText.caption('Готовим запись…'));
        case CarpenterVoicePhase.preview:
          controls.addAll([
            CarpenterText.caption('Запись · ${_duration(recordDuration)}'),
            _button(
              playing ? 'Пауза' : 'Прослушать',
              playing ? onPlaybackPause : onPreview,
            ),
            _button('Прикрепить', onAttach, high: true),
            _button('Перезаписать', onRerecord),
            _button('Отменить', onCancel),
          ]);
        case CarpenterVoicePhase.failed:
          controls.addAll([
            const CarpenterText.feedback(
              'Не удалось записать голосовое сообщение.',
              feedbackRole: FeedbackColorRole.danger,
            ),
            _button('Повторить', onRecord),
          ]);
      }
    }
    if (playingMessage || phase == CarpenterVoicePhase.preview) {
      controls.addAll([
        _button(
          '−${seekStep.inSeconds} с',
          onSeek == null ? null : () => _seek(-seekStep, effectiveDuration),
        ),
        _button(
          '+${seekStep.inSeconds} с',
          onSeek == null ? null : () => _seek(seekStep, effectiveDuration),
        ),
        _button(
          'Скорость $speed×',
          onSpeedChanged == null
              ? null
              : () {
                  final next = speeds.indexWhere((value) => value > speed);
                  onSpeedChanged!(next < 0 ? speeds.first : speeds[next]);
                },
        ),
      ]);
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
        child: Wrap(spacing: gap, runSpacing: gap, children: controls),
      ),
    );
  }

  void _seek(Duration delta, Duration total) {
    final target = (position.inMilliseconds + delta.inMilliseconds).clamp(
      0,
      total.inMilliseconds,
    );
    onSeek?.call(Duration(milliseconds: target));
  }

  static Widget _button(
    String label,
    VoidCallback? onPressed, {
    bool high = false,
  }) => CarpenterButton(
    label: label,
    onPressed: onPressed,
    prominence: high ? ActionProminence.high : ActionProminence.ghost,
  );

  static String _duration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
