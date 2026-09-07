import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordered patches may insert then remove the same node', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatches(const [
      CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        parentId: 'root',
      ),
      CarpenterTreeRemoved<String>('child'),
    ]);
    expect(findCarpenterTreeNode(next, 'child'), isNull);
  });
}
