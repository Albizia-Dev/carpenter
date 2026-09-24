import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/gestures.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/input/text_area.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Controlled chat composer with attachment and voice affordances.
/// The host owns text, media recording, upload, and send semantics.
final class CarpenterChatComposer extends StatefulWidget {
  const CarpenterChatComposer({
    super.key,
    required this.text,
    required this.onTextChanged,
    required this.onSend,
    this.onFilesRequested,
    this.onVoiceRecord,
    this.onVoiceStop,
    this.recording = false,
    this.hasAttachments = false,
    this.enabled = true,
  });

  final String text;
  final ValueChanged<String> onTextChanged;
  final VoidCallback? onSend;
  final VoidCallback? onFilesRequested;
  final VoidCallback? onVoiceRecord;
  final VoidCallback? onVoiceStop;
  final bool recording;
  final bool hasAttachments;
  final bool enabled;

  @override
  State<CarpenterChatComposer> createState() => _CarpenterChatComposerState();
}

class _CarpenterChatComposerState extends State<CarpenterChatComposer> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  bool _videoMode = false;
  bool _locked = false;
  bool _sendMenuOpen = false;
  Timer? _holdTimer;
  bool _holdingVoice = false;
  bool _suppressTap = false;
  Offset? _pressOrigin;

  @override
  void didUpdateWidget(covariant CarpenterChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && _controller.text == oldWidget.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
    if (oldWidget.recording && !widget.recording) _locked = false;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (!widget.enabled ||
        widget.onSend == null ||
        _controller.value.composing.isValid &&
            !_controller.value.composing.isCollapsed) {
      return;
    }
    if (_controller.text.trim().isNotEmpty || widget.hasAttachments) {
      widget.onSend!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final canSend = _controller.text.trim().isNotEmpty || widget.hasAttachments;
    if (!widget.enabled) {
      return Padding(
        padding: EdgeInsets.all(gap),
        child: const CarpenterText.body(
          'В этом разговоре доступно только чтение.',
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.recording)
            CarpenterText.caption(
              _locked
                  ? 'Запись закреплена · завершите кнопкой'
                  : 'Идёт запись · потяните вверх для закрепления',
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CarpenterIconButton(
                icon: GravityIcons.paperclip,
                semanticLabel: 'Прикрепить файлы',
                onPressed: widget.onFilesRequested,
                prominence: ActionProminence.ghost,
              ),
              SizedBox(width: gap),
              Expanded(
                child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _send();
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
                    onChanged: (value) {
                      setState(() {});
                      widget.onTextChanged(value);
                    },
                  ),
                ),
              ),
              SizedBox(width: gap),
              if (canSend)
                GestureDetector(
                  onLongPress: () => setState(() => _sendMenuOpen = true),
                  child: CarpenterPopover(
                    open: _sendMenuOpen,
                    onOpenChanged: (value) =>
                        setState(() => _sendMenuOpen = value),
                    content: CarpenterMenu(
                      semanticLabel: 'Варианты отправки',
                      onDismissRequested: () =>
                          setState(() => _sendMenuOpen = false),
                      items: [
                        CarpenterMenuItem(
                          action: CarpenterActionDescriptor(
                            id: 'send-default',
                            label: 'Отправить',
                            onInvoke: _send,
                          ),
                        ),
                        const CarpenterMenuItem(
                          action: CarpenterActionDescriptor(
                            id: 'send-important',
                            label: 'Важное · пока недоступно',
                            onInvoke: null,
                          ),
                        ),
                        const CarpenterMenuItem(
                          action: CarpenterActionDescriptor(
                            id: 'send-need-answer',
                            label: 'Требует ответа · пока недоступно',
                            onInvoke: null,
                          ),
                        ),
                      ],
                    ),
                    anchor: CarpenterIconButton(
                      icon: GravityIcons.paperPlane,
                      semanticLabel: 'Отправить',
                      onPressed: widget.onSend == null ? null : _send,
                      prominence: ActionProminence.high,
                    ),
                  ),
                )
              else
                Listener(
                  onPointerDown: (event) {
                    _suppressTap = false;
                    _pressOrigin = event.position;
                    if (_videoMode || widget.onVoiceRecord == null) return;
                    _holdTimer?.cancel();
                    _holdTimer = Timer(kLongPressTimeout, () {
                      if (!mounted || _pressOrigin == null) return;
                      _holdingVoice = true;
                      _suppressTap = true;
                      widget.onVoiceRecord?.call();
                    });
                  },
                  onPointerMove: (event) {
                    if (!_holdingVoice || _locked || _pressOrigin == null) {
                      return;
                    }
                    if (event.position.dy - _pressOrigin!.dy <
                        -context.units(theme.sizes.minimumTarget)) {
                      setState(() => _locked = true);
                    }
                  },
                  onPointerUp: (_) {
                    _holdTimer?.cancel();
                    _pressOrigin = null;
                    if (_holdingVoice && !_locked) widget.onVoiceStop?.call();
                    _holdingVoice = false;
                  },
                  onPointerCancel: (_) {
                    _holdTimer?.cancel();
                    _pressOrigin = null;
                    if (_holdingVoice && !_locked) widget.onVoiceStop?.call();
                    _holdingVoice = false;
                  },
                  child: CarpenterIconButton(
                    icon: _videoMode
                        ? GravityIcons.video
                        : GravityIcons.microphone,
                    semanticLabel: _videoMode
                        ? 'Переключить на голосовое сообщение'
                        : 'Переключить на видеосообщение',
                    onPressed: () {
                      if (_suppressTap || _holdingVoice || widget.recording) {
                        return;
                      }
                      setState(() => _videoMode = !_videoMode);
                    },
                    prominence: ActionProminence.ghost,
                  ),
                ),
            ],
          ),
          if (_videoMode && !canSend)
            const CarpenterText.caption('Видеосообщения пока недоступны'),
        ],
      ),
    );
  }
}
