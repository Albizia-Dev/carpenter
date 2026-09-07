import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nested insert preserves unrelated root object identity', () {
    const root = CarpenterTreeNode(id: 'root', value: 'root', label: 'Root');
    const untouched = CarpenterTreeNode(id: 'u', value: 'u', label: 'U');
    final roots = <CarpenterTreeNode<String>>[root, untouched];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        parentId: 'root',
      ),
    );
    expect(next.first, isNot(same(root)));
    expect(next[1], same(untouched));
  });
}
