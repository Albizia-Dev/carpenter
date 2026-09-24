import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/checkbox.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
import 'inline_media.dart';
import 'messaging_models.dart';

/// Controlled message bubble with pointer/touch actions and horizontal reply.
final class CarpenterMessageBubble extends StatefulWidget {
  const CarpenterMessageBubble({
    super.key,
    required this.message,
    required this.selected,
    required this.selectionMode,
    this.showAuthor = true,
    this.onSelectionChanged,
    this.onReplyRequested,
    this.onRetryRequested,
    this.onReplyPreviewInvoked,
    this.mediaPreviewBuilder,
    this.onMediaLoadRequested,
    this.onMediaPlayPauseRequested,
    this.onMediaSeekRequested,
    this.onMediaSpeedChanged,
    this.onMediaFocusChanged,
    this.metadataLeading = const [],
    this.metadataTrailing = const [],
  });

  final CarpenterMessageView message;
  final bool selected;
  final bool selectionMode;
  final bool showAuthor;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onReplyRequested;
  final VoidCallback? onRetryRequested;
  final VoidCallback? onReplyPreviewInvoked;
  final CarpenterMediaPreviewBuilder? mediaPreviewBuilder;
  final ValueChanged<String>? onMediaLoadRequested;
  final ValueChanged<String>? onMediaPlayPauseRequested;
  final CarpenterMediaSeekRequested? onMediaSeekRequested;
  final CarpenterMediaSpeedChanged? onMediaSpeedChanged;
  final CarpenterMediaFocusChanged? onMediaFocusChanged;
  final List<Widget> metadataLeading;
  final List<Widget> metadataTrailing;

  @override
  State<CarpenterMessageBubble> createState() => _CarpenterMessageBubbleState();
}

final class _CarpenterMessageBubbleState extends State<CarpenterMessageBubble> {
  bool _menuOpen = false;
  Offset? _pointerOrigin;
  Offset _pointerDelta = Offset.zero;

  void _invoke(VoidCallback callback) {
    setState(() => _menuOpen = false);
    callback();
  }

  void _completePointerGesture(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final threshold = context.units(theme.sizes.control(ControlSize.large));
    if (_pointerDelta.dx <= -threshold &&
        _pointerDelta.dx.abs() > _pointerDelta.dy.abs()) {
      widget.onReplyRequested?.call();
    }
    _pointerOrigin = null;
    _pointerDelta = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final showSelection = widget.selectionMode || widget.selected;
    final selection = showSelection
        ? KeyedSubtree(
            key: ValueKey('message-selection-${message.id}'),
            child: CarpenterCheckbox(
              value: widget.selected
                  ? CheckboxValue.checked
                  : CheckboxValue.unchecked,
              label: '',
              semanticLabel: widget.selected
                  ? 'Снять выбор сообщения'
                  : 'Выбрать сообщение',
              onChanged: widget.onSelectionChanged == null
                  ? null
                  : (value) => widget.onSelectionChanged!(
                      value == CheckboxValue.checked,
                    ),
            ),
          )
        : null;
    return Align(
      alignment: message.own
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.own && selection != null) ...[selection],
          Flexible(child: _bubble(context)),
          if (!message.own && selection != null) ...[selection],
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context) {
    final message = widget.message;
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final semanticBase = message.meta.important || message.meta.requiresAnswer
        ? theme.feedback.resolve(FeedbackColorRole.danger).background
        : message.own
        ? Color.alphaBlend(theme.actions.primary.state, theme.surface.base)
        : theme.surface.base;
    final bubbleColor = widget.selected
        ? Color.alphaBlend(theme.actions.primary.strongState, semanticBase)
        : semanticBase;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: context.units(theme.sizes.tableColumn),
        maxWidth: context.units(theme.sizes.layoutSecondary),
      ),
      child: Listener(
        onPointerDown: (event) {
          _pointerOrigin = event.position;
          _pointerDelta = Offset.zero;
        },
        onPointerMove: (event) {
          final origin = _pointerOrigin;
          if (origin != null) _pointerDelta = event.position - origin;
        },
        onPointerCancel: (_) {
          _pointerOrigin = null;
          _pointerDelta = Offset.zero;
        },
        onPointerUp: (_) => _completePointerGesture(context),
        child: CarpenterPopover(
          open: _menuOpen,
          onOpenChanged: (open) => setState(() => _menuOpen = open),
          anchorActivates: false,
          content: CarpenterMenu(
            semanticLabel: 'Действия с сообщением',
            onDismissRequested: () => setState(() => _menuOpen = false),
            items: _menuItems(),
          ),
          anchor: Builder(
            builder: (context) {
              final anchor = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTap: () => setState(() => _menuOpen = true),
                onLongPress: () => setState(() => _menuOpen = true),
                onTap: widget.selectionMode && widget.onSelectionChanged != null
                    ? () => widget.onSelectionChanged!(!widget.selected)
                    : null,
                child: TweenAnimationBuilder<Color?>(
                  duration: theme.motion.transitionDuration(context),
                  curve: theme.motion.stateCurve,
                  tween: ColorTween(end: bubbleColor),
                  builder: (context, color, child) => DecoratedBox(
                    key: ValueKey('message-bubble-${message.id}'),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        context.units(theme.shapes.radius(ShapeRole.rounded)),
                      ),
                      border: Border.all(
                        color: theme.overlay.border,
                        width: context.units(theme.shapes.fieldBorderWidth),
                      ),
                    ),
                    child: child,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.units(theme.spacing.medium),
                      vertical: gap,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showAuthor && !message.own)
                          CarpenterText.label(
                            message.authorLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            emphasis: TypographyEmphasis.strong,
                          ),
                        if (message.replyPreview case final preview?)
                          _ReplyPreview(
                            preview: preview,
                            onPressed: widget.onReplyPreviewInvoked,
                          ),
                        if (message.meta.forwardedFrom case final author?)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CarpenterIcon(
                                GravityIcons.forwardStep,
                                size: IconSize.small,
                                semanticLabel: 'Переслано',
                              ),
                              SizedBox(
                                width: context.units(theme.spacing.xsmall),
                              ),
                              Flexible(
                                child: CarpenterText.caption(
                                  'Переслано от $author',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        for (final media in message.media)
                          Padding(
                            key: ValueKey('message-media-${media.id}'),
                            padding: EdgeInsets.symmetric(
                              vertical: context.units(theme.spacing.xsmall),
                            ),
                            child: CarpenterInlineMedia(
                              view: media,
                              preview: widget.mediaPreviewBuilder?.call(
                                context,
                                media,
                              ),
                              onLoadRequested:
                                  widget.onMediaLoadRequested == null
                                  ? null
                                  : () =>
                                        widget.onMediaLoadRequested!(media.id),
                              onPlayPauseRequested:
                                  widget.onMediaPlayPauseRequested == null
                                  ? null
                                  : () => widget.onMediaPlayPauseRequested!(
                                      media.id,
                                    ),
                              onSeekRequested:
                                  widget.onMediaSeekRequested == null
                                  ? null
                                  : (position) => widget.onMediaSeekRequested!(
                                      media.id,
                                      position,
                                    ),
                              onSpeedChanged: widget.onMediaSpeedChanged == null
                                  ? null
                                  : (speed) => widget.onMediaSpeedChanged!(
                                      media.id,
                                      speed,
                                    ),
                              onFocusChanged: widget.onMediaFocusChanged == null
                                  ? null
                                  : (focused) => widget.onMediaFocusChanged!(
                                      media.id,
                                      focused,
                                    ),
                            ),
                          ),
                        if (message.body.isNotEmpty)
                          CarpenterText.body(
                            message.body,
                            colorRole: ContentColorRole.primary,
                          ),
                        SizedBox(height: context.units(theme.spacing.xsmall)),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _MessageMetadata(
                            message: message,
                            inverse: false,
                            leading: widget.metadataLeading,
                            trailing: widget.metadataTrailing,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              return message.media.isEmpty
                  ? IntrinsicWidth(child: anchor)
                  : anchor;
            },
          ),
        ),
      ),
    );
  }

  List<CarpenterMenuItem> _menuItems() {
    final message = widget.message;
    return [
      if (message.canReply && widget.onReplyRequested != null)
        CarpenterMenuItem(
          action: CarpenterActionDescriptor(
            id: 'reply-message',
            label: 'Ответить',
            icon: GravityIcons.arrowShapeTurnUpLeft,
            colorRole: ActionColorRole.primary,
            onInvoke: () => _invoke(widget.onReplyRequested!),
          ),
        ),
      if (widget.onSelectionChanged != null)
        CarpenterMenuItem(
          action: CarpenterActionDescriptor(
            id: 'select-message',
            label: widget.selected ? 'Снять выбор' : 'Выбрать',
            icon: widget.selected
                ? GravityIcons.squareXmark
                : GravityIcons.squareCheck,
            colorRole: ActionColorRole.utility,
            onInvoke: () =>
                _invoke(() => widget.onSelectionChanged!(!widget.selected)),
          ),
        ),
      CarpenterMenuItem(
        action: CarpenterActionDescriptor(
          id: 'copy-message',
          label: 'Скопировать',
          icon: GravityIcons.copy,
          onInvoke: () => _invoke(
            () => Clipboard.setData(ClipboardData(text: message.body)),
          ),
        ),
      ),
      if (message.canRetry && widget.onRetryRequested != null)
        CarpenterMenuItem(
          action: CarpenterActionDescriptor(
            id: 'retry-message',
            label: 'Повторить',
            icon: GravityIcons.arrowRotateRight,
            colorRole: ActionColorRole.warning,
            onInvoke: () => _invoke(widget.onRetryRequested!),
          ),
        ),
    ];
  }
}

final class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.preview, this.onPressed});

  final String preview;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final separator = preview.indexOf(':');
    final author = separator > 0 ? preview.substring(0, separator) : null;
    final body = separator > 0
        ? preview.substring(separator + 1).trimLeft()
        : preview;
    return GestureDetector(
      onTap: onPressed,
      child: Semantics(
        button: onPressed != null,
        label: 'Перейти к исходному сообщению',
        child: DecoratedBox(
          key: const ValueKey('message-reply-preview'),
          decoration: BoxDecoration(
            color: theme.surface.subtle,
            borderRadius: BorderRadius.circular(
              context.units(theme.shapes.radius(ShapeRole.rounded)),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: context.units(theme.shapes.fieldBorderWidth) * 2,
                  child: ColoredBox(color: theme.actions.primary.state),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.units(theme.spacing.xsmall),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (author != null)
                          CarpenterText.caption(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            emphasis: TypographyEmphasis.strong,
                          ),
                        CarpenterText.caption(
                          body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          emphasis: TypographyEmphasis.medium,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: gap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _MessageMetadata extends StatelessWidget {
  const _MessageMetadata({
    required this.message,
    required this.inverse,
    required this.leading,
    required this.trailing,
  });

  final CarpenterMessageView message;
  final bool inverse;
  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.xsmall);
    final meta = message.meta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final modifier in leading) ...[modifier, SizedBox(width: gap)],
        if (meta.important) ...[
          const CarpenterIcon.feedback(
            GravityIcons.exclamationShape,
            feedbackRole: FeedbackColorRole.danger,
            size: IconSize.small,
            semanticLabel: 'Важное',
          ),
          SizedBox(width: gap),
        ],
        if (meta.requiresAnswer) ...[
          const CarpenterIcon.feedback(
            GravityIcons.circleQuestion,
            feedbackRole: FeedbackColorRole.danger,
            size: IconSize.small,
            semanticLabel: 'Требует ответа',
          ),
          SizedBox(width: gap),
        ],
        if (meta.edited) ...[
          CarpenterIcon(
            GravityIcons.pencil,
            size: IconSize.small,
            semanticLabel: 'Изменено',
            colorRole: inverse
                ? ContentColorRole.inverse
                : ContentColorRole.secondary,
          ),
          SizedBox(width: gap),
        ],
        CarpenterText.caption(
          _localTime(message.sentAt),
          colorRole: inverse
              ? ContentColorRole.inverse
              : ContentColorRole.secondary,
        ),
        if (message.own && meta.delivery != null) ...[
          SizedBox(width: gap),
          CarpenterIcon(
            switch (meta.delivery!) {
              CarpenterDeliveryState.sending => GravityIcons.clock,
              CarpenterDeliveryState.sent => GravityIcons.check,
              CarpenterDeliveryState.read => GravityIcons.checkDouble,
              CarpenterDeliveryState.failed => GravityIcons.exclamationShape,
            },
            size: IconSize.small,
            semanticLabel: switch (meta.delivery!) {
              CarpenterDeliveryState.sending => 'Отправляется',
              CarpenterDeliveryState.sent => 'Отправлено',
              CarpenterDeliveryState.read => 'Прочитано',
              CarpenterDeliveryState.failed => 'Ошибка отправки',
            },
            colorRole: inverse
                ? ContentColorRole.inverse
                : ContentColorRole.secondary,
          ),
        ],
        for (final modifier in trailing) ...[SizedBox(width: gap), modifier],
      ],
    );
  }
}

String _localTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
