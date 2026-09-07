import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CarpenterTreeNode<String> node(
    String id, {
    List<CarpenterTreeNode<String>> children = const [],
  }) => CarpenterTreeNode<String>(
    id: id,
    value: id,
    label: id,
    children: children,
  );

  test('nested update copies only the affected ancestry', () {
    final child = node('child');
    final sibling = node('sibling');
    final root = node('root', children: [child, sibling]);
    final untouched = node('untouched');
    final roots = <CarpenterTreeNode<String>>[root, untouched];
    final replacement = CarpenterTreeNode<String>(
      id: 'child',
      value: 'updated',
      label: 'Updated',
    );

    final next = roots.applyCarpenterTreePatch(
      CarpenterTreeUpdated(replacement),
    );

    expect(next, isNot(same(roots)));
    expect(next.first, isNot(same(root)));
    expect(next.first.children.first, same(replacement));
    expect(next.first.children[1], same(sibling));
    expect(next[1], same(untouched));
  });

  test(
    'insert supports roots and nested parents and rejects duplicate ids',
    () {
      final root = node('root');
      final roots = <CarpenterTreeNode<String>>[root];
      final nested = node('nested');

      final withNested = roots.applyCarpenterTreePatch(
        CarpenterTreeInserted(node: nested, parentId: 'root'),
      );
      expect(withNested.first.children.single, same(nested));

      final appended = withNested.applyCarpenterTreePatch(
        CarpenterTreeInserted(node: node('second'), index: 0),
      );
      expect(appended.first.id, 'second');

      final duplicate = appended.applyCarpenterTreePatch(
        CarpenterTreeInserted(node: node('nested')),
      );
      expect(duplicate, same(appended));
    },
  );

  test('remove drops one subtree and preserves unrelated branches', () {
    final child = node('child', children: [node('grandchild')]);
    final sibling = node('sibling');
    final root = node('root', children: [child, sibling]);
    final untouched = node('untouched');
    final roots = <CarpenterTreeNode<String>>[root, untouched];

    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeRemoved<String>('child'),
    );

    expect(next.first.children.single, same(sibling));
    expect(findCarpenterTreeNode(next, 'grandchild'), isNull);
    expect(next[1], same(untouched));
  });

  test('move reparents the same node object and clamps its index', () {
    final moved = node('moved');
    final source = node('source', children: [moved]);
    final targetChild = node('target-child');
    final target = node('target', children: [targetChild]);
    final roots = <CarpenterTreeNode<String>>[source, target];

    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(
        id: 'moved',
        parentId: 'target',
        index: 99,
      ),
    );

    expect(next.first.children, isEmpty);
    expect(next[1].children.last, same(moved));
    expect(next[1].children.first, same(targetChild));
  });

  test('move into own descendant and stale patches are no-ops', () {
    final grandchild = node('grandchild');
    final child = node('child', children: [grandchild]);
    final root = node('root', children: [child]);
    final roots = <CarpenterTreeNode<String>>[root];

    expect(
      roots.applyCarpenterTreePatch(
        const CarpenterTreeMoved<String>(id: 'child', parentId: 'grandchild'),
      ),
      same(roots),
    );
    expect(
      roots.applyCarpenterTreePatch(
        const CarpenterTreeRemoved<String>('missing'),
      ),
      same(roots),
    );
    expect(
      roots.applyCarpenterTreePatch(CarpenterTreeUpdated(node('missing'))),
      same(roots),
    );
  });

  test('patch batches are applied in order', () {
    final roots = <CarpenterTreeNode<String>>[node('root')];
    final child = node('child');
    final updated = CarpenterTreeNode<String>(
      id: 'child',
      value: 'updated',
      label: 'Updated',
    );

    final next = roots.applyCarpenterTreePatches([
      CarpenterTreeInserted(node: child, parentId: 'root'),
      CarpenterTreeUpdated(updated),
      const CarpenterTreeMoved<String>(id: 'child', parentId: null, index: 0),
    ]);

    expect(next.first, same(updated));
    expect(findCarpenterTreeNode(next, 'root')!.children, isEmpty);
  });
}
