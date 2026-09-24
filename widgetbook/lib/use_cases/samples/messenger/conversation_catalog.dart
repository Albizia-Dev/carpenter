import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../helpers/layout_viewport.dart';

final conversationComponents = [
  WidgetbookComponent(
    name: 'Conversation tile',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => _TileScenario(
          group: context.knobs.boolean(label: 'Групповой чат'),
          unread: context.knobs.boolean(label: 'Непрочитанные'),
          draft: context.knobs.boolean(label: 'Черновик'),
          ownPreview: context.knobs.boolean(label: 'Своё сообщение'),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Muted group with unread',
        builder: (context) =>
            const _TileScenario(group: true, unread: true, initialMuted: true),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Conversation header',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => CarpenterConversationHeader(
          title: context.knobs.string(
            label: 'Имя',
            initialValue: 'Северный парк',
          ),
          status: context.knobs.string(
            label: 'Статус',
            initialValue: 'Анна печатает…',
          ),
          avatar: const CarpenterConversationAvatar(
            name: 'Северный парк',
            shape: CarpenterConversationAvatarShape.room,
          ),
          onBack: context.knobs.boolean(label: 'Узкий экран') ? () {} : null,
          actions: CarpenterIconButton(
            icon: GravityIcons.ellipsis,
            semanticLabel: 'Действия с разговором',
            onPressed: () {},
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Conversation loading',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => Column(
          children: List.generate(
            CarpenterConversationSkeleton.initialCount,
            (index) => CarpenterConversationSkeleton(key: ValueKey(index)),
          ),
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Chat composer',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => _ChatComposerScenario(
          hasAttachments: context.knobs.boolean(label: 'Есть вложения'),
          enabled: !context.knobs.boolean(label: 'Только чтение'),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Recording locked',
        builder: (context) =>
            const _ChatComposerScenario(initiallyRecording: true),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Attachment strip',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => const _AttachmentStripScenario(),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Conversation split view',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) =>
            layoutViewportPreview(context, child: const _SplitScenario()),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Message timeline chrome',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => Column(
          children: [
            const CarpenterMessageDateDivider(label: '24.09.2026'),
            const CarpenterMessageSystemEvent(text: 'Анна закрепила сообщение'),
            CarpenterJumpToLatest(
              newerCount: context.knobs.int.slider(
                label: 'Новые сообщения',
                min: 0,
                max: 20,
              ),
              onPressed: () {},
            ),
            CarpenterMessageSelectionBar(
              count: context.knobs.int.slider(
                label: 'Выбрано',
                min: 1,
                max: 10,
              ),
              onClear: () {},
              onActions: () {},
            ),
          ],
        ),
      ),
    ],
  ),
  WidgetbookComponent(
    name: 'Voice controls',
    useCases: [
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) => _VoiceScenario(
          phase: context.knobs.object.dropdown(
            label: 'Запись',
            options: CarpenterVoicePhase.values,
            initialOption: CarpenterVoicePhase.preview,
          ),
          playingMessage: context.knobs.boolean(label: 'Воспроизведение'),
        ),
      ),
      WidgetbookUseCase(
        name: 'States · Recording error',
        builder: (context) =>
            const _VoiceScenario(phase: CarpenterVoicePhase.failed),
      ),
    ],
  ),
];

class _TileScenario extends StatefulWidget {
  const _TileScenario({
    this.group = false,
    this.unread = false,
    this.draft = false,
    this.initialMuted = false,
    this.ownPreview = false,
  });

  final bool group;
  final bool unread;
  final bool draft;
  final bool initialMuted;
  final bool ownPreview;

  @override
  State<_TileScenario> createState() => _TileScenarioState();
}

class _TileScenarioState extends State<_TileScenario> {
  bool selected = false;
  late bool muted = widget.initialMuted;

  @override
  Widget build(BuildContext context) => CarpenterConversationTile(
    title: widget.group ? 'Северный парк' : 'Анна Смирнова',
    preview: widget.draft
        ? 'Черновик: отправлю документы завтра'
        : widget.ownPreview
        ? 'Вы: отправлю документы завтра'
        : widget.group
        ? 'Анна: проверьте документы'
        : 'Проверьте документы',
    unreadCount: widget.unread ? 3 : 0,
    previewDelivery: widget.ownPreview ? CarpenterMessageDelivery.read : null,
    selected: selected,
    onSelected: () => setState(() => selected = true),
    avatar: CarpenterConversationAvatar(
      name: widget.group ? 'Северный парк' : 'Анна Смирнова',
      shape: widget.group
          ? CarpenterConversationAvatarShape.room
          : CarpenterConversationAvatarShape.person,
      muted: muted,
    ),
    actions: [
      CarpenterMenuItem(
        action: CarpenterActionDescriptor(
          id: 'mute',
          label: muted ? 'Включить уведомления' : 'Без звука',
          onInvoke: () => setState(() => muted = !muted),
        ),
      ),
    ],
  );
}

class _ChatComposerScenario extends StatefulWidget {
  const _ChatComposerScenario({
    this.hasAttachments = false,
    this.enabled = true,
    this.initiallyRecording = false,
  });

  final bool hasAttachments;
  final bool enabled;
  final bool initiallyRecording;

  @override
  State<_ChatComposerScenario> createState() => _ChatComposerScenarioState();
}

class _ChatComposerScenarioState extends State<_ChatComposerScenario> {
  String text = '';
  late bool recording = widget.initiallyRecording;

  @override
  Widget build(BuildContext context) => CarpenterChatComposer(
    text: text,
    enabled: widget.enabled,
    hasAttachments: widget.hasAttachments,
    recording: recording,
    onTextChanged: (value) => setState(() => text = value),
    onSend: () => setState(() => text = ''),
    onFilesRequested: () {},
    onVoiceRecord: () => setState(() => recording = true),
    onVoiceStop: () => setState(() => recording = false),
  );
}

class _AttachmentStripScenario extends StatefulWidget {
  const _AttachmentStripScenario();

  @override
  State<_AttachmentStripScenario> createState() =>
      _AttachmentStripScenarioState();
}

class _AttachmentStripScenarioState extends State<_AttachmentStripScenario> {
  final removed = <String>{};
  bool retried = false;

  @override
  Widget build(BuildContext context) => CarpenterAttachmentStrip(
    items: [
      const CarpenterAttachmentItem(
        id: 'ready',
        name: 'Фото объекта.jpg',
        phase: CarpenterMessengerUploadPhase.ready,
        detail: '2 МБ',
      ),
      const CarpenterAttachmentItem(
        id: 'uploading',
        name: 'План работ.pdf',
        phase: CarpenterMessengerUploadPhase.uploading,
        detail: '512 КБ / 1 МБ',
        progress: .5,
      ),
      CarpenterAttachmentItem(
        id: 'failed',
        name: 'Смета.xlsx',
        phase: retried
            ? CarpenterMessengerUploadPhase.ready
            : CarpenterMessengerUploadPhase.failed,
        detail: retried ? '840 КБ' : 'Не удалось загрузить',
      ),
    ].where((item) => !removed.contains(item.id)).toList(),
    onRetry: (_) => setState(() => retried = true),
    onCancel: (id) => setState(() => removed.add(id)),
    onRemove: (id) => setState(() => removed.add(id)),
  );
}

class _SplitScenario extends StatefulWidget {
  const _SplitScenario();

  @override
  State<_SplitScenario> createState() => _SplitScenarioState();
}

class _SplitScenarioState extends State<_SplitScenario> {
  bool selected = false;

  @override
  Widget build(BuildContext context) => CarpenterConversationSplitView(
    selected: selected,
    master: Center(
      child: CarpenterButton(
        label: 'Открыть чат',
        onPressed: () => setState(() => selected = true),
      ),
    ),
    detail: Center(
      child: CarpenterButton(
        label: 'К списку',
        onPressed: () => setState(() => selected = false),
      ),
    ),
    emptyDetail: const Center(child: CarpenterText.body('Выберите чат')),
  );
}

class _VoiceScenario extends StatefulWidget {
  const _VoiceScenario({required this.phase, this.playingMessage = false});

  final CarpenterVoicePhase phase;
  final bool playingMessage;

  @override
  State<_VoiceScenario> createState() => _VoiceScenarioState();
}

class _VoiceScenarioState extends State<_VoiceScenario> {
  Duration position = const Duration(seconds: 20);
  double speed = 1;
  bool playing = false;

  @override
  Widget build(BuildContext context) => CarpenterVoiceControls(
    phase: widget.phase,
    recordDuration: const Duration(seconds: 42),
    position: position,
    duration: const Duration(minutes: 1),
    speed: speed,
    playingMessage: widget.playingMessage,
    playing: playing,
    onRecord: () {},
    onPause: () {},
    onResume: () {},
    onStop: () {},
    onCancel: () {},
    onPreview: () => setState(() => playing = true),
    onAttach: () {},
    onRerecord: () {},
    onPlaybackPause: () => setState(() => playing = !playing),
    onSeek: (value) => setState(() => position = value),
    onSpeedChanged: (value) => setState(() => speed = value),
  );
}
