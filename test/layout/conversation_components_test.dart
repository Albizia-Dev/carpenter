import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('count badge never becomes narrower than its height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const Center(child: CarpenterBadge.count(3))),
    );

    final size = tester.getSize(find.byType(CarpenterBadge));
    expect(size.width, greaterThanOrEqualTo(size.height));
  });

  testWidgets('count badge stays square at increased text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: CarpenterBadge.count(3)),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CarpenterBadge));
    expect(size.width, greaterThanOrEqualTo(size.height));
  });

  testWidgets('room avatars are square and show mute state', (tester) async {
    await tester.pumpWidget(
      _host(
        const CarpenterConversationAvatar(
          name: 'Северный парк',
          shape: CarpenterConversationAvatarShape.room,
          muted: true,
        ),
      ),
    );
    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.bySemanticsLabel('Без звука'), findsOneWidget);
  });

  testWidgets('conversation row opens its host action menu', (tester) async {
    var muted = false;
    await tester.pumpWidget(
      _host(
        CarpenterConversationTile(
          title: 'Анна',
          preview: 'Проверьте документ',
          avatar: const CarpenterConversationAvatar(
            name: 'Анна',
            shape: CarpenterConversationAvatarShape.person,
          ),
          selected: false,
          onSelected: () {},
          unreadCount: 2,
          timestampLabel: '01:59',
          previewDelivery: CarpenterDeliveryState.read,
          actions: [
            CarpenterMenuItem(
              action: CarpenterActionDescriptor(
                id: 'mute',
                label: 'Без звука',
                onInvoke: () => muted = true,
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    expect(
      tester
          .widget<CarpenterListTile>(find.byType(CarpenterListTile))
          .presentation,
      CarpenterListTilePresentation.standard,
    );
    expect(find.text('01:59'), findsOneWidget);
    expect(find.bySemanticsLabel('Прочитано'), findsOneWidget);
    expect(
      tester.getCenter(find.text('01:59')).dy,
      lessThan(tester.getCenter(find.text('2')).dy),
    );
    await tester.longPress(find.text('Анна').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Без звука').last);
    expect(muted, isTrue);
  });

  testWidgets('chat composer sends attachment only draft', (tester) async {
    var sends = 0;
    await tester.pumpWidget(
      _host(
        CarpenterChatComposer(
          view: const CarpenterComposerView(
            text: '',
            attachments: [
              CarpenterMediaView(
                id: 'attachment',
                kind: CarpenterMediaKind.file,
                label: 'Файл',
                byteLength: 1,
                loadState: CarpenterMediaLoadState.ready,
              ),
            ],
          ),
          recording: const CarpenterRecordingView(
            kind: CarpenterRecordingKind.voice,
            phase: CarpenterRecordingPhase.idle,
          ),
          onTextChanged: (_) {},
          onSendRequested: (_) => sends++,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Отправить'));
    expect(sends, 1);
  });
}

Widget _host(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          child: Overlay(
            initialEntries: [
              OverlayEntry(builder: (_) => SizedBox.expand(child: child)),
            ],
          ),
        ),
      ),
    ),
  ),
);
