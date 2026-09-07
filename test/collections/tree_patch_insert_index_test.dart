import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nested insertion honors the requested position', () {
    const a = CarpenterTreeNode(id: 'a', value: 'a', label: 'A');
    const b = CarpenterTreeNode(id: 'b', value: 'b', label: 'B');
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [a, b],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'x', value: 'x', label: 'X'),
        parentId: 'root',
        index: 1,
      ),
    );
    expect(next.single.children.map((node) => node.id), ['a', 'x', 'b']);
  });
}
