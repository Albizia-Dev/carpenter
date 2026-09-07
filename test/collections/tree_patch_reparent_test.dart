import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('node can reparent between sibling branches', () {
    const moved = CarpenterTreeNode(
      id: 'moved',
      value: 'moved',
      label: 'Moved',
    );
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'a',
        value: 'a',
        label: 'A',
        children: [moved],
      ),
      const CarpenterTreeNode(id: 'b', value: 'b', label: 'B'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(id: 'moved', parentId: 'b'),
    );
    expect(findCarpenterTreeNode(next, 'a')!.children, isEmpty);
    expect(findCarpenterTreeNode(next, 'b')!.children.single, same(moved));
  });
}
