import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moving a node into itself is rejected', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    expect(
      roots.applyCarpenterTreePatch(
        const CarpenterTreeMoved<String>(id: 'root', parentId: 'root'),
      ),
      same(roots),
    );
  });
}
