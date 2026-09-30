import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/checkbox.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/link.dart';
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
    this.onLinkInvoked,
    this.mediaPreviewBuilder,
    this.mediaExpandedPreviewBuilder,
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

  /// Opens a URL found in the visible message body.
  final ValueChanged<Uri>? onLinkInvoked;
  final CarpenterMediaPreviewBuilder? mediaPreviewBuilder;
  final CarpenterMediaExpandedPreviewBuilder? mediaExpandedPreviewBuilder;
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
  double _replyOffset = 0;

  void _invoke(VoidCallback callback) {
    setState(() => _menuOpen = false);
    callback();
  }

  void _completePointerGesture(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final threshold = context.units(theme.sizes.control(ControlSize.large));
    final direction = Directionality.of(context);
    final logicalDelta = direction == TextDirection.ltr
        ? _pointerDelta.dx
        : -_pointerDelta.dx;
    if (logicalDelta <= -threshold &&
        logicalDelta.abs() > _pointerDelta.dy.abs()) {
      widget.onReplyRequested?.call();
    }
    setState(() {
      _pointerOrigin = null;
      _pointerDelta = Offset.zero;
      _replyOffset = 0;
    });
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
    final standaloneMedia = _isStandaloneMedia(message);
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
        minWidth: standaloneMedia ? 0 : context.units(theme.sizes.tableColumn),
        maxWidth: context.units(theme.sizes.layoutSecondary),
      ),
      child: Listener(
        onPointerDown: (event) {
          _pointerOrigin = event.position;
          _pointerDelta = Offset.zero;
          _replyOffset = 0;
        },
        onPointerMove: (event) {
          final origin = _pointerOrigin;
          if (origin == null || widget.onReplyRequested == null) return;
          final delta = event.position - origin;
          final direction = Directionality.of(context);
          final logicalDelta = direction == TextDirection.ltr
              ? delta.dx
              : -delta.dx;
          final threshold = context.units(
            theme.sizes.control(ControlSize.large),
          );
          setState(() {
            _pointerDelta = delta;
            _replyOffset = logicalDelta < 0
                ? logicalDelta.clamp(-threshold, 0).toDouble()
                : 0;
          });
        },
        onPointerCancel: (_) {
          setState(() {
            _pointerOrigin = null;
            _pointerDelta = Offset.zero;
            _replyOffset = 0;
          });
        },
        onPointerUp: (_) => _completePointerGesture(context),
        child: Stack(
          fit: StackFit.passthrough,
          alignment: message.own
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          clipBehavior: Clip.none,
          children: [
            if (_replyOffset != 0)
              PositionedDirectional(
                end: 0,
                child: Opacity(
                  key: ValueKey('message-reply-affordance-${message.id}'),
                  opacity:
                      (_replyOffset.abs() /
                              context.units(
                                theme.sizes.control(ControlSize.large),
                              ))
                          .clamp(0, 1),
                  child: const CarpenterIcon(
                    GravityIcons.arrowShapeTurnUpLeft,
                    semanticLabel: 'Ответить',
                    colorRole: ContentColorRole.secondary,
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(
                Directionality.of(context) == TextDirection.ltr
                    ? _replyOffset
                    : -_replyOffset,
                0,
              ),
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
                      onTap:
                          widget.selectionMode &&
                              widget.onSelectionChanged != null
                          ? () => widget.onSelectionChanged!(!widget.selected)
                          : null,
                      child: TweenAnimationBuilder<Color?>(
                        duration: theme.motion.transitionDuration(context),
                        curve: theme.motion.stateCurve,
                        tween: ColorTween(end: bubbleColor),
                        builder: (context, color, child) {
                          final emphasized =
                              widget.selected ||
                              message.meta.important ||
                              message.meta.requiresAnswer;
                          return DecoratedBox(
                            key: ValueKey('message-bubble-${message.id}'),
                            decoration: BoxDecoration(
                              color: standaloneMedia ? null : color,
                              borderRadius: BorderRadius.circular(
                                context.units(
                                  theme.shapes.radius(ShapeRole.rounded),
                                ),
                              ),
                              border: standaloneMedia && !emphasized
                                  ? null
                                  : Border.all(
                                      color: standaloneMedia
                                          ? widget.selected
                                                ? theme.actions.primary.normal
                                                : theme.feedback
                                                      .resolve(
                                                        FeedbackColorRole
                                                            .danger,
                                                      )
                                                      .foreground
                                          : theme.overlay.border,
                                      width: context.units(
                                        theme.shapes.fieldBorderWidth,
                                      ),
                                    ),
                            ),
                            child: child,
                          );
                        },
                        child: standaloneMedia
                            ? _standaloneMedia(context, message.media.single)
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.units(
                                    theme.spacing.medium,
                                  ),
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
                                    if (message.replyPreview
                                        case final preview?)
                                      _ReplyPreview(
                                        preview: preview,
                                        onPressed: widget.onReplyPreviewInvoked,
                                      ),
                                    if (message.meta.forwardedFrom
                                        case final author?)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CarpenterIcon(
                                            GravityIcons.forwardStep,
                                            size: IconSize.small,
                                            semanticLabel: 'Переслано',
                                          ),
                                          SizedBox(
                                            width: context.units(
                                              theme.spacing.xsmall,
                                            ),
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
                                      _inlineMedia(
                                        context,
                                        media,
                                        padded: true,
                                      ),
                                    if (message.body.isNotEmpty)
                                      _MessageBody(
                                        body: message.body,
                                        onLinkInvoked: widget.onLinkInvoked,
                                      ),
                                    SizedBox(
                                      height: context.units(
                                        theme.spacing.xsmall,
                                      ),
                                    ),
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
                    return standaloneMedia
                        ? Align(widthFactor: 1, child: anchor)
                        : message.media.isEmpty
                        ? IntrinsicWidth(child: anchor)
                        : anchor;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStandaloneMedia(CarpenterMessageView message) =>
      message.body.isEmpty &&
      message.media.length == 1 &&
      !widget.showAuthor &&
      message.replyPreview == null &&
      message.meta.forwardedFrom == null;

  Widget _standaloneMedia(BuildContext context, CarpenterMediaView media) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.xsmall);
    final visual =
        media.kind == CarpenterMediaKind.image ||
        media.kind == CarpenterMediaKind.video ||
        media.kind == CarpenterMediaKind.videoCircle;
    final metadata = _MessageMetadata(
      message: widget.message,
      inverse: visual,
      leading: widget.metadataLeading,
      trailing: widget.metadataTrailing,
    );
    if (!visual) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _inlineMedia(context, media),
          Padding(
            padding: EdgeInsetsDirectional.only(top: gap, end: gap),
            child: metadata,
          ),
        ],
      );
    }
    return Stack(
      children: [
        _inlineMedia(context, media),
        PositionedDirectional(
          end: gap,
          bottom: gap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.overlay.scrim,
              borderRadius: BorderRadius.circular(
                context.units(theme.shapes.radius(ShapeRole.rounded)),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap / 2),
              child: metadata,
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineMedia(
    BuildContext context,
    CarpenterMediaView media, {
    bool padded = false,
  }) {
    final child = CarpenterInlineMedia(
      key: ValueKey('message-media-${media.id}'),
      view: media,
      preview: widget.mediaPreviewBuilder?.call(context, media),
      expandedPreview: widget.mediaExpandedPreviewBuilder?.call(context, media),
      onLoadRequested: widget.onMediaLoadRequested == null
          ? null
          : () => widget.onMediaLoadRequested!(media.id),
      onPlayPauseRequested: widget.onMediaPlayPauseRequested == null
          ? null
          : () => widget.onMediaPlayPauseRequested!(media.id),
      onSeekRequested: widget.onMediaSeekRequested == null
          ? null
          : (position) => widget.onMediaSeekRequested!(media.id, position),
      onSpeedChanged: widget.onMediaSpeedChanged == null
          ? null
          : (speed) => widget.onMediaSpeedChanged!(media.id, speed),
      onFocusChanged: widget.onMediaFocusChanged == null
          ? null
          : (focused) => widget.onMediaFocusChanged!(media.id, focused),
    );
    if (!padded) return child;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.units(CarpenterTheme.of(context).spacing.xsmall),
      ),
      child: child,
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

final class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.body, this.onLinkInvoked});

  final String body;
  final ValueChanged<Uri>? onLinkInvoked;
  static final RegExp _urlPattern = RegExp(
    r'(?:(?:https?|ftp)://|www\.)[^\s<>()]+',
    caseSensitive: false,
  );
  static final RegExp _trailingPunctuation = RegExp(r'[.,!?;:]+$');

  List<({String text, Uri? uri})> _segments() {
    final segments = <({String text, Uri? uri})>[];
    var cursor = 0;
    for (final match in _urlPattern.allMatches(body)) {
      var label = match.group(0)!;
      final punctuation = _trailingPunctuation.firstMatch(label)?.group(0);
      if (punctuation != null) {
        label = label.substring(0, label.length - punctuation.length);
      }
      if (label.isEmpty) continue;
      if (match.start > cursor) {
        segments.add((text: body.substring(cursor, match.start), uri: null));
      }
      final uri = Uri.tryParse(
        label.startsWith('www.') ? 'https://$label' : label,
      );
      segments.add((text: label, uri: uri));
      if (punctuation != null) {
        segments.add((text: punctuation, uri: null));
      }
      cursor = match.end;
    }
    if (cursor < body.length) {
      segments.add((text: body.substring(cursor), uri: null));
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    if (onLinkInvoked == null) {
      return CarpenterText.body(body, colorRole: ContentColorRole.primary);
    }
    final theme = CarpenterTheme.of(context);
    final bodyStyle = theme.typography
        .resolve(context, TypographyRole.body, TypographyEmphasis.regular)
        .copyWith(color: theme.content.resolve(ContentColorRole.primary));
    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          for (final segment in _segments())
            if (segment.uri case final uri?)
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: CarpenterLink(
                  label: segment.text,
                  semanticLabel: 'Открыть ссылку ${segment.text}',
                  role: CarpenterLinkRole.inline,
                  underline: CarpenterLinkUnderline.always,
                  onInvoke: () => onLinkInvoked!(uri),
                ),
              )
            else
              TextSpan(text: segment.text),
        ],
      ),
    );
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
