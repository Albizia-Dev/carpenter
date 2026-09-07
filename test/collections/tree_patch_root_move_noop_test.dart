import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root node may move within root ordering', () {
    const a = CarpenterTreeNode(id: 'a', value: 'a', label: 'A');
    const b = CarpenterTreeNode(id: 'b', value: 'b', label: 'B');
    final roots = <CarpenterTreeNode<String>>[a, b];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeMoved<String>(id: 'a', index: 1),
    );
    expect(next, [b, a]);
  });
}
