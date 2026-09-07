import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root removal preserves remaining node identity', () {
    const first = CarpenterTreeNode(id: 'a', value: 'a', label: 'A');
    const second = CarpenterTreeNode(id: 'b', value: 'b', label: 'B');
    final roots = <CarpenterTreeNode<String>>[first, second];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeRemoved<String>('a'),
    );
    expect(next, hasLength(1));
    expect(next.single, same(second));
  });
}
