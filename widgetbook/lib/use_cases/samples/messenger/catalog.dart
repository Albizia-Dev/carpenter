import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';

final messengerComponents = [
  WidgetbookComponent(
    name: 'Message attachments',
    useCases: [
      WidgetbookUseCase(
        name: 'Ready draft and retry',
        builder: (context) => layoutViewportPreview(
          context,
          child: const AttachmentMessageScenario(),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Attachment tray',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: AttachmentTrayScenario(
            verifying: context.knobs.boolean(label: 'Проверка файла'),
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Messenger recovery',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: RecoveryScenario(
            noConflicts: context.knobs.boolean(label: 'Без конфликтов'),
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Messenger workspace',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: MessengerScenario(
            initialRoom:
                context.knobs.boolean(
                  label: 'Открыть разговор',
                  initialValue: true,
                )
                ? 'project'
                : null,
            initialQuery: context.knobs.string(label: 'Поиск чатов'),
            showAttachments: context.knobs.boolean(label: 'Вложения'),
            missingOriginal: context.knobs.boolean(
              label: 'Подгрузка оригинала',
            ),
            failSend: context.knobs.boolean(label: 'Ошибка отправки'),
            readOnly: context.knobs.boolean(label: 'Только чтение'),
            historyLoading: context.knobs.boolean(label: 'Загрузка истории'),
            historyFailure: context.knobs.boolean(label: 'Ошибка истории'),
            hasOlder: context.knobs.boolean(label: 'Есть ранние сообщения'),
            groupedMessages: context.knobs.boolean(label: 'Группа сообщений'),
            distantReply: context.knobs.boolean(
              label: 'Ответ на раннее сообщение',
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'State · Failed send',
        builder: (context) => layoutViewportPreview(
          context,
          child: const MessengerScenario(failSend: true, showFailure: true),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Message bubble',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => CarpenterMessageBubble(
          message: CarpenterMessageItem(
            id: 'example',
            author: context.knobs.string(
              label: 'Автор',
              initialValue: 'Анна Смирнова',
            ),
            text: context.knobs.string(
              label: 'Текст',
              initialValue: 'Проверьте, пожалуйста, документ.',
            ),
            status: context.knobs.string(
              label: 'Статус',
              initialValue: '10:24',
            ),
            own: context.knobs.boolean(label: 'Собственное сообщение'),
            needAnswer: context.knobs.boolean(label: 'Нужен ответ'),
            canRetry: context.knobs.boolean(label: 'Можно повторить'),
          ),
          groupWithPrevious: context.knobs.boolean(label: 'Продолжение группы'),
          onRetry: () {},
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Message composer',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => ComposerScenario(
          enabled: !context.knobs.boolean(label: 'Только чтение'),
        ),
      ),
    ],
  ),
];

/// UI-only fixture harness. Does not import the Desktop, Bloc or transport.
class MessengerScenario extends StatefulWidget {
  const MessengerScenario({
    super.key,
    this.initialRoom = 'project',
    this.failSend = false,
    this.showFailure = false,
    this.showAttachments = false,
    this.readOnly = false,
    this.historyLoading = false,
    this.historyFailure = false,
    this.hasOlder = false,
    this.groupedMessages = false,
    this.initialQuery = '',
    this.distantReply = false,
    this.missingOriginal = false,
    this.originalFailure = false,
  });
  final String? initialRoom;
  final bool failSend;
  final bool showFailure;
  final bool showAttachments;
  final bool readOnly;
  final bool historyLoading;
  final bool historyFailure;
  final bool hasOlder;
  final bool groupedMessages;
  final bool distantReply;
  final bool missingOriginal;
  final bool originalFailure;
  final String initialQuery;
  @override
  State<MessengerScenario> createState() => _MessengerScenarioState();
}

class _MessengerScenarioState extends State<MessengerScenario> {
  late String? selected = widget.initialRoom;
  final drafts = <String, String>{};
  final replies = <String, String>{};
  final replyTargets = <String, String>{};
  final flags = <String, bool>{};
  final sent = <String, List<CarpenterMessageItem>>{};
  int sequence = 0;
  late String query = widget.initialQuery;
  bool fixtureRetried = false;
  bool historyResolved = false;
  bool originalLoaded = false;
  bool originalFailed = false;
  @override
  void didUpdateWidget(covariant MessengerScenario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      query = widget.initialQuery;
    }
    if (oldWidget.historyFailure != widget.historyFailure ||
        oldWidget.hasOlder != widget.hasOlder) {
      historyResolved = false;
    }
    if (oldWidget.initialRoom != widget.initialRoom) {
      selected = widget.initialRoom;
    }
  }

  List<CarpenterConversationItem> get _rooms => [
    CarpenterConversationItem(
      id: 'anna',
      title: 'Анна Смирнова',
      subtitle: 'Личный разговор',
      canSend: !widget.readOnly,
    ),
    CarpenterConversationItem(
      id: 'project',
      title: 'Северный парк',
      subtitle: 'Документация и согласование',
      contextLabel: 'Проект · Северный парк',
      canSend: !widget.readOnly,
    ),
    const CarpenterConversationItem(
      id: 'archive',
      title: 'Завершённый заказ',
      subtitle: 'Только чтение',
      canSend: false,
    ),
  ];

  List<CarpenterMessageItem> get _messages => [
    if (historyResolved && widget.hasOlder)
      const CarpenterMessageItem(
        id: 'older',
        author: 'Анна Смирнова',
        text: 'Раннее обсуждение документации.',
        status: 'Вчера · 16:10',
      ),
    if (selected == 'project') ...[
      CarpenterMessageItem(
        id: 'one',
        canReply: true,
        authorKey: 'anna',
        sentAt: DateTime(2026, 9, 11, 10, 24),
        author: 'Анна Смирнова',
        text:
            'Коллеги, проверьте состав документации перед передачей заказчику.',
        status: '',
        timeLabel: '10:24',
        needAnswer: true,
      ),
      if (widget.groupedMessages)
        CarpenterMessageItem(
          id: 'continuation',
          author: 'Анна Смирнова',
          authorKey: 'anna',
          sentAt: DateTime(2026, 9, 11, 10, 25),
          text: 'Особенно раздел с замечаниями.',
          status: '',
          timeLabel: '10:25',
        ),
      CarpenterMessageItem(
        id: 'two',
        canReply: true,
        authorKey: 'self',
        sentAt: DateTime(2026, 9, 11, 10, 26),
        author: 'Вы',
        text: 'Проверю сегодня. Ответ напишу здесь.',
        status: 'Отправлено',
        timeLabel: '10:26',
        own: true,
      ),
      if (widget.showFailure)
        CarpenterMessageItem(
          id: 'failure',
          authorKey: 'self',
          sentAt: DateTime(2026, 9, 11, 10, 27),
          timeLabel: '10:27',
          author: 'Вы',
          text: 'Обновлённый список замечаний готов.',
          status: fixtureRetried ? 'Отправлено' : 'Не отправлено',
          own: true,
          canRetry: !fixtureRetried,
        ),
    ],
    if (widget.distantReply && selected == 'project') ...[
      for (var index = 0; index < 80; index++)
        CarpenterMessageItem(
          id: 'history-$index',
          author: 'Анна',
          text:
              'Обсуждение раздела $index. Дополнительные замечания по документации.',
          status: '10:30',
        ),
      const CarpenterMessageItem(
        id: 'distant-reply',
        author: 'Вы',
        text: 'Возвращаюсь к первому вопросу.',
        status: 'Отправлено',
        own: true,
        replyPreview: 'Анна Смирнова\nПроверьте состав документации',
        replyTargetId: 'one',
      ),
    ],
    if (widget.missingOriginal && selected == 'project') ...[
      if (originalLoaded)
        const CarpenterMessageItem(
          id: 'recovered',
          author: 'Анна',
          text: 'Восстановленный оригинал',
          status: '',
        ),
      CarpenterMessageItem(
        id: 'quoted-missing',
        author: 'Вы',
        text: 'Уточняю исходный вопрос',
        status: '',
        replyPreview: originalLoaded
            ? 'Анна\nВосстановленный оригинал'
            : 'Сообщение недоступно',
        replyTargetId: originalLoaded ? 'recovered' : null,
      ),
    ],
    ...?sent[selected],
  ];

  @override
  Widget build(BuildContext context) => CarpenterMessengerWorkspace(
    attachments: widget.showAttachments
        ? const [
            CarpenterAttachmentItem(
              id: 'example-file',
              name: 'План работ.pdf',
              phase: CarpenterMessengerUploadPhase.uploading,
              detail: '512 КБ / 1 МБ',
              progress: .5,
            ),
          ]
        : const [],
    replyLookupStatus: originalFailed && selected == 'project'
        ? 'Не удалось загрузить оригинал. Повторите запрос у цитаты.'
        : null,
    failedReplyMessageId: originalFailed && selected == 'project'
        ? 'quoted-missing'
        : null,
    onUnavailableReply: widget.missingOriginal
        ? (_) => setState(() {
            originalFailed = widget.originalFailure;
            originalLoaded = !widget.originalFailure;
          })
        : null,
    historyLoading: widget.historyLoading,
    historyProblem: widget.historyFailure && !historyResolved
        ? 'Не удалось загрузить историю.'
        : null,
    onHistoryRequested:
        (widget.historyFailure || widget.hasOlder) && !historyResolved
        ? () => setState(() => historyResolved = true)
        : null,
    conversations: _rooms,
    conversationQuery: query,
    onConversationQueryChanged: (value) => setState(() => query = value),
    visibleConversationIds: _rooms
        .where((room) {
          final text =
              '${room.title} ${room.subtitle} ${room.contextLabel ?? ''}'
                  .toLowerCase()
                  .replaceAll('ё', 'е');
          final terms = query
              .toLowerCase()
              .replaceAll('ё', 'е')
              .trim()
              .split(RegExp(r'\s+'))
              .where((term) => term.isNotEmpty);
          return terms.every(text.contains);
        })
        .map((room) => room.id)
        .toSet(),
    selectedId: selected,
    messages: _messages,
    replyPreview: replies[selected],
    onCancelReply: () => setState(() => replies.remove(selected)),
    onReply: (id) => setState(() {
      final message = _messages.firstWhere((item) => item.id == id);
      replies[selected!] = '${message.author}\n${message.text}';
      replyTargets[selected!] = message.id;
    }),
    draft: drafts[selected] ?? '',
    needAnswer: flags[selected] ?? false,
    onSelected: (key) => setState(() => selected = key),
    onDraftChanged: (text) => setState(() => drafts[selected!] = text),
    onNeedAnswerChanged: (value) => setState(() => flags[selected!] = value),
    onSend: () => setState(() {
      final id = selected!;
      final text = drafts[id] ?? '';
      if (text.trim().isEmpty) return;
      (sent[id] ??= []).add(
        CarpenterMessageItem(
          id: 'sent-${++sequence}',
          author: 'Вы',
          text: text,
          status: widget.failSend ? 'Не отправлено' : 'Отправлено',
          own: true,
          needAnswer: flags[id] ?? false,
          canRetry: widget.failSend,
          canReply: !widget.failSend,
          replyPreview: replies[id],
          replyTargetId: replyTargets[id],
        ),
      );
      drafts.remove(id);
      flags.remove(id);
      replies.remove(id);
      replyTargets.remove(id);
    }),
    onRetry: (id) => setState(() {
      if (id == 'failure') {
        fixtureRetried = true;
        return;
      }
      final items = sent[selected];
      if (items == null) return;
      final index = items.indexWhere((item) => item.id == id);
      if (index < 0) return;
      final item = items[index];
      items[index] = CarpenterMessageItem(
        id: item.id,
        author: item.author,
        text: item.text,
        status: 'Отправлено',
        own: item.own,
        needAnswer: item.needAnswer,
        canReply: true,
        replyPreview: item.replyPreview,
        replyTargetId: item.replyTargetId,
      );
    }),
  );
}

class ComposerScenario extends StatefulWidget {
  const ComposerScenario({super.key, this.enabled = true});
  final bool enabled;
  @override
  State<ComposerScenario> createState() => _ComposerScenarioState();
}

class _ComposerScenarioState extends State<ComposerScenario> {
  String text = '';
  bool answer = false;
  @override
  Widget build(BuildContext context) => CarpenterMessageComposer(
    text: text,
    needAnswer: answer,
    enabled: widget.enabled,
    onTextChanged: (value) => setState(() => text = value),
    onNeedAnswerChanged: (value) => setState(() => answer = value),
    onSend: () => setState(() {
      text = '';
      answer = false;
    }),
  );
}

class RecoveryScenario extends StatefulWidget {
  const RecoveryScenario({super.key, this.noConflicts = false});
  final bool noConflicts;
  @override
  State<RecoveryScenario> createState() => _RecoveryScenarioState();
}

class _RecoveryScenarioState extends State<RecoveryScenario> {
  final choices = <String, CarpenterDraftChoice>{};
  String? result;
  @override
  void didUpdateWidget(covariant RecoveryScenario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noConflicts != widget.noConflicts) {
      choices.clear();
      result = null;
    }
  }

  @override
  Widget build(BuildContext context) => result != null
      ? Center(child: CarpenterText(result!))
      : CarpenterMessengerRecovery(
          conflicts: widget.noConflicts
              ? const []
              : const [
                  CarpenterDraftConflict(
                    id: 'anna',
                    title: 'Анна Смирнова',
                    base: 'Отправлю документы завтра.',
                    local: 'Отправлю документы сегодня.\nНужен ответ',
                    stored: null,
                  ),
                ],
          choices: choices,
          onChoiceChanged: (id, value) => setState(() => choices[id] = value),
          onApply: () => setState(() => result = 'Черновики сохранены'),
          onCancel: () => setState(() => result = 'Восстановление отменено'),
        );
}

class AttachmentTrayScenario extends StatefulWidget {
  const AttachmentTrayScenario({super.key, this.verifying = false});
  final bool verifying;
  @override
  State<AttachmentTrayScenario> createState() => _AttachmentTrayScenarioState();
}

class _AttachmentTrayScenarioState extends State<AttachmentTrayScenario> {
  bool retried = false;
  bool cancelled = false;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: RepaintBoundary(
      child: CarpenterAttachmentTray(
        items: [
          CarpenterAttachmentItem(
            id: 'upload',
            name: 'План участка — редакция для согласования.pdf',
            phase: cancelled
                ? CarpenterMessengerUploadPhase.cancelled
                : widget.verifying
                ? CarpenterMessengerUploadPhase.verifying
                : CarpenterMessengerUploadPhase.uploading,
            detail: cancelled
                ? 'Локальная загрузка остановлена'
                : '512 КБ / 1 МБ',
            progress: .5,
          ),
          CarpenterAttachmentItem(
            id: 'failed',
            name: 'Смета.xlsx',
            phase: retried
                ? CarpenterMessengerUploadPhase.ready
                : CarpenterMessengerUploadPhase.failed,
            detail: retried ? '840 КБ' : 'Нет подтверждения. Можно повторить',
          ),
          const CarpenterAttachmentItem(
            id: 'ready',
            name: 'Фото объекта.jpg',
            phase: CarpenterMessengerUploadPhase.ready,
            detail: '2 МБ',
          ),
        ],
        onRetry: (_) => setState(() => retried = true),
        onCancel: (_) => setState(() => cancelled = true),
      ),
    ),
  );
}

/// UI-only complete composition for a ready file, captionless send and retry.
class AttachmentMessageScenario extends StatefulWidget {
  const AttachmentMessageScenario({super.key});
  @override
  State<AttachmentMessageScenario> createState() =>
      _AttachmentMessageScenarioState();
}

class _AttachmentMessageScenarioState extends State<AttachmentMessageScenario> {
  String caption = '';
  bool needAnswer = false;
  bool submitted = false;
  bool confirmed = false;
  @override
  Widget build(BuildContext context) => CarpenterMessengerWorkspace(
    conversations: const [
      CarpenterConversationItem(
        id: 'project',
        title: 'Документация',
        subtitle: 'Проект',
        contextLabel: 'ERP · Проект №42',
      ),
    ],
    selectedId: 'project',
    onSelected: (_) {},
    messages: [
      const CarpenterMessageItem(
        id: 'incoming',
        author: 'Анна Смирнова',
        text: 'Для проверки',
        attachmentLabels: ['План работ.pdf · 2 МБ'],
        status: '',
        timeLabel: '10:24',
      ),
      if (submitted)
        CarpenterMessageItem(
          id: 'outgoing',
          author: 'Вы',
          text: caption,
          own: true,
          needAnswer: needAnswer,
          canRetry: !confirmed,
          attachmentLabels: const ['Спецификация оборудования.pdf · 540 КБ'],
          status: confirmed ? 'Отправлено' : 'Нет подтверждения',
        ),
    ],
    attachments: submitted
        ? const []
        : const [
            CarpenterAttachmentItem(
              id: 'ready',
              name: 'Спецификация оборудования.pdf',
              phase: CarpenterMessengerUploadPhase.ready,
              detail: '540 КБ',
            ),
          ],
    hasDraftAttachments: !submitted,
    draft: submitted ? '' : caption,
    needAnswer: !submitted && needAnswer,
    onDraftChanged: (text) => setState(() => caption = text),
    onNeedAnswerChanged: (value) => setState(() => needAnswer = value),
    onSend: submitted ? null : () => setState(() => submitted = true),
    onRetry: (_) => setState(() => confirmed = true),
  );
}
