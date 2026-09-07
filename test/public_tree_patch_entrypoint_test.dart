import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main entrypoint exposes tree presentation patches', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        parentId: 'root',
      ),
    );
    expect(next.single.children.single.id, 'child');
  });
}
