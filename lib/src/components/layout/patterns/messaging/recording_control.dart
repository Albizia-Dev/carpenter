import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/text.dart';
import 'messaging_models.dart';

/// Voice/video-circle control with tap switching, hold recording and drag lock.
final class CarpenterRecordingControl extends StatefulWidget {
  const CarpenterRecordingControl({
    super.key,
    required this.view,
    this.onModeChanged,
    this.onStart,
    this.onLock,
    this.onStop,
  });

  final CarpenterRecordingView view;
  final ValueChanged<CarpenterRecordingKind>? onModeChanged;
  final ValueChanged<CarpenterRecordingKind>? onStart;
  final ValueChanged<CarpenterRecordingKind>? onLock;
  final ValueChanged<CarpenterRecordingKind>? onStop;

  @override
  State<CarpenterRecordingControl> createState() =>
      _CarpenterRecordingControlState();
}

final class _CarpenterRecordingControlState
    extends State<CarpenterRecordingControl> {
  Timer? _holdTimer;
  Offset? _origin;
  bool _started = false;
  bool _locked = false;
  bool _suppressTap = false;

  bool get _currentAvailable => widget.view.kind == CarpenterRecordingKind.voice
      ? widget.view.voiceAvailable
      : widget.view.videoAvailable;

  bool get _alternativeAvailable =>
      widget.view.kind == CarpenterRecordingKind.voice
      ? widget.view.videoAvailable
      : widget.view.voiceAvailable;

  @override
  void didUpdateWidget(CarpenterRecordingControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.phase != CarpenterRecordingPhase.idle &&
        widget.view.phase == CarpenterRecordingPhase.idle) {
      _started = false;
      _locked = false;
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _tap() {
    if (_suppressTap) {
      _suppressTap = false;
      return;
    }
    if (widget.view.phase == CarpenterRecordingPhase.locked ||
        widget.view.phase == CarpenterRecordingPhase.recording) {
      widget.onStop?.call(widget.view.kind);
      return;
    }
    if (!_alternativeAvailable) return;
    widget.onModeChanged?.call(
      widget.view.kind == CarpenterRecordingKind.voice
          ? CarpenterRecordingKind.video
          : CarpenterRecordingKind.voice,
    );
  }

  void _pointerDown(PointerDownEvent event) {
    _suppressTap = false;
    _origin = event.position;
    if (!_currentAvailable ||
        widget.view.phase != CarpenterRecordingPhase.idle ||
        widget.onStart == null) {
      return;
    }
    _holdTimer?.cancel();
    _holdTimer = Timer(kLongPressTimeout, () {
      if (!mounted || _origin == null) return;
      _started = true;
      _suppressTap = true;
      widget.onStart!(widget.view.kind);
    });
  }

  void _pointerMove(BuildContext context, PointerMoveEvent event) {
    if (!_started || _locked || _origin == null) return;
    final threshold = context.units(
      CarpenterTheme.of(context).sizes.minimumTarget,
    );
    if (event.position.dy - _origin!.dy <= -threshold) {
      _locked = true;
      widget.onLock?.call(widget.view.kind);
    }
  }

  void _finishPointer() {
    _holdTimer?.cancel();
    _origin = null;
    if (_started && !_locked) widget.onStop?.call(widget.view.kind);
    _started = false;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final icon = view.kind == CarpenterRecordingKind.voice
        ? GravityIcons.microphone
        : GravityIcons.video;
    final label = view.kind == CarpenterRecordingKind.voice
        ? 'Записать голосовое сообщение'
        : 'Записать видеосообщение';
    final level = view.level.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.phase == CarpenterRecordingPhase.recording ||
            view.phase == CarpenterRecordingPhase.locked)
          CarpenterText.caption(
            view.phase == CarpenterRecordingPhase.locked
                ? 'Запись закреплена'
                : 'Идёт запись',
          ),
        if (view.failureLabel case final failure?)
          CarpenterText.feedback(
            failure,
            feedbackRole: FeedbackColorRole.danger,
            role: TypographyRole.caption,
          ),
        Listener(
          onPointerDown: _pointerDown,
          onPointerMove: (event) => _pointerMove(context, event),
          onPointerUp: (_) => _finishPointer(),
          onPointerCancel: (_) => _finishPointer(),
          child: TweenAnimationBuilder<double>(
            duration: CarpenterTheme.of(
              context,
            ).motion.transitionDuration(context),
            curve: CarpenterTheme.of(context).motion.stateCurve,
            tween: Tween(end: level),
            builder: (context, value, child) =>
                Transform.scale(scale: 1 + value * .15, child: child),
            child: CarpenterIconButton(
              icon: icon,
              semanticLabel: label,
              onPressed:
                  _currentAvailable &&
                      view.phase != CarpenterRecordingPhase.unavailable &&
                      view.phase != CarpenterRecordingPhase.failed
                  ? _tap
                  : null,
              prominence:
                  view.phase == CarpenterRecordingPhase.recording ||
                      view.phase == CarpenterRecordingPhase.locked
                  ? ActionProminence.high
                  : ActionProminence.ghost,
              toggled:
                  view.phase == CarpenterRecordingPhase.recording ||
                  view.phase == CarpenterRecordingPhase.locked,
            ),
          ),
        ),
      ],
    );
  }
}
