import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'messenger_recovery.dart';
import 'attachment_tray.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/adaptive.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/button/icon_button.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/avatar.dart';
import '../../../basic/button/button.dart';
import '../../../basic/checkbox.dart';
import '../../../basic/input/text_area.dart';
import '../../../basic/input/input.dart';
import '../../../basic/text.dart';
import '../../../behaviour/popover.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../collections/list_tile.dart';
import '../../master_detail.dart';
import '../../regions/region_role.dart';

/// Display-only conversation identity. Permissions are supplied by the host.
class CarpenterConversationItem {
  /// [id] is a stable key, [title] a readable name, [subtitle] a short context.
  const CarpenterConversationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.contextLabel,
    this.canSend = true,
  });

  /// Opaque key used for selection; never a list index.
  final String id;

  /// Primary conversation label.
  final String title;

  /// Preview or conversation kind; does not imply presence.
  final String subtitle;

  /// Optional ERP context, already resolved by the host.
  final String? contextLabel;

  /// Disables writing without hiding existing history.
  final bool canSend;
}

/// Display-only message. Delivery wording must reflect observed transport state.
class CarpenterMessageItem {
  /// [status] is readable delivery text, never an inferred recipient receipt.
  const CarpenterMessageItem({
    required this.id,
    required this.author,
    required this.text,
    required this.status,
    this.own = false,
    this.needAnswer = false,
    this.canRetry = false,
    this.authorKey,
    this.sentAt,
    this.timeLabel,
    this.replyPreview,
    this.canReply = false,
    this.replyTargetId,
    this.attachmentLabels = const [],
  });

  /// Resolved quotation or an unavailable-target label; never fetched by Carpenter.
  final String? replyPreview;

  /// The host has a confirmed target and permission to compose a reply.
  final bool canReply;

  /// Stable row key of a loaded original; null means unavailable in this view.
  final String? replyTargetId;

  /// Stable author identity for grouping. Null disables grouping; names are not identities.
  final String? authorKey;

  /// Host-local message time used only to bound consecutive-author grouping.
  final DateTime? sentAt;

  /// Localized clock time, independent from delivery/receipt wording.
  final String? timeLabel;

  /// Stable row key surviving local-to-server reconciliation.
  final String id;

  /// Visible author, independent of the transport's actor identifier.
  final String author;

  /// Message text or attachment caption; empty for a file-only message.
  final String text;

  /// Localized file names and sizes. Display only until a download action exists.
  /// The caller must keep this list immutable for the lifetime of the item.
  final List<String> attachmentLabels;

  /// Localized delivery state or timestamp supplied by the caller.
  final String status;

  /// Aligns the sender's messages at the end of the reading direction.
  final bool own;

  /// Explicit request for an answer; not a read/task completion marker.
  final bool needAnswer;

  /// Shows a retry action when the host can safely repeat this intent.
  final bool canRetry;
}

/// A semantic message surface with clipboard access and explicit recovery.
/// Requires an Overlay ancestor for the keyboard/pointer action menu.
class CarpenterMessageBubble extends StatefulWidget {
  /// [onRetry] must repeat the same logical intent, not compose a new message.
  const CarpenterMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.groupWithPrevious = false,
    this.onReply,
    this.onOpenReply,
  });

  /// Immutable display state owned by the caller.
  final CarpenterMessageItem message;

  /// Opens a controlled reply draft; null hides the menu action.
  final VoidCallback? onReply;

  /// Opens the quoted original; the workspace resolves its loaded row key.
  final VoidCallback? onOpenReply;

  /// Null disables retry even if the model permits it.
  final VoidCallback? onRetry;

  /// Compact continuation; the workspace only groups verified matching authors.
  final bool groupWithPrevious;

  /// Owns the transient action menu, never message or delivery state.
  @override
  State<CarpenterMessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<CarpenterMessageBubble> {
  bool _menuOpen = false;
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final radius = context.units(theme.shapes.radius(ShapeRole.rounded));
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = context.units(theme.sizes.layoutNarrowEnd);
        final available = constraints.maxWidth * .88;
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            gap,
            widget.groupWithPrevious ? gap / 4 : gap,
            gap,
            gap / 4,
          ),
          child: Align(
            alignment: message.own
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: available < maxWidth ? available : maxWidth,
              ),
              child: GestureDetector(
                onSecondaryTap: () => setState(() => _menuOpen = true),
                onLongPress: () => setState(() => _menuOpen = true),
                child: CarpenterPopover(
                  open: _menuOpen,
                  onOpenChanged: (open) => setState(() => _menuOpen = open),
                  content: CarpenterMenu(
                    semanticLabel: 'Действия с сообщением',
                    onDismissRequested: () => setState(() => _menuOpen = false),
                    items: [
                      if (message.canReply && widget.onReply != null)
                        CarpenterMenuItem(
                          action: CarpenterActionDescriptor(
                            id: 'reply-message',
                            label: 'Ответить',
                            onInvoke: widget.onReply,
                          ),
                        ),
                      CarpenterMenuItem(
                        action: CarpenterActionDescriptor(
                          id: 'copy-message',
                          label: 'Скопировать сообщение',
                          icon: GravityIcons.copy,
                          onInvoke: () => Clipboard.setData(
                            ClipboardData(
                              text: [
                                message.text,
                                ...message.attachmentLabels,
                              ].where((s) => s.isNotEmpty).join('\n'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  anchor: DecoratedBox(
                    decoration: BoxDecoration(
                      color: message.own
                          ? theme.actions.primary.state
                          : theme.surface.base,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gap * 1.5,
                        vertical: gap,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.own && !widget.groupWithPrevious) ...[
                            CarpenterText.label(
                              message.author,
                              emphasis: TypographyEmphasis.strong,
                            ),
                            SizedBox(height: gap / 2),
                          ],
                          if (message.replyPreview != null)
                            _ReplyPreview(
                              text: message.replyPreview!,
                              onOpen: widget.onOpenReply,
                            ),
                          for (final label in message.attachmentLabels)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: gap / 2),
                              child: CarpenterText.label(label),
                            ),
                          if (message.text.isNotEmpty)
                            CarpenterText.body(message.text),
                          if (message.needAnswer)
                            Padding(
                              padding: EdgeInsets.only(top: gap / 2),
                              child: const CarpenterText.caption(
                                'Нужен ответ',
                                emphasis: TypographyEmphasis.strong,
                              ),
                            ),
                          SizedBox(height: gap / 2),
                          Wrap(
                            spacing: gap,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (message.timeLabel != null)
                                CarpenterText.caption(
                                  message.timeLabel!,
                                  colorRole: ContentColorRole.secondary,
                                ),
                              if (message.status.isNotEmpty)
                                CarpenterText.caption(
                                  message.status,
                                  colorRole: ContentColorRole.secondary,
                                ),
                              if (message.canRetry)
                                CarpenterButton.text(
                                  label: 'Повторить',
                                  size: ControlSize.small,
                                  onPressed: widget.onRetry,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Controlled text/NeedAnswer composer. Controller only owns editing mechanics.
/// Enter sends, Shift+Enter inserts a line; IME composition never submits.
class CarpenterMessageComposer extends StatefulWidget {
  /// Caller owns [text], [needAnswer] and submission. Null send disables sending.
  const CarpenterMessageComposer({
    super.key,
    required this.text,
    required this.needAnswer,
    required this.onTextChanged,
    required this.onNeedAnswerChanged,
    required this.onSend,
    this.enabled = true,
    this.hasAttachments = false,
    this.replyPreview,
    this.onCancelReply,
  });

  /// Current reply quotation; null means an ordinary message.
  final String? replyPreview;

  /// Clears only the reply relation, preserving text and NeedAnswer.
  final VoidCallback? onCancelReply;

  /// Current draft text; echoed updates preserve selection and newer typing.
  final String text;

  /// Draft's explicit request-for-answer flag.
  final bool needAnswer;

  /// Receives every edit; must not discard newer drafts on a delayed save.
  final ValueChanged<String> onTextChanged;

  /// Receives the next request-for-answer flag.
  final ValueChanged<bool> onNeedAnswerChanged;

  /// Allows a message containing only the host's persisted attachment bundle.
  final bool hasAttachments;

  /// Called for text or attachments outside IME composition.
  final VoidCallback? onSend;

  /// False shows an explanatory read-only state.
  final bool enabled;

  /// Creates the editor controller and keyboard interaction state.
  @override
  State<CarpenterMessageComposer> createState() => _ComposerState();
}

class _ComposerState extends State<CarpenterMessageComposer> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  @override
  void didUpdateWidget(covariant CarpenterMessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A delayed persistence echo must not replace text typed after that echo.
    if (widget.text != oldWidget.text && _controller.text == oldWidget.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  void _send() {
    if (widget.enabled &&
        (_controller.text.trim().isNotEmpty || widget.hasAttachments) &&
        _controller.value.composing.isCollapsed) {
      widget.onSend?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Builds the controlled messenger presentation using semantic theme roles.
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
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
          if (widget.replyPreview != null)
            _ReplyPreview(
              text: widget.replyPreview!,
              onCancel: widget.onCancelReply,
            ),
          Focus(
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed &&
                  _controller.value.composing.isCollapsed) {
                _send();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: CarpenterTextArea(
              controller: _controller,
              placeholder: 'Написать сообщение…',
              semanticLabel: 'Сообщение',
              trailingAction: CarpenterActionDescriptor(
                id: 'send-message',
                label: 'Отправить',
                icon: GravityIcons.paperPlane,
                onInvoke:
                    (_controller.text.trim().isEmpty &&
                            !widget.hasAttachments) ||
                        widget.onSend == null
                    ? null
                    : _send,
              ),
              minLines: 1,
              maxLines: 4,
              onChanged: (text) {
                setState(() {});
                widget.onTextChanged(text);
              },
            ),
          ),
          SizedBox(height: gap),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: gap,
            runSpacing: gap,
            children: [
              CarpenterCheckbox(
                value: widget.needAnswer
                    ? CheckboxValue.checked
                    : CheckboxValue.unchecked,
                label: 'Нужен ответ',
                onChanged: (value) =>
                    widget.onNeedAnswerChanged(value == CheckboxValue.checked),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Canonical conversation list/detail composition shared by host and Widgetbook.
/// Requires bounded height. Selection, draft, history and errors are controlled.
/// Uses Carpenter's master-detail policy; switching regions does not own a call.
class CarpenterMessengerWorkspace extends StatelessWidget {
  /// Missing selection keeps the list available; [onSelected] also handles back.
  const CarpenterMessengerWorkspace({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.messages,
    required this.draft,
    required this.needAnswer,
    required this.onSelected,
    required this.onDraftChanged,
    required this.onNeedAnswerChanged,
    required this.onSend,
    required this.onRetry,
    this.loading = false,
    this.problem,
    this.onReload,
    this.onRecoveryRequested,
    this.recovery,
    this.attachments = const [],
    this.hasDraftAttachments = false,
    this.onFilesRequested,
    this.onUploadRetried,
    this.onUploadCancelled,
    this.historyLoading = false,
    this.historyProblem,
    this.onHistoryRequested,
    this.conversationQuery = '',
    this.onConversationQueryChanged,
    this.visibleConversationIds,
    this.replyPreview,
    this.onUnavailableReply,
    this.replyLookupStatus,
    this.failedReplyMessageId,
    this.onCancelReplyLookup,
    this.onReply,
    this.onCancelReply,
  });

  /// Quotation associated with the selected room's draft, supplied by the host.
  final String? replyPreview;

  /// Requests an unavailable original using the quoted message row key.
  /// Resolving that row's target automatically navigates while this room remains
  /// mounted, unless the user cancels, scrolls, or opens another quote.
  final ValueChanged<String>? onUnavailableReply;

  /// Room-scoped host status for original lookup, including retry guidance.
  final String? replyLookupStatus;

  /// Quoted row whose lookup failed; cancels only its pending navigation.
  /// Reset to null when that lookup is retried.
  final String? failedReplyMessageId;

  /// Cancels the pending quoted row on explicit cancel, scrolling or another
  /// quote selection. The host decides whether network work can be cancelled.
  final ValueChanged<String>? onCancelReplyLookup;

  /// Receives a stable message row key to start a reply.
  final ValueChanged<String>? onReply;

  /// Clears the selected draft's reply relation only.
  final VoidCallback? onCancelReply;

  /// Host-owned local directory query, independent from message-content search.
  final String conversationQuery;

  /// Null hides search for hosts that do not offer directory filtering.
  final ValueChanged<String>? onConversationQueryChanged;

  /// Host-filtered IDs. Null shows all authorized [conversations]. Unknown IDs
  /// never add rooms. Filtering leaves [selectedId] and its detail intact.
  final Set<String>? visibleConversationIds;

  /// A page request is running; existing messages and the composer stay usable.
  final bool historyLoading;

  /// Selected-room history error, independent from directory and send errors.
  final String? historyProblem;

  /// Loads older messages, or retries the failed page. Null hides the action.
  /// The host owns the opaque cursor and must prevent concurrent page requests.
  final VoidCallback? onHistoryRequested;

  /// Available conversations after host authorization.
  final List<CarpenterConversationItem> conversations;

  /// Selected opaque key, or null for the list-only state.
  final String? selectedId;

  /// Messages in the selected conversation, oldest first.
  final List<CarpenterMessageItem> messages;

  /// Selected conversation's draft.
  final String draft;

  /// Selected draft's answer-request flag.
  final bool needAnswer;

  /// Receives a key or null when leaving detail.
  final ValueChanged<String?> onSelected;

  /// Receives edits for the selected room.
  final ValueChanged<String> onDraftChanged;

  /// Receives changes to the draft marker.
  final ValueChanged<bool> onNeedAnswerChanged;

  /// Null disables send; storage/transport are entirely caller-owned.
  final VoidCallback? onSend;

  /// Receives an existing message key to retry.
  final ValueChanged<String> onRetry;

  /// Initial loading only; does not erase existing usable history.
  final bool loading;

  /// Human-readable, recoverable problem; raw exceptions are not appropriate.
  final String? problem;

  /// Explicit retry for initial loading failures.
  final VoidCallback? onReload;

  /// Optional explicit recovery action, shown alongside a storage warning.
  final VoidCallback? onRecoveryRequested;

  /// Controlled review replaces the conversation region until host dismissal.
  final CarpenterMessengerRecovery? recovery;

  /// Selected-room uploads; these are not sent messages.
  final List<CarpenterAttachmentItem> attachments;

  /// True when a persisted draft contains files, allowing captionless submission.
  final bool hasDraftAttachments;

  /// Optional host picker for an authorized writable room.
  final VoidCallback? onFilesRequested;

  /// Retries an existing upload by its intent key.
  final ValueChanged<String>? onUploadRetried;

  /// Cancels a queued or active upload; also available after write revocation.
  final ValueChanged<String>? onUploadCancelled;

  /// Builds the controlled messenger presentation using semantic theme roles.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    CarpenterConversationItem? selected;
    for (final item in conversations) {
      if (item.id == selectedId) selected = item;
    }
    final room = selected;
    final visible = conversations
        .where(
          (item) =>
              visibleConversationIds == null ||
              visibleConversationIds!.contains(item.id),
        )
        .toList();
    return ColoredBox(
      color: theme.surface.base,
      child: Column(
        children: [
          if (problem != null)
            Padding(
              padding: EdgeInsets.all(gap),
              child: Wrap(
                spacing: gap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CarpenterText.feedback(
                    problem!,
                    feedbackRole: FeedbackColorRole.danger,
                  ),
                  if (onRecoveryRequested != null && recovery == null)
                    CarpenterButton.text(
                      label: 'Сверить черновики',
                      onPressed: onRecoveryRequested,
                    ),
                  if (onReload != null && recovery == null)
                    CarpenterButton.text(
                      label: 'Попробовать снова',
                      onPressed: onReload,
                    ),
                ],
              ),
            ),
          Expanded(
            child:
                recovery ??
                CarpenterMasterDetail(
                  viewportPolicy: const CarpenterViewportPolicy(
                    accountForTextScale: true,
                  ),
                  detailScrollOwnership: CarpenterRegionScrollOwnership.child,
                  splitPosition: .3,
                  masterSemanticLabel: 'Разговоры',
                  detailSemanticLabel: 'Переписка',
                  onDetailVisibilityChanged: (visible) {
                    if (!visible) onSelected(null);
                  },
                  master: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(gap),
                        child: const CarpenterText.title(
                          'Сообщения',
                          emphasis: TypographyEmphasis.strong,
                        ),
                      ),
                      if (onConversationQueryChanged != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
                          child: _ConversationSearchField(
                            query: conversationQuery,
                            onChanged: onConversationQueryChanged!,
                          ),
                        ),
                      if (loading)
                        Padding(
                          padding: EdgeInsets.all(gap),
                          child: const CarpenterText.body(
                            'Загрузка разговоров…',
                          ),
                        ),
                      if (!loading && problem == null && visible.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(gap),
                          child: CarpenterText.body(
                            conversationQuery.trim().isEmpty
                                ? 'Пока нет разговоров'
                                : 'Ничего не найдено',
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final item = visible[index];
                            return CarpenterListTile(
                              key: ValueKey(item.id),
                              presentation:
                                  CarpenterListTilePresentation.collectionRow,
                              leading: CarpenterAvatar(
                                initials: item.title.characters
                                    .take(1)
                                    .toString(),
                              ),
                              title: CarpenterText.label(
                                item.title,
                                emphasis: TypographyEmphasis.strong,
                              ),
                              subtitle: CarpenterText.caption(item.subtitle),
                              selected: item.id == selectedId,
                              onInvoke: () => onSelected(item.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  detail: room == null
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(gap),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CarpenterIconButton(
                                        icon: GravityIcons.arrowLeft,
                                        semanticLabel: 'К разговорам',
                                        prominence: ActionProminence.ghost,
                                        onPressed: () => onSelected(null),
                                      ),
                                      SizedBox(width: gap),
                                      CarpenterAvatar(
                                        initials: room.title.characters
                                            .take(1)
                                            .toString(),
                                      ),
                                      SizedBox(width: gap),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CarpenterText.label(
                                              room.title,
                                              emphasis:
                                                  TypographyEmphasis.strong,
                                            ),
                                            CarpenterText.caption(
                                              room.contextLabel ??
                                                  room.subtitle,
                                              colorRole:
                                                  ContentColorRole.secondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (replyLookupStatus != null)
                              Semantics(
                                liveRegion: true,
                                child: CarpenterText.caption(
                                  replyLookupStatus!,
                                ),
                              ),
                            if (historyLoading ||
                                historyProblem != null ||
                                onHistoryRequested != null)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: gap),
                                child: Wrap(
                                  spacing: gap,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (historyLoading)
                                      const CarpenterText.caption(
                                        'Загрузка истории…',
                                      ),
                                    if (historyProblem != null)
                                      CarpenterText.feedback(
                                        historyProblem!,
                                        feedbackRole: FeedbackColorRole.danger,
                                      ),
                                    if (onHistoryRequested != null &&
                                        !historyLoading)
                                      CarpenterButton(
                                        label: historyProblem == null
                                            ? 'Ранние сообщения'
                                            : 'Повторить загрузку',
                                        onPressed: onHistoryRequested,
                                        prominence: ActionProminence.ghost,
                                      ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ColoredBox(
                                        color: theme.surface.subtle,
                                        child: messages.isEmpty
                                            ? Center(
                                                child: CarpenterText.body(
                                                  historyLoading
                                                      ? 'Загружаем сообщения…'
                                                      : historyProblem != null
                                                      ? 'История пока недоступна'
                                                      : 'Начните разговор',
                                                ),
                                              )
                                            : _MessageTimeline(
                                                key: ValueKey(room.id),
                                                messages: messages,
                                                onRetry: onRetry,
                                                onUnavailableReply:
                                                    onUnavailableReply,
                                                failedReplyMessageId:
                                                    failedReplyMessageId,
                                                onCancelReplyLookup:
                                                    onCancelReplyLookup,
                                                onReply: room.canSend
                                                    ? onReply
                                                    : null,
                                              ),
                                      ),
                                    ),
                                    if (attachments.isNotEmpty ||
                                        (room.canSend &&
                                            onFilesRequested != null))
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: constraints.maxHeight / 2,
                                        ),
                                        child: CarpenterAttachmentTray(
                                          items: attachments,
                                          onAdd: room.canSend
                                              ? onFilesRequested
                                              : null,
                                          onRetry: room.canSend
                                              ? onUploadRetried
                                              : null,
                                          onCancel: onUploadCancelled,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            CarpenterMessageComposer(
                              key: ValueKey('composer-${room.id}'),
                              text: draft,
                              hasAttachments: hasDraftAttachments,
                              replyPreview: replyPreview,
                              onCancelReply: onCancelReply,
                              needAnswer: needAnswer,
                              enabled: room.canSend,
                              onTextChanged: onDraftChanged,
                              onNeedAnswerChanged: onNeedAnswerChanged,
                              onSend: onSend,
                            ),
                          ],
                        ),
                ),
          ),
        ],
      ),
    );
  }
}

// Author IDs and a short local-time interval are required. Identical display
// names alone must never merge different participants.
bool _groupsWithPrevious(List<CarpenterMessageItem> messages, int index) {
  if (index < 1) return false;
  final current = messages[index];
  final previous = messages[index - 1];
  final time = current.sentAt;
  final prior = previous.sentAt;
  if (current.authorKey == null ||
      current.authorKey != previous.authorKey ||
      current.own != previous.own ||
      time == null ||
      prior == null) {
    return false;
  }
  final delta = time.difference(prior);
  return !delta.isNegative &&
      delta <= const Duration(minutes: 5) &&
      time.year == prior.year &&
      time.month == prior.month &&
      time.day == prior.day;
}

// Editing mechanics belong here; filtering remains in the host/Cubit.
class _ConversationSearchField extends StatefulWidget {
  const _ConversationSearchField({
    required this.query,
    required this.onChanged,
  });
  final String query;
  final ValueChanged<String> onChanged;
  @override
  State<_ConversationSearchField> createState() =>
      _ConversationSearchFieldState();
}

class _ConversationSearchFieldState extends State<_ConversationSearchField> {
  late final _controller = TextEditingController(text: widget.query);
  @override
  void didUpdateWidget(covariant _ConversationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && _controller.text != widget.query) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape &&
          _controller.text.isNotEmpty &&
          _controller.value.composing.isCollapsed) {
        _clear();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: CarpenterInput(
      controller: _controller,
      placeholder: 'Поиск чатов',
      semanticLabel: 'Поиск чатов',
      leadingIcon: GravityIcons.magnifier,
      onChanged: widget.onChanged,
      trailingAction: widget.query.isEmpty
          ? null
          : CarpenterActionDescriptor(
              id: 'clear-conversation-search',
              label: 'Очистить поиск',
              icon: GravityIcons.xmark,
              onInvoke: _clear,
            ),
    ),
  );
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.text, this.onCancel, this.onOpen});
  final String text;
  final VoidCallback? onCancel;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: theme.actions.primary.normal,
              width: gap / 4,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CarpenterText.caption(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  colorRole: ContentColorRole.secondary,
                ),
              ),
              if (onOpen != null)
                CarpenterIconButton(
                  icon: GravityIcons.arrowUp,
                  semanticLabel: 'Перейти к исходному сообщению',
                  prominence: ActionProminence.ghost,
                  onPressed: onOpen,
                ),
              if (onCancel != null)
                CarpenterIconButton(
                  icon: GravityIcons.xmark,
                  semanticLabel: 'Отменить ответ',
                  prominence: ActionProminence.ghost,
                  onPressed: onCancel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Re-anchor lazy slivers around the original instead of estimating pixel offsets
// for variable-height messages. Newer items remain available below the anchor.
class _MessageTimeline extends StatefulWidget {
  const _MessageTimeline({
    super.key,
    required this.messages,
    required this.onRetry,
    this.onUnavailableReply,
    this.failedReplyMessageId,
    this.onCancelReplyLookup,
    this.onReply,
  });
  final String? failedReplyMessageId;
  final ValueChanged<String>? onCancelReplyLookup;
  final List<CarpenterMessageItem> messages;
  final ValueChanged<String> onRetry;
  final ValueChanged<String>? onUnavailableReply;
  final ValueChanged<String>? onReply;
  @override
  State<_MessageTimeline> createState() => _MessageTimelineState();
}

class _MessageTimelineState extends State<_MessageTimeline> {
  final _center = UniqueKey();
  String? _anchor;
  String? _pendingReply;
  String? _notice;
  int _generation = 0;

  @override
  void didUpdateWidget(covariant _MessageTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pendingReply == widget.failedReplyMessageId) {
      _pendingReply = null;
    }
    if (_pendingReply != null) {
      final sources = widget.messages.where((item) => item.id == _pendingReply);
      if (sources.isEmpty) {
        _pendingReply = null;
      } else {
        final target = sources.first.replyTargetId;
        if (target != null &&
            widget.messages.any((item) => item.id == target)) {
          _pendingReply = null;
          _anchor = target;
          _notice = null;
          _generation++;
        }
      }
    }
    if (_anchor != null && !widget.messages.any((item) => item.id == _anchor)) {
      _anchor = null;
      _notice = 'Исходное сообщение больше недоступно.';
      _generation++;
    }
  }

  void _cancelPendingNavigation() {
    final pending = _pendingReply;
    if (pending != null) {
      setState(() => _pendingReply = null);
      widget.onCancelReplyLookup?.call(pending);
    }
  }

  void _open(CarpenterMessageItem message) {
    if (_pendingReply != message.id) _cancelPendingNavigation();
    _pendingReply = null;
    final target = message.replyTargetId;
    if (target == null || !widget.messages.any((item) => item.id == target)) {
      if (widget.onUnavailableReply != null) {
        setState(() => _pendingReply = message.id);
        widget.onUnavailableReply!(message.id);
      } else {
        setState(
          () => _notice = 'Исходное сообщение не загружено или недоступно.',
        );
      }
      return;
    }
    setState(() {
      _anchor = target;
      _notice = null;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.messages.indexWhere((item) => item.id == _anchor);
    final anchor = found < 0 ? widget.messages.length - 1 : found;
    Widget bubble(int index) {
      final message = widget.messages[index];
      return Semantics(
        key: ValueKey(message.id),
        label: message.id == _anchor ? 'Исходное сообщение' : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message.id == _anchor)
              const Center(child: CarpenterText.caption('Исходное сообщение')),
            CarpenterMessageBubble(
              key: ValueKey(message.id),
              message: message,
              groupWithPrevious: _groupsWithPrevious(widget.messages, index),
              onRetry: () => widget.onRetry(message.id),
              onReply: widget.onReply == null
                  ? null
                  : () => widget.onReply!(message.id),
              onOpenReply: message.replyPreview == null
                  ? null
                  : () => _open(message),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_notice != null) CarpenterText.caption(_notice!),
        Expanded(
          child: Listener(
            onPointerSignal: (_) => _cancelPendingNavigation(),
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null) {
                  _cancelPendingNavigation();
                }
                return false;
              },
              child: CustomScrollView(
                key: ValueKey(_generation),
                reverse: true,
                center: _center,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => bubble(anchor + index + 1),
                      childCount: widget.messages.length - anchor - 1,
                    ),
                  ),
                  SliverList(
                    key: _center,
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => bubble(anchor - index),
                      childCount: anchor + 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_anchor != null || _notice != null || _pendingReply != null)
          CarpenterButton(
            label: _pendingReply != null
                ? 'Отменить переход'
                : 'К последним сообщениям',
            prominence: ActionProminence.ghost,
            onPressed: () {
              _cancelPendingNavigation();
              setState(() {
                _anchor = null;
                _notice = null;
                _generation++;
              });
            },
          ),
      ],
    );
  }
}
