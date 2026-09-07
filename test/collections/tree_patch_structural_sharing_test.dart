import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tree update retains untouched root object identity', () {
    const child = CarpenterTreeNode(
      id: 'child',
      value: 'child',
      label: 'Child',
    );
    const untouched = CarpenterTreeNode(
      id: 'untouched',
      value: 'untouched',
      label: 'Untouched',
    );
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [child],
      ),
      untouched,
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeUpdated(
        CarpenterTreeNode(id: 'child', value: 'new', label: 'New'),
      ),
    );
    expect(next[1], same(untouched));
  });
}
