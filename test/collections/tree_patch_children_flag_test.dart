import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inserting first loaded child makes copied parent expandable', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        hasChildren: false,
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        parentId: 'root',
      ),
    );
    expect(next.single.canExpand, isTrue);
  });
}
