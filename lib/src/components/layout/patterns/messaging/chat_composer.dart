import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/input/text_area.dart';
import '../../../basic/input/field_shell.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
import '../../../../internal/rendering/focus_ring.dart';
import 'attachment_tray.dart';
import 'messaging_models.dart';
import 'recording_control.dart';

/// Controlled, Carpenter-themed composer. The host owns drafts, uploads,
/// recording bytes, permissions and send operations.
final class CarpenterChatComposer extends StatefulWidget {
  const CarpenterChatComposer({
    super.key,
    required this.view,
    required this.recording,
    required this.onTextChanged,
    required this.onSendRequested,
    this.onAttachmentsRequested,
    this.onAttachmentRemoved,
    this.onReplyRemoved,
    this.onRecordingModeChanged,
    this.onRecordingStart,
    this.onRecordingLock,
    this.onRecordingStop,
    this.onRecordingCancel,
    this.onRecordingPause,
    this.onRecordingResume,
    this.onRecordingPreview,
    this.onRecordingSend,
    this.onRecordingRerecord,
  });

  final CarpenterComposerView view;
  final CarpenterRecordingView recording;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<CarpenterSendMode> onSendRequested;
  final VoidCallback? onAttachmentsRequested;
  final ValueChanged<String>? onAttachmentRemoved;
  final VoidCallback? onReplyRemoved;
  final ValueChanged<CarpenterRecordingKind>? onRecordingModeChanged;
  final ValueChanged<CarpenterRecordingKind>? onRecordingStart;
  final ValueChanged<CarpenterRecordingKind>? onRecordingLock;
  final ValueChanged<CarpenterRecordingKind>? onRecordingStop;
  final ValueChanged<CarpenterRecordingKind>? onRecordingCancel;

  /// Host capabilities for the controlled recording session. Stop prepares
  /// bytes; send explicitly requests delivery. Missing actions are hidden.
  final ValueChanged<CarpenterRecordingKind>? onRecordingPause;

  /// Resumes the host session when paused; absent capabilities remain hidden.
  final ValueChanged<CarpenterRecordingKind>? onRecordingResume;

  /// Previews the prepared bytes without modifying the text draft or sending.
  final ValueChanged<CarpenterRecordingKind>? onRecordingPreview;

  /// Explicit delivery request; the host retains preview bytes on failure.
  final ValueChanged<CarpenterRecordingKind>? onRecordingSend;

  /// Explicitly discards prepared bytes and starts a fresh host recording.
  final ValueChanged<CarpenterRecordingKind>? onRecordingRerecord;

  @override
  State<CarpenterChatComposer> createState() => _CarpenterChatComposerState();
}

final class _CarpenterChatComposerState extends State<CarpenterChatComposer> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.view.text,
  );
  late final FocusNode _textFocusNode = FocusNode()
    ..addListener(_handleTextFocusChanged);
  bool _sendMenuOpen = false;
  final GlobalKey _recordingKey = GlobalKey();

  void _handleTextFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CarpenterChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.view.text != oldWidget.view.text &&
        _controller.text == oldWidget.view.text) {
      _controller.value = TextEditingValue(
        text: widget.view.text,
        selection: TextSelection.collapsed(offset: widget.view.text.length),
      );
    }
  }

  @override
  void dispose() {
    _textFocusNode
      ..removeListener(_handleTextFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !_recordingActive &&
      !widget.view.readOnly &&
      !widget.view.busy &&
      (_controller.text.trim().isNotEmpty ||
          widget.view.attachments.isNotEmpty);

  bool get _recordingActive => switch (widget.recording.phase) {
    CarpenterRecordingPhase.idle ||
    CarpenterRecordingPhase.failed ||
    CarpenterRecordingPhase.unavailable => false,
    _ => true,
  };

  bool get _recordingSessionControls => switch (widget.recording.phase) {
    CarpenterRecordingPhase.locked ||
    CarpenterRecordingPhase.paused ||
    CarpenterRecordingPhase.preview => true,
    _ => false,
  };

  void _send(CarpenterSendMode mode) {
    if (!_canSend ||
        (_controller.value.composing.isValid &&
            !_controller.value.composing.isCollapsed)) {
      return;
    }
    if (_sendMenuOpen) setState(() => _sendMenuOpen = false);
    widget.onSendRequested(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    if (widget.view.readOnly) {
      return ColoredBox(
        color: theme.surface.base,
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: const CarpenterText.body(
            'В этом чате доступно только чтение.',
            colorRole: ContentColorRole.secondary,
          ),
        ),
      );
    }
    return ColoredBox(
      color: theme.surface.base,
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.view.replyPreview case final preview?)
              _ComposerReplyPreview(
                preview: preview,
                onRemoved: widget.onReplyRemoved,
              ),
            CarpenterComposerAttachmentTray(
              items: widget.view.attachments,
              onRemoved: widget.onAttachmentRemoved,
            ),
            FocusRing(
              visible: _textFocusNode.hasFocus,
              borderRadius: BorderRadius.circular(
                context.units(theme.shapes.radius(ShapeRole.rounded)),
              ),
              child: DecoratedBox(
                key: const ValueKey('composer-input-surface'),
                decoration: BoxDecoration(
                  color: theme.surface.subtle,
                  borderRadius: BorderRadius.circular(
                    context.units(theme.shapes.radius(ShapeRole.rounded)),
                  ),
                ),
                child: _recordingSessionControls
                    ? _recordingControl()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CarpenterIconButton(
                            icon: GravityIcons.paperclip,
                            semanticLabel: 'Прикрепить файлы',
                            onPressed: widget.view.busy || _recordingActive
                                ? null
                                : widget.onAttachmentsRequested,
                            prominence: ActionProminence.ghost,
                          ),
                          Expanded(
                            child: Focus(
                              onKeyEvent: (_, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter &&
                                    !HardwareKeyboard.instance.isShiftPressed) {
                                  _send(CarpenterSendMode.ordinary);
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: CarpenterTextArea(
                                controller: _controller,
                                focusNode: _textFocusNode,
                                placeholder: 'Написать сообщение…',
                                semanticLabel: 'Сообщение',
                                minLines: 1,
                                maxLines: 4,
                                presentation:
                                    CarpenterFieldPresentation.seamless,
                                availability:
                                    widget.view.busy || _recordingActive
                                    ? FieldAvailability.disabled
                                    : FieldAvailability.enabled,
                                onChanged: (value) {
                                  setState(() {});
                                  widget.onTextChanged(value);
                                },
                              ),
                            ),
                          ),
                          if (_canSend) _sendControl() else _recordingControl(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sendControl() => Semantics(
    customSemanticsActions: {
      const CustomSemanticsAction(label: 'Варианты отправки'): () =>
          setState(() => _sendMenuOpen = true),
    },
    child: CarpenterPopover(
      open: _sendMenuOpen,
      onOpenChanged: (value) => setState(() => _sendMenuOpen = value),
      content: CarpenterMenu(
        semanticLabel: 'Варианты отправки',
        onDismissRequested: () => setState(() => _sendMenuOpen = false),
        items: [
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'send-ordinary',
              label: 'Обычное',
              icon: GravityIcons.paperPlane,
              onInvoke: () => _send(CarpenterSendMode.ordinary),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'send-important',
              label: 'Важное',
              icon: GravityIcons.exclamationShape,
              colorRole: ActionColorRole.danger,
              onInvoke: () => _send(CarpenterSendMode.important),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'send-requires-answer',
              label: 'Требует ответа',
              icon: GravityIcons.circleQuestion,
              colorRole: ActionColorRole.danger,
              onInvoke: () => _send(CarpenterSendMode.requiresAnswer),
            ),
          ),
        ],
      ),
      anchorActivates: false,
      anchor: CarpenterIconButton(
        icon: GravityIcons.paperPlane,
        semanticLabel: 'Отправить',
        onPressed: () => _send(CarpenterSendMode.ordinary),
        onLongPress: () => setState(() => _sendMenuOpen = true),
        onSecondaryTap: () => setState(() => _sendMenuOpen = true),
        prominence: ActionProminence.high,
      ),
    ),
  );

  Widget _recordingControl() => CarpenterRecordingControl(
    key: _recordingKey,
    view: widget.recording,
    onModeChanged: widget.onRecordingModeChanged,
    onStart: widget.onRecordingStart,
    onLock: widget.onRecordingLock,
    onStop: widget.onRecordingStop,
    onCancel: widget.onRecordingCancel,
    onPause: widget.onRecordingPause,
    onResume: widget.onRecordingResume,
    onPreview: widget.onRecordingPreview,
    onSend: widget.onRecordingSend,
    onRerecord: widget.onRecordingRerecord,
  );
}

final class _ComposerReplyPreview extends StatelessWidget {
  const _ComposerReplyPreview({required this.preview, this.onRemoved});

  final String preview;
  final VoidCallback? onRemoved;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Row(
      children: [
        Expanded(
          child: CarpenterText.caption(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            emphasis: TypographyEmphasis.medium,
          ),
        ),
        SizedBox(width: gap),
        CarpenterIconButton(
          icon: GravityIcons.xmark,
          semanticLabel: 'Убрать ответ',
          onPressed: onRemoved,
          prominence: ActionProminence.ghost,
          size: ControlSize.small,
        ),
      ],
    );
  }
}
