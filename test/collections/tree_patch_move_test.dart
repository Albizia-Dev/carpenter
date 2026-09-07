import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moving to root preserves the source node instance', () {
    const child = CarpenterTreeNode(id: 'child', value: 'child', label: 'Child');
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'parent',
        value: 'parent',
        label: 'Parent',
        children: [child],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(id: 'child', index: 0),
    );
    expect(next.first, same(child));
  });
}
