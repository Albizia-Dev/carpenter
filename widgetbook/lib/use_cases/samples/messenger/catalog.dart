import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../helpers/layout_viewport.dart';
import 'conversation_catalog.dart';

final _messengerPlaygroundMemory = _MessengerScenarioMemory();

final messengerComponents = [
  ...conversationComponents,
  WidgetbookComponent(
    name: 'Message timeline',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: _TimelineScenario(
            loadingOlder: context.knobs.boolean(label: 'Подгрузка сверху'),
            selected: context.knobs.boolean(label: 'Мультивыбор'),
            withMedia: context.knobs.boolean(
              label: 'Медиа',
              initialValue: true,
            ),
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Messenger layout',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: _MessengerScenario(
            memory: _messengerPlaygroundMemory,
            loading: context.knobs.boolean(label: 'Загрузка списка'),
            failed: context.knobs.boolean(label: 'Ошибка списка'),
            readOnly: context.knobs.boolean(label: 'Только чтение'),
            recording: context.knobs.boolean(label: 'Записывает'),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Narrow selected chat',
        builder: (_) => const SizedBox(
          width: 390,
          height: 760,
          child: _MessengerScenario(initialSelected: true),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Wide empty detail',
        builder: (_) => const SizedBox(
          width: 1280,
          height: 760,
          child: _MessengerScenario(),
        ),
      ),
    ],
  ),
];

class _MessengerScenario extends StatefulWidget {
  const _MessengerScenario({
    this.memory,
    this.initialSelected = false,
    this.loading = false,
    this.failed = false,
    this.readOnly = false,
    this.recording = false,
  });
  final _MessengerScenarioMemory? memory;
  final bool initialSelected;
  final bool loading;
  final bool failed;
  final bool readOnly;
  final bool recording;
  @override
  State<_MessengerScenario> createState() => _MessengerScenarioState();
}

class _MessengerScenarioState extends State<_MessengerScenario> {
  late String? selected =
      widget.memory?.selected ?? (widget.initialSelected ? 'project' : null);
  final search = TextEditingController();
  late String draft = widget.memory?.draft ?? '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterMessengerLayout(
    selectedConversationId: selected,
    directory: CarpenterConversationDirectory(
      searchController: search,
      conversations: widget.loading ? const [] : _conversations,
      selectedId: selected,
      initialLoading: widget.loading,
      failureLabel: widget.failed ? 'Не удалось обновить' : null,
      onConversationSelected: (id) => setState(() {
        selected = id;
        widget.memory?.selected = id;
      }),
      onSearchChanged: (_) {},
      onCreateConversation: () {},
    ),
    emptyConversation: const Center(child: CarpenterText.body('Выберите чат')),
    conversation: Column(
      children: [
        CarpenterConversationHeader(
          title: 'Северный парк',
          avatar: const CarpenterConversationAvatar(
            name: 'Северный парк',
            shape: CarpenterConversationAvatarShape.room,
          ),
          presence: widget.recording
              ? CarpenterPresenceKind.recordingVoice
              : CarpenterPresenceKind.online,
          onBack: () => setState(() {
            selected = null;
            widget.memory?.selected = null;
          }),
          onCall: () {},
          onActions: () {},
        ),
        const Expanded(child: _TimelineScenario(withMedia: true)),
        CarpenterChatComposer(
          view: CarpenterComposerView(text: draft, readOnly: widget.readOnly),
          recording: CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: widget.recording
                ? CarpenterRecordingPhase.recording
                : CarpenterRecordingPhase.idle,
            level: .8,
          ),
          onTextChanged: (value) => setState(() {
            draft = value;
            widget.memory?.draft = value;
          }),
          onSendRequested: (_) => setState(() {
            draft = '';
            widget.memory?.draft = '';
          }),
          onAttachmentsRequested: () {},
          onRecordingStart: (_) {},
          onRecordingLock: (_) {},
          onRecordingStop: (_) {},
        ),
      ],
    ),
  );
}

final class _MessengerScenarioMemory {
  String? selected;
  String draft = '';
}

class _TimelineScenario extends StatefulWidget {
  const _TimelineScenario({
    this.loadingOlder = false,
    this.selected = false,
    this.withMedia = false,
  });
  final bool loadingOlder;
  final bool selected;
  final bool withMedia;
  @override
  State<_TimelineScenario> createState() => _TimelineScenarioState();
}

class _TimelineScenarioState extends State<_TimelineScenario> {
  final selectedIds = <String>{};
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    if (widget.selected && selectedIds.isEmpty) selectedIds.add('reply');
    return CarpenterMessageTimeline(
      messages: [
        CarpenterMessageView(
          id: 'first',
          authorId: 'anna',
          authorLabel: 'Анна',
          body: 'Проверьте смету',
          own: false,
          sentAt: DateTime(2026, 9, 24, 10),
        ),
        CarpenterMessageView(
          id: 'reply',
          authorId: 'me',
          authorLabel: 'Вы',
          body: 'Проверю сегодня',
          own: true,
          sentAt: DateTime(2026, 9, 24, 10, 4),
          replyTargetId: 'first',
          replyPreview: 'Анна: Проверьте смету',
          meta: const CarpenterMessageMeta(
            important: true,
            requiresAnswer: true,
            delivery: CarpenterDeliveryState.read,
          ),
          media: widget.withMedia
              ? [
                  CarpenterMediaView(
                    id: 'circle',
                    kind: CarpenterMediaKind.videoCircle,
                    label: 'Кружок',
                    byteLength: 1024,
                    loadState: CarpenterMediaLoadState.ready,
                    duration: const Duration(seconds: 20),
                    focused: focused,
                  ),
                ]
              : const [],
        ),
        CarpenterMessageView(
          id: 'system',
          authorId: 'system',
          authorLabel: '',
          body: 'Анна закрепила сообщение',
          own: false,
          sentAt: DateTime(2026, 9, 24, 10, 5),
          system: true,
        ),
      ],
      selectedIds: selectedIds,
      groupChat: true,
      loadingOlder: widget.loadingOlder,
      onSelectionChanged: (id, selected) => setState(
        () => selected ? selectedIds.add(id) : selectedIds.remove(id),
      ),
      onReplyRequested: (_) {},
      onRetryRequested: (_) {},
      onReplyPreviewInvoked: (_) {},
      mediaPreviewBuilder: (_, _) => const ColoredBox(color: Color(0xff7b5cd6)),
      onMediaFocusChanged: (_, value) => setState(() => focused = value),
      onMediaPlayPauseRequested: (_) {},
      onMediaSpeedChanged: (_, _) {},
      metadataLeadingBuilder: (_, message) => message.meta.important
          ? const [
              CarpenterIcon(
                GravityIcons.pin,
                semanticLabel: 'Leading-модификатор',
                size: IconSize.small,
              ),
            ]
          : const [],
      metadataTrailingBuilder: (_, message) => message.meta.requiresAnswer
          ? const [CarpenterBadge(label: 'Ответ')]
          : const [],
    );
  }
}

final _conversations = [
  CarpenterConversationView(
    id: 'project',
    title: 'Северный парк',
    preview: 'Проверьте смету',
    previewAuthor: 'Анна',
    avatarShape: CarpenterConversationAvatarShape.room,
    unreadCount: 3,
    lastEventAt: DateTime(2026, 9, 25, 1, 59),
  ),
  CarpenterConversationView(
    id: 'anna',
    title: 'Анна Смирнова',
    preview: 'Готово',
    avatarShape: CarpenterConversationAvatarShape.person,
    lastEventAt: DateTime(2026, 9, 25, 1, 55),
  ),
];
