import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draft label is danger text and preview stays one line', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        CarpenterConversationDirectory(
          searchController: controller,
          conversations: const [
            CarpenterConversationView(
              id: 'room',
              title: 'Северный парк',
              preview: 'Старое сообщение',
              draft: 'Черновик сообщения, который не должен расширить строку',
              avatarShape: CarpenterConversationAvatarShape.room,
              unreadCount: 3,
            ),
          ],
          selectedId: null,
          onConversationSelected: (_) {},
          onSearchChanged: (_) {},
          onCreateConversation: () {},
        ),
      ),
    );

    final draft = tester.widget<CarpenterText>(
      find.widgetWithText(CarpenterText, 'Черновик'),
    );
    expect(draft.feedbackRole, FeedbackColorRole.danger);
    expect(draft.maxLines, 1);
    final previewFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CarpenterText && widget.data.contains('Черновик сообщения'),
    );
    final preview = tester.widget<CarpenterText>(previewFinder);
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
    expect(
      tester.getCenter(find.text('3')).dx,
      greaterThan(tester.getCenter(previewFinder).dx),
    );
  });

  testWidgets(
    'initial loading renders six skeletons and failure keeps stale rows',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          CarpenterConversationDirectory(
            searchController: controller,
            conversations: const [],
            selectedId: null,
            initialLoading: true,
            onConversationSelected: (_) {},
            onSearchChanged: (_) {},
            onCreateConversation: () {},
          ),
        ),
      );
      expect(
        find.byType(CarpenterConversationSkeleton),
        findsNWidgets(CarpenterConversationSkeleton.initialCount),
      );

      await tester.pumpWidget(
        _host(
          CarpenterConversationDirectory(
            searchController: controller,
            conversations: const [
              CarpenterConversationView(
                id: 'person',
                title: 'Анна',
                preview: 'Последнее доступное сообщение',
                avatarShape: CarpenterConversationAvatarShape.person,
              ),
            ],
            selectedId: null,
            failureLabel: 'Не удалось обновить',
            statusLabel: 'Синхронизируем разговор…',
            onConversationSelected: (_) {},
            onSearchChanged: (_) {},
            onCreateConversation: () {},
          ),
        ),
      );
      expect(find.text('Анна'), findsOneWidget);
      expect(find.text('Не удалось обновить'), findsOneWidget);
      expect(find.text('Синхронизируем разговор…'), findsOneWidget);
    },
  );
}

Widget _host(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(child: SizedBox.expand(child: child)),
      ),
    ),
  ),
);
