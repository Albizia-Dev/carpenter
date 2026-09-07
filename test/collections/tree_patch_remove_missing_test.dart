import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stale removal leaves tree untouched', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'root', label: 'Root'),
    ];
    expect(
      roots.applyCarpenterTreePatch(
        const CarpenterTreeRemoved<String>('missing'),
      ),
      same(roots),
    );
  });
}
