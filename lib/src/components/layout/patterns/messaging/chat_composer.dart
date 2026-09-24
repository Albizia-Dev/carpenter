import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/input/text_area.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
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

  @override
  State<CarpenterChatComposer> createState() => _CarpenterChatComposerState();
}

final class _CarpenterChatComposerState extends State<CarpenterChatComposer> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.view.text,
  );
  bool _sendMenuOpen = false;
  Timer? _sendHoldTimer;

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
    _sendHoldTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !widget.view.readOnly &&
      !widget.view.busy &&
      (_controller.text.trim().isNotEmpty ||
          widget.view.attachments.isNotEmpty);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CarpenterIconButton(
                  icon: GravityIcons.paperclip,
                  semanticLabel: 'Прикрепить файлы',
                  onPressed: widget.view.busy
                      ? null
                      : widget.onAttachmentsRequested,
                  prominence: ActionProminence.ghost,
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _send(CarpenterSendMode.ordinary);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: CarpenterTextArea(
                      controller: _controller,
                      placeholder: 'Написать сообщение…',
                      semanticLabel: 'Сообщение',
                      minLines: 1,
                      maxLines: 4,
                      availability: widget.view.busy
                          ? FieldAvailability.disabled
                          : FieldAvailability.enabled,
                      onChanged: (value) {
                        setState(() {});
                        widget.onTextChanged(value);
                      },
                    ),
                  ),
                ),
                SizedBox(width: gap),
                if (_canSend) _sendControl() else _recordingControl(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sendControl() => Listener(
    onPointerDown: (_) {
      _sendHoldTimer?.cancel();
      _sendHoldTimer = Timer(kLongPressTimeout, () {
        if (mounted) setState(() => _sendMenuOpen = true);
      });
    },
    onPointerUp: (_) => _sendHoldTimer?.cancel(),
    onPointerCancel: (_) => _sendHoldTimer?.cancel(),
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
              onInvoke: () => _send(CarpenterSendMode.ordinary),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'send-important',
              label: 'Важное',
              colorRole: ActionColorRole.danger,
              onInvoke: () => _send(CarpenterSendMode.important),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'send-requires-answer',
              label: 'Требует ответа',
              colorRole: ActionColorRole.danger,
              onInvoke: () => _send(CarpenterSendMode.requiresAnswer),
            ),
          ),
        ],
      ),
      anchor: CarpenterIconButton(
        icon: GravityIcons.paperPlane,
        semanticLabel: 'Отправить',
        onPressed: () => _send(CarpenterSendMode.ordinary),
        prominence: ActionProminence.high,
      ),
    ),
  );

  Widget _recordingControl() => CarpenterRecordingControl(
    view: widget.recording,
    onModeChanged: widget.onRecordingModeChanged,
    onStart: widget.onRecordingStart,
    onLock: widget.onRecordingLock,
    onStop: widget.onRecordingStop,
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
