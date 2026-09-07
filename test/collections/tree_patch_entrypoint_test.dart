import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collections entrypoint exposes tree patches', () {
    const child = CarpenterTreeNode(
      id: 'child',
      value: 'child',
      label: 'Child',
    );
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(node: child, parentId: 'root'),
    );
    expect(next.single.children.single, same(child));
  });
}
