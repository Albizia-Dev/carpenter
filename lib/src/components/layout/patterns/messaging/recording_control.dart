import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/gravity_icon.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import 'messaging_models.dart';

/// Voice/video-circle control with tap switching, hold recording and drag lock.
/// Shift+Space on the focused control and the start semantics action request
/// capture without holding a pointer. The host applies lock after permission.
final class CarpenterRecordingControl extends StatefulWidget {
  const CarpenterRecordingControl({
    super.key,
    required this.view,
    this.onModeChanged,
    this.onStart,
    this.onLock,
    this.onStop,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.onPreview,
    this.onSend,
    this.onRerecord,
    this.focusNode,
  });

  final CarpenterRecordingView view;
  final ValueChanged<CarpenterRecordingKind>? onModeChanged;
  final ValueChanged<CarpenterRecordingKind>? onStart;
  final ValueChanged<CarpenterRecordingKind>? onLock;
  final ValueChanged<CarpenterRecordingKind>? onStop;
  final ValueChanged<CarpenterRecordingKind>? onCancel;

  /// Optional host capabilities. Omitted actions are hidden. Stop prepares a
  /// preview; only [onSend] requests delivery. The host retains recorded bytes
  /// across failures and owns permission, playback and upload progress.
  final ValueChanged<CarpenterRecordingKind>? onPause;

  /// Resumes a paused host session; omitted when the recorder cannot resume.
  final ValueChanged<CarpenterRecordingKind>? onResume;

  /// Starts playback of prepared bytes without requesting delivery.
  final ValueChanged<CarpenterRecordingKind>? onPreview;

  /// Requests delivery of prepared bytes. Failures stay in host-owned preview.
  final ValueChanged<CarpenterRecordingKind>? onSend;

  /// Replaces the prepared recording after an explicit user action.
  final ValueChanged<CarpenterRecordingKind>? onRerecord;

  /// Optional caller-owned focus for keyboard capture and focus restoration.
  /// The caller disposes it; omitting it lets the action own its focus node.
  final FocusNode? focusNode;

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
  bool _cancelled = false;
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
      _cancelled = false;
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
    if (widget.view.phase != CarpenterRecordingPhase.idle) return;
    if (!_alternativeAvailable) return;
    widget.onModeChanged?.call(
      widget.view.kind == CarpenterRecordingKind.voice
          ? CarpenterRecordingKind.video
          : CarpenterRecordingKind.voice,
    );
  }

  void _pointerDown(PointerDownEvent event) {
    _suppressTap = false;
    _cancelled = false;
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

  void _startWithoutHold() {
    if (!_currentAvailable ||
        widget.view.phase != CarpenterRecordingPhase.idle ||
        widget.onStart == null) {
      return;
    }
    widget.onStart?.call(widget.view.kind);
    widget.onLock?.call(widget.view.kind);
  }

  void _pointerMove(BuildContext context, PointerMoveEvent event) {
    if (!_started || _locked || _cancelled || _origin == null) return;
    final threshold = context.units(
      CarpenterTheme.of(context).sizes.minimumTarget,
    );
    if (event.position.dy - _origin!.dy <= -threshold) {
      _locked = true;
      widget.onLock?.call(widget.view.kind);
    } else if (event.position.dx - _origin!.dx <= -threshold) {
      _cancelled = true;
      _suppressTap = true;
      widget.onCancel?.call(widget.view.kind);
    }
  }

  void _finishPointer({bool cancelled = false}) {
    _holdTimer?.cancel();
    _origin = null;
    if (_started && !_locked && !_cancelled) {
      if (cancelled) {
        widget.onCancel?.call(widget.view.kind);
      } else {
        widget.onStop?.call(widget.view.kind);
      }
    }
    _started = false;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    if (view.phase == CarpenterRecordingPhase.preview ||
        view.phase == CarpenterRecordingPhase.paused ||
        view.phase == CarpenterRecordingPhase.locked) {
      return _sessionControls(context);
    }
    final icon = view.kind == CarpenterRecordingKind.voice
        ? GravityIcons.microphone
        : GravityIcons.video;
    final label = view.kind == CarpenterRecordingKind.voice
        ? 'Записать голосовое сообщение'
        : 'Записать видеосообщение';
    final level = view.level.clamp(0.0, 1.0);
    final theme = CarpenterTheme.of(context);
    final controlExtent = context.units(theme.sizes.control(ControlSize.large));
    final pulseExtent = context.units(theme.spacing.small);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: theme.motion.transitionDuration(context),
          switchInCurve: theme.motion.stateCurve,
          switchOutCurve: theme.motion.stateCurve,
          child: switch (view.phase) {
            CarpenterRecordingPhase.recording => const CarpenterIcon(
              GravityIcons.arrowUp,
              key: ValueKey('recording-lock-affordance'),
              semanticLabel: 'Потяните вверх, чтобы зафиксировать запись',
              size: IconSize.small,
            ),
            CarpenterRecordingPhase.locked => const CarpenterIcon(
              GravityIcons.lockFill,
              key: ValueKey('recording-lock-indicator'),
              semanticLabel: 'Запись зафиксирована',
              size: IconSize.small,
            ),
            _ => const SizedBox.shrink(key: ValueKey('recording-lock-hidden')),
          },
        ),
        if (view.failureLabel case final failure?)
          CarpenterText.feedback(
            failure,
            feedbackRole: FeedbackColorRole.danger,
            role: TypographyRole.caption,
          ),
        Semantics(
          customSemanticsActions:
              view.phase == CarpenterRecordingPhase.idle &&
                  _currentAvailable &&
                  widget.onStart != null
              ? {
                  const CustomSemanticsAction(
                    label: 'Начать запись без удержания',
                  ): _startWithoutHold,
                }
              : const {},
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.space, shift: true):
                  _startWithoutHold,
            },
            child: Listener(
              onPointerDown: _pointerDown,
              onPointerMove: (event) => _pointerMove(context, event),
              onPointerUp: (_) => _finishPointer(),
              onPointerCancel: (_) => _finishPointer(cancelled: true),
              child: TweenAnimationBuilder<double>(
                duration: theme.motion.transitionDuration(context),
                curve: theme.motion.stateCurve,
                tween: Tween(end: level),
                builder: (context, value, child) => Transform.scale(
                  scale: 1 + value * pulseExtent / controlExtent,
                  child: child,
                ),
                child: SizedBox(
                  key: const ValueKey('recording-control-button'),
                  width: controlExtent + context.units(theme.spacing.medium),
                  child: CarpenterIconButton(
                    focusNode: widget.focusNode,
                    icon: icon,
                    semanticLabel: label,
                    onPressed:
                        _currentAvailable &&
                            view.phase != CarpenterRecordingPhase.unavailable &&
                            view.phase != CarpenterRecordingPhase.failed
                        ? _tap
                        : null,
                    colorRole: ActionColorRole.primary,
                    prominence:
                        view.phase == CarpenterRecordingPhase.recording ||
                            view.phase == CarpenterRecordingPhase.locked
                        ? ActionProminence.high
                        : ActionProminence.normal,
                    toggled:
                        view.phase == CarpenterRecordingPhase.recording ||
                        view.phase == CarpenterRecordingPhase.locked,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sessionControls(BuildContext context) {
    final view = widget.view;
    final preview = view.phase == CarpenterRecordingPhase.preview;
    final paused = view.phase == CarpenterRecordingPhase.paused;
    final minutes = view.duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (view.duration.inSeconds % 60).toString().padLeft(2, '0');
    Widget action(
      GravityIconData icon,
      String label,
      ValueChanged<CarpenterRecordingKind>? callback, {
      bool primary = false,
    }) => CarpenterIconButton(
      icon: icon,
      semanticLabel: label,
      onPressed: view.busy ? null : () => callback?.call(view.kind),
      executionPhase: view.busy && primary
          ? ActionExecutionPhase.running
          : ActionExecutionPhase.idle,
      prominence: primary ? ActionProminence.high : ActionProminence.ghost,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.phase == CarpenterRecordingPhase.locked)
          const CarpenterIcon(
            GravityIcons.lockFill,
            key: ValueKey('recording-lock-indicator'),
            semanticLabel: 'Запись зафиксирована',
            size: IconSize.small,
          ),
        CarpenterText.caption('$minutes:$seconds'),
        if (view.failureLabel case final failure?)
          CarpenterText.feedback(
            failure,
            feedbackRole: FeedbackColorRole.danger,
          ),
        Wrap(
          alignment: WrapAlignment.end,
          children: [
            if (widget.onCancel != null)
              action(GravityIcons.trashBin, 'Удалить запись', widget.onCancel),
            if (preview && widget.onRerecord != null)
              action(
                GravityIcons.arrowRotateLeft,
                'Записать заново',
                widget.onRerecord,
              ),
            if (preview && widget.onPreview != null)
              action(GravityIcons.play, 'Прослушать запись', widget.onPreview),
            if (!preview && !paused && widget.onPause != null)
              action(
                GravityIcons.pause,
                'Приостановить запись',
                widget.onPause,
              ),
            if (paused && widget.onResume != null)
              action(
                GravityIcons.microphone,
                'Продолжить запись',
                widget.onResume,
              ),
            if (!preview && widget.onStop != null)
              action(
                GravityIcons.stop,
                'Завершить запись',
                widget.onStop,
                primary: true,
              ),
            if (preview && widget.onSend != null)
              action(
                GravityIcons.paperPlane,
                'Отправить запись',
                widget.onSend,
                primary: true,
              ),
          ],
        ),
      ],
    );
  }
}
