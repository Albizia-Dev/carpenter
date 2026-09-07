import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nested removal keeps sibling identity', () {
    const removed = CarpenterTreeNode(id: 'remove', value: 'r', label: 'Remove');
    const sibling = CarpenterTreeNode(id: 'keep', value: 'k', label: 'Keep');
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [removed, sibling],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeRemoved<String>('remove'),
    );
    expect(next.single.children.single, same(sibling));
  });
}
