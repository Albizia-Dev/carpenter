/// Shape of an identity avatar in a conversation surface.
enum CarpenterConversationAvatarShape { person, room }

/// Delivery state explicitly supplied by the host application.
enum CarpenterDeliveryState { sending, sent, read, failed }

/// Presence state explicitly supplied by the host application.
enum CarpenterPresenceKind {
  online,
  offline,
  typing,
  recordingVoice,
  recordingVideo,
}

/// Send semantics selected in the composer.
enum CarpenterSendMode { ordinary, important, requiresAnswer }

/// Media presentation supported by a message bubble.
enum CarpenterMediaKind { image, video, audio, voice, videoCircle, file }

/// Host-owned loading phase for an inline media item.
enum CarpenterMediaLoadState {
  previewLoading,
  previewReady,
  originalLoading,
  ready,
  failed,
}

/// Recording kind selected by the composer action.
enum CarpenterRecordingKind { voice, video }

/// Host-owned recording lifecycle.
enum CarpenterRecordingPhase {
  idle,
  requestingPermission,
  recording,
  locked,
  stopping,
  preview,
  failed,
  unavailable,
}

/// Original payloads above this size require an explicit user action.
const carpenterEagerMediaLimitBytes = 10 * 1024 * 1024;

/// Immutable directory projection. Ordering and persistence remain host-owned.
final class CarpenterConversationView {
  const CarpenterConversationView({
    required this.id,
    required this.title,
    required this.preview,
    required this.avatarShape,
    this.previewAuthor,
    this.previewOwn = false,
    this.previewDelivery,
    this.draft,
    this.unreadCount = 0,
    this.muted = false,
    this.pinned = false,
    this.selected = false,
  });

  final String id;
  final String title;
  final String preview;
  final CarpenterConversationAvatarShape avatarShape;
  final String? previewAuthor;
  final bool previewOwn;
  final CarpenterDeliveryState? previewDelivery;
  final String? draft;
  final int unreadCount;
  final bool muted;
  final bool pinned;
  final bool selected;

  CarpenterDeliveryState? get effectivePreviewDelivery =>
      previewOwn ? previewDelivery : null;
}

/// Independent metadata rendered alongside an individual message.
final class CarpenterMessageMeta {
  const CarpenterMessageMeta({
    this.edited = false,
    this.important = false,
    this.requiresAnswer = false,
    this.forwardedFrom,
    this.delivery,
  });

  final bool edited;
  final bool important;
  final bool requiresAnswer;
  final String? forwardedFrom;
  final CarpenterDeliveryState? delivery;
}

/// Immutable host projection for one inline media item.
final class CarpenterMediaView {
  const CarpenterMediaView({
    required this.id,
    required this.kind,
    required this.label,
    required this.byteLength,
    required this.loadState,
    this.duration,
    this.position = Duration.zero,
    this.playing = false,
    this.playbackRate = 1,
    this.waveform = const [],
    this.focused = false,
  });

  final String id;
  final CarpenterMediaKind kind;
  final String label;
  final int byteLength;
  final CarpenterMediaLoadState loadState;
  final Duration? duration;
  final Duration position;
  final bool playing;
  final double playbackRate;
  final List<int> waveform;
  final bool focused;

  bool get requiresExplicitOriginalLoad =>
      byteLength > carpenterEagerMediaLimitBytes &&
      loadState != CarpenterMediaLoadState.originalLoading &&
      loadState != CarpenterMediaLoadState.ready;
}

/// Immutable host projection for one timeline entry.
final class CarpenterMessageView {
  const CarpenterMessageView({
    required this.id,
    required this.authorId,
    required this.authorLabel,
    required this.body,
    required this.own,
    required this.sentAt,
    this.meta = const CarpenterMessageMeta(),
    this.replyTargetId,
    this.replyPreview,
    this.media = const [],
    this.system = false,
    this.canReply = true,
    this.canRetry = false,
  });

  final String id;
  final String authorId;
  final String authorLabel;
  final String body;
  final bool own;
  final DateTime sentAt;
  final CarpenterMessageMeta meta;
  final String? replyTargetId;
  final String? replyPreview;
  final List<CarpenterMediaView> media;
  final bool system;
  final bool canReply;
  final bool canRetry;
}

/// Immutable host-owned composer state.
final class CarpenterComposerView {
  const CarpenterComposerView({
    required this.text,
    this.replyPreview,
    this.attachments = const [],
    this.sendMode = CarpenterSendMode.ordinary,
    this.readOnly = false,
    this.busy = false,
  });

  final String text;
  final String? replyPreview;
  final List<CarpenterMediaView> attachments;
  final CarpenterSendMode sendMode;
  final bool readOnly;
  final bool busy;

  bool get canSend =>
      !readOnly && !busy && (text.trim().isNotEmpty || attachments.isNotEmpty);
}

/// Immutable host-owned recording state.
final class CarpenterRecordingView {
  const CarpenterRecordingView({
    required this.kind,
    required this.phase,
    this.duration = Duration.zero,
    this.level = 0,
    this.voiceAvailable = true,
    this.videoAvailable = true,
    this.failureLabel,
  });

  final CarpenterRecordingKind kind;
  final CarpenterRecordingPhase phase;
  final Duration duration;
  final double level;
  final bool voiceAvailable;
  final bool videoAvailable;
  final String? failureLabel;
}
