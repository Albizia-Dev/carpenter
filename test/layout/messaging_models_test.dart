import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message keeps stable identity and independent attention flags', () {
    final sentAt = DateTime.utc(2026, 9, 24, 10);
    final message = CarpenterMessageView(
      id: r'$event',
      authorId: '@u:okibi',
      authorLabel: 'Анна',
      body: 'Проверьте',
      own: false,
      sentAt: sentAt,
      meta: const CarpenterMessageMeta(important: true, requiresAnswer: true),
    );

    expect(message.id, r'$event');
    expect(message.sentAt, same(sentAt));
    expect(message.meta.important, isTrue);
    expect(message.meta.requiresAnswer, isTrue);
  });

  test('conversation preview does not infer delivery for incoming events', () {
    const conversation = CarpenterConversationView(
      id: '!room:okibi',
      title: 'Проект',
      preview: 'Анна: Готово',
      avatarShape: CarpenterConversationAvatarShape.room,
      previewOwn: false,
      previewDelivery: CarpenterDeliveryState.read,
    );

    expect(conversation.effectivePreviewDelivery, isNull);
  });

  test('large original media requires an explicit load action', () {
    const media = CarpenterMediaView(
      id: 'attachment',
      kind: CarpenterMediaKind.video,
      label: 'Видео',
      byteLength: 10 * 1024 * 1024 + 1,
      loadState: CarpenterMediaLoadState.previewReady,
    );

    expect(media.requiresExplicitOriginalLoad, isTrue);
  });
}
