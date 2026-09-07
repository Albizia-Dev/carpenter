import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nested node can move to root at a requested index', () {
    const child = CarpenterTreeNode(id: 'child', value: 'child', label: 'Child');
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'parent',
        value: 'parent',
        label: 'Parent',
        children: [child],
      ),
      const CarpenterTreeNode(id: 'tail', value: 'tail', label: 'Tail'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(id: 'child', index: 1),
    );
    expect(next[1], same(child));
  });
}
