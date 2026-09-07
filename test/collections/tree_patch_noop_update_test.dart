import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stale tree update preserves root list identity', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeUpdated(
        CarpenterTreeNode(id: 'missing', value: 'x', label: 'Missing'),
      ),
    );
    expect(next, same(roots));
  });
}
