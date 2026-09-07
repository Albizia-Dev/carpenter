import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty patch batch preserves root list identity', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    expect(
      roots.applyCarpenterTreePatches(const <CarpenterTreePatch<String>>[]),
      same(roots),
    );
  });
}
