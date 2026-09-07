import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('move to a stale missing parent does not remove the source', () {
    const child = CarpenterTreeNode(
      id: 'child',
      value: 'child',
      label: 'Child',
    );
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [child],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(id: 'child', parentId: 'missing'),
    );
    expect(next, same(roots));
    expect(findCarpenterTreeNode(next, 'child'), same(child));
  });
}
