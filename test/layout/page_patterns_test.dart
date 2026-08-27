import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('collection page distinguishes exclusive collection states', (
    tester,
  ) async {
    var rendered = 0;
    var retried = 0;

    Future<void> pump(CollectionSnapshot<String> snapshot) => tester.pumpWidget(
      _harness(
        child: CarpenterCollectionPage<String, int>(
          title: 'Documents',
          snapshot: snapshot,
          selection: CollectionSelection<int>.none(),
          retryAction: CarpenterActionDescriptor(
            id: 'retry',
            label: 'Retry',
            onInvoke: () => retried += 1,
          ),
          collectionBuilder: (context, value) {
            rendered += 1;
            return Text('Rows ${value.items.length}');
          },
        ),
      ),
    );

    await pump(CollectionSnapshot<String>.initialLoading());
    expect(find.text('Loading collection'), findsOneWidget);

    await pump(
      CollectionSnapshot<String>(contentState: CollectionContentState.zero),
    );
    expect(find.text('No records yet'), findsOneWidget);

    await pump(
      CollectionSnapshot<String>(
        contentState: CollectionContentState.emptyResult,
      ),
    );
    expect(find.text('No matching records'), findsOneWidget);

    await pump(
      CollectionSnapshot<String>(
        initialFailure: const CollectionFailure(
          error: 'offline',
          message: 'Network unavailable',
        ),
      ),
    );
    expect(find.text('Network unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
    expect(rendered, 0);
  });

  testWidgets('refresh failure preserves collection and selection actions', (
    tester,
  ) async {
    var selectedActionInvoked = 0;
    await tester.pumpWidget(
      _harness(
        child: CarpenterCollectionPage<String, int>(
          title: 'Documents',
          snapshot: CollectionSnapshot<String>(
            items: const ['A'],
            freshness: CollectionFreshness.stale,
            refreshFailure: const CollectionFailure(
              error: 'timeout',
              message: 'Refresh timed out',
            ),
          ),
          selection: CollectionSelection<int>.multiple(const [1]),
          selectionActions: [
            CarpenterActionDescriptor(
              id: 'archive',
              label: 'Archive selected',
              onInvoke: () => selectedActionInvoked += 1,
            ),
          ],
          collectionBuilder: (context, snapshot) => Text(snapshot.items.single),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Refresh timed out'), findsOneWidget);
    await tester.tap(find.text('Archive selected'));
    expect(selectedActionInvoked, 1);
  });

  testWidgets('filter bar remains externally controlled and exposes filters', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var query = '';
    var cleared = 0;
    await tester.pumpWidget(
      _harness(
        child: CarpenterFilterBar(
          searchController: controller,
          onSearchChanged: (value) => query = value,
          activeFilterCount: 2,
          clearAction: CarpenterActionDescriptor(
            id: 'clear',
            label: 'Clear filters',
            onInvoke: () => cleared += 1,
          ),
          filterControls: const [Text('Status filter')],
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'invoice');
    expect(query, 'invoice');
    expect(controller.text, 'invoice');
    expect(find.text('2 active filters'), findsOneWidget);
    expect(find.text('Status filter'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    expect(cleared, 1);
  });

  testWidgets('object page adapts secondary region without losing content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 1100,
        child: const CarpenterObjectPage(
          title: 'Object',
          primaryContent: Text('Primary object'),
          secondaryRegion: Text('Metadata panel'),
        ),
      ),
    );
    expect(find.text('Primary object'), findsOneWidget);
    expect(find.text('Metadata panel'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        width: 380,
        child: const CarpenterObjectPage(
          title: 'Object',
          primaryContent: Text('Primary object'),
          secondaryRegion: Text('Metadata panel'),
        ),
      ),
    );
    expect(find.text('Primary object'), findsOneWidget);
    expect(find.text('Metadata panel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form page delegates model and action state to its caller', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'draft');
    addTearDown(controller.dispose);
    var saved = 0;
    var cancelled = 0;
    await tester.pumpWidget(
      _harness(
        child: CarpenterFormPage(
          title: 'Edit document',
          dirty: true,
          validationSummary: const Text('Validation summary'),
          formContent: CarpenterInput(controller: controller, label: 'Name'),
          saveAction: CarpenterActionDescriptor(
            id: 'save',
            label: 'Save',
            onInvoke: () => saved += 1,
          ),
          cancelAction: CarpenterActionDescriptor(
            id: 'cancel',
            label: 'Cancel',
            onInvoke: () => cancelled += 1,
          ),
        ),
      ),
    );

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(find.text('Validation summary'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Cancel'));
    expect(saved, 1);
    expect(cancelled, 1);
    expect(controller.text, 'draft');
  });

  testWidgets('master detail page is controlled and closes narrow detail', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      _harness(
        width: 380,
        child: CarpenterMasterDetailPage<int>(
          title: 'Records',
          master: const Text('Master records'),
          selectedValue: 42,
          detailBuilder: (context, value) => Text('Record $value'),
          onDetailClosed: () => closed += 1,
        ),
      ),
    );

    expect(find.text('Record 42'), findsOneWidget);
    expect(find.text('Master records'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);

    await tester.pumpWidget(
      _harness(
        width: 380,
        child: CarpenterMasterDetailPage<int>(
          title: 'Records',
          master: const Text('Master records'),
          selectedValue: null,
          detailBuilder: (context, value) => Text('Record $value'),
          onDetailClosed: () => closed += 1,
        ),
      ),
    );
    expect(find.text('Master records'), findsOneWidget);
    expect(find.text('Record 42'), findsNothing);
  });

  testWidgets('page action shortcuts work with keyboard focus', (tester) async {
    var invoked = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _harness(
        child: CarpenterObjectPage(
          title: 'Shortcut page',
          primaryContent: Focus(
            focusNode: focusNode,
            child: const Text('Focusable content'),
          ),
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'save',
              label: 'Save',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
              ),
              onInvoke: () => invoked += 1,
            ),
          ],
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(invoked, 1);
  });

  testWidgets('patterns support narrow RTL at 200 percent text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 360,
        direction: TextDirection.rtl,
        textScale: 2,
        child: CarpenterObjectPage(
          title: 'صفحة الكائن',
          subtitle: 'وصف طويل للمحتوى الدلالي في الصفحة',
          primaryContent: const Text('المحتوى الرئيسي'),
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'edit',
              label: 'تحرير المستند',
              onInvoke: _noop,
            ),
          ],
        ),
      ),
    );
    expect(find.text('المحتوى الرئيسي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _harness({
  required Widget child,
  double width = 800,
  double height = 600,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    ),
  ),
);

void _noop() {}
