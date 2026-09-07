import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all-no-op tree patch batch retains root list identity', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatches(const [
      CarpenterTreeRemoved<String>('missing'),
      CarpenterTreeMoved<String>(id: 'also-missing', parentId: 'root'),
    ]);
    expect(next, same(roots));
  });
}
