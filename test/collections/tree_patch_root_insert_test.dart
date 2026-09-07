import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root insert clamps an oversized index', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'a', value: 'a', label: 'A'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeInserted(
        node: CarpenterTreeNode(id: 'b', value: 'b', label: 'B'),
        index: 999,
      ),
    );
    expect(next.map((node) => node.id), ['a', 'b']);
  });
}
