import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('tree sibling alignment and height at $scale', (tester) async {
      await tester.pumpWidget(
        carpenterHarness(
          const SizedBox(
            width: 500,
            child: CarpenterTreeView<String>(
              nodes: [
                CarpenterTreeNode(
                  id: 'folder',
                  value: '',
                  label: 'Folder',
                  hasChildren: true,
                ),
                CarpenterTreeNode(id: 'file', value: '', label: 'File'),
              ],
            ),
          ),
          textScale: scale,
        ),
      );
      final folder = tester.getRect(find.text('Folder'));
      final file = tester.getRect(find.text('File'));
      expect(folder.left, file.left);
      final rows = find.byType(CarpenterListTile);
      expect(
        tester.getSize(rows.at(0)).height,
        tester.getSize(rows.at(1)).height,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets('rich list trailing placement at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        carpenterOverlayHarness(
          SizedBox(
            width: width,
            child: const CarpenterListTile(
              title: Text('Counterparty'),
              subtitle: Text('Payment purpose'),
              trailing: Text('2 450 000 RUB'),
            ),
          ),
        ),
      );
      final title = tester.getRect(find.text('Counterparty'));
      final subtitle = tester.getRect(find.text('Payment purpose'));
      final amount = tester.getRect(find.text('2 450 000 RUB'));
      if (width < 640) {
        expect(amount.top, greaterThan(subtitle.bottom));
        expect(amount.left, title.left);
      } else {
        expect(amount.top, title.top);
        expect(amount.left, greaterThan(title.right));
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('disclosure preserves controlled expansion and row selection', (
    tester,
  ) async {
    Set<Object> expanded = {};
    Set<Object> selected = {};
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, update) {
            return CarpenterTreeView<String>(
              nodes: const [
                CarpenterTreeNode(
                  id: 'folder',
                  value: '',
                  label: 'Folder',
                  children: [
                    CarpenterTreeNode(id: 'file', value: '', label: 'File'),
                  ],
                ),
              ],
              expandedIds: expanded,
              selectedIds: selected,
              onExpansionChanged: (id, value) =>
                  update(() => expanded = value ? {id} : {}),
              onSelectionChanged: (ids) => update(() => selected = ids),
            );
          },
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Expand Folder'));
    await tester.pumpAndSettle();
    expect(expanded, {'folder'});
    await tester.tap(find.text('File'));
    await tester.pump();
    expect(selected, {'file'});
    await tester.tap(find.bySemanticsLabel('Collapse Folder'));
    await tester.pumpAndSettle();
    expect(find.text('File'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'expander header keyboard and embedded action remain independent',
    (tester) async {
      var refreshed = 0;
      final changes = <bool>[];
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterExpander(
            initiallyExpanded: true,
            onChanged: changes.add,
            header: Row(
              children: [
                const Expanded(child: Text('Assignments')),
                CarpenterButton(label: 'Refresh', onInvoke: () => refreshed++),
              ],
            ),
            content: const Text('Assignment content'),
          ),
        ),
      );
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(refreshed, 1);
      expect(changes, isEmpty);
      expect(find.text('Assignment content'), findsOneWidget);
      await tester.tap(find.text('Assignments'));
      await tester.pumpAndSettle();
      expect(changes, [false]);
      expect(find.text('Assignment content'), findsNothing);
      FocusScope.of(tester.element(find.text('Assignments'))).nextFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, [false, true]);
      expect(find.text('Assignment content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('list group adds no insets around its rows', (tester) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterExpander.listGroup(
          key: ValueKey('group'),
          initiallyExpanded: true,
          header: Text('Today'),
          content: SizedBox(
            key: ValueKey('rows'),
            height: 80,
            width: double.infinity,
          ),
        ),
      ),
    );
    final group = tester.getRect(find.byKey(const ValueKey('group')));
    final rows = tester.getRect(find.byKey(const ValueKey('rows')));
    final header = tester.getRect(find.byType(FocusableActionDetector).first);
    expect(rows.left, group.left);
    expect(rows.right, group.right);
    expect(rows.top, header.bottom);
    expect(rows.bottom, group.bottom);
    expect(find.byType(CarpenterCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
