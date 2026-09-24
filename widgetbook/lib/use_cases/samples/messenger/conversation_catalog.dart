import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../helpers/layout_viewport.dart';

final conversationComponents = [
  WidgetbookComponent(
    name: 'Conversation directory',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => layoutViewportPreview(
          context,
          child: _DirectoryScenario(
            loading: context.knobs.boolean(label: 'Первая загрузка'),
            failed: context.knobs.boolean(label: 'Ошибка обновления'),
            draft: context.knobs.boolean(label: 'Черновик', initialValue: true),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Initial loading',
        builder: (_) => const _DirectoryScenario(loading: true),
      ),
      WidgetbookUseCase(
        name: 'States · Stale after failure',
        builder: (_) => const _DirectoryScenario(failed: true),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Conversation header',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => CarpenterConversationHeader(
          title: 'Северный парк',
          avatar: const CarpenterConversationAvatar(
            name: 'Северный парк',
            shape: CarpenterConversationAvatarShape.room,
          ),
          presence: context.knobs.objectOrNull.dropdown(
            label: 'Статус',
            options: CarpenterPresenceKind.values,
          ),
          onBack: context.knobs.boolean(label: 'Кнопка назад') ? () {} : null,
          onCall: () {},
          onActions: () {},
          pinnedMessages: CarpenterPinnedMessages(
            previews: const ['Проверьте смету'],
            currentIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Message composer',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => _ComposerScenario(
          readOnly: context.knobs.boolean(label: 'Только чтение'),
          withReply: context.knobs.boolean(label: 'Ответ'),
          withAttachment: context.knobs.boolean(label: 'Вложение'),
          recording: context.knobs.boolean(label: 'Запись закреплена'),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Read only',
        builder: (_) => const _ComposerScenario(readOnly: true),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Inline media',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => _MediaScenario(
          kind: context.knobs.object.dropdown(
            label: 'Тип',
            options: CarpenterMediaKind.values,
            initialOption: CarpenterMediaKind.videoCircle,
          ),
          large: context.knobs.boolean(label: 'Большой файл'),
        ),
      ),
    ],
  ),
];

class _DirectoryScenario extends StatefulWidget {
  const _DirectoryScenario({
    this.loading = false,
    this.failed = false,
    this.draft = false,
  });
  final bool loading;
  final bool failed;
  final bool draft;
  @override
  State<_DirectoryScenario> createState() => _DirectoryScenarioState();
}

class _DirectoryScenarioState extends State<_DirectoryScenario> {
  final search = TextEditingController();
  String? selected;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterConversationDirectory(
    searchController: search,
    conversations: widget.loading
        ? const []
        : [
            CarpenterConversationView(
              id: 'project',
              title: 'Северный парк',
              preview: 'Проверьте смету',
              previewAuthor: 'Анна',
              draft: widget.draft ? 'отвечу позже' : null,
              avatarShape: CarpenterConversationAvatarShape.room,
              unreadCount: 3,
              muted: true,
              lastEventAt: DateTime(2026, 9, 25, 1, 59),
            ),
            CarpenterConversationView(
              id: 'anna',
              title: 'Анна Смирнова',
              preview: 'Готово',
              previewOwn: true,
              previewDelivery: CarpenterDeliveryState.read,
              lastEventAt: DateTime(2026, 9, 25, 1, 55),
              avatarShape: CarpenterConversationAvatarShape.person,
            ),
          ],
    selectedId: selected,
    initialLoading: widget.loading,
    failureLabel: widget.failed ? 'Не удалось обновить' : null,
    onConversationSelected: (id) => setState(() => selected = id),
    onSearchChanged: (_) {},
    onCreateConversation: () {},
  );
}

class _ComposerScenario extends StatefulWidget {
  const _ComposerScenario({
    this.readOnly = false,
    this.withReply = false,
    this.withAttachment = false,
    this.recording = false,
  });
  final bool readOnly;
  final bool withReply;
  final bool withAttachment;
  final bool recording;
  @override
  State<_ComposerScenario> createState() => _ComposerScenarioState();
}

class _ComposerScenarioState extends State<_ComposerScenario> {
  String text = '';
  CarpenterRecordingKind kind = CarpenterRecordingKind.voice;
  @override
  Widget build(BuildContext context) => CarpenterChatComposer(
    view: CarpenterComposerView(
      text: text,
      readOnly: widget.readOnly,
      replyPreview: widget.withReply ? 'Анна: Проверьте' : null,
      attachments: widget.withAttachment ? const [_demoMedia] : const [],
    ),
    recording: CarpenterRecordingView(
      kind: kind,
      phase: widget.recording
          ? CarpenterRecordingPhase.locked
          : CarpenterRecordingPhase.idle,
      level: .7,
    ),
    onTextChanged: (value) => setState(() => text = value),
    onSendRequested: (_) => setState(() => text = ''),
    onAttachmentsRequested: () {},
    onAttachmentRemoved: (_) {},
    onReplyRemoved: () {},
    onRecordingModeChanged: (value) => setState(() => kind = value),
    onRecordingStart: (_) {},
    onRecordingLock: (_) {},
    onRecordingStop: (_) {},
  );
}

class _MediaScenario extends StatefulWidget {
  const _MediaScenario({required this.kind, required this.large});
  final CarpenterMediaKind kind;
  final bool large;
  @override
  State<_MediaScenario> createState() => _MediaScenarioState();
}

class _MediaScenarioState extends State<_MediaScenario> {
  bool focused = false;
  bool playing = false;
  double speed = 1;
  @override
  Widget build(BuildContext context) => CarpenterInlineMedia(
    view: CarpenterMediaView(
      id: 'media',
      kind: widget.kind,
      label: 'Медиа',
      byteLength: widget.large ? carpenterEagerMediaLimitBytes + 1 : 1024,
      loadState: widget.large
          ? CarpenterMediaLoadState.previewReady
          : CarpenterMediaLoadState.ready,
      duration: const Duration(seconds: 42),
      waveform: const [2, 7, 4, 10, 5],
      focused: focused,
      playing: playing,
      playbackRate: speed,
    ),
    preview: const ColoredBox(color: Color(0xff7b5cd6)),
    onLoadRequested: () {},
    onPlayPauseRequested: () => setState(() => playing = !playing),
    onSpeedChanged: (value) => setState(() => speed = value),
    onFocusChanged: (value) => setState(() => focused = value),
  );
}

const _demoMedia = CarpenterMediaView(
  id: 'photo',
  kind: CarpenterMediaKind.image,
  label: 'Фото.jpg',
  byteLength: 2048,
  loadState: CarpenterMediaLoadState.ready,
);
