import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insert into a stale missing parent is a no-op', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        parentId: 'missing',
      ),
    );
    expect(next, same(roots));
  });
}
