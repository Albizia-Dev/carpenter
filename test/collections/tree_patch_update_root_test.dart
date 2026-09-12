import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root update uses replacement node directly', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(id: 'root', value: 'old', label: 'Old'),
    ];
    const replacement = CarpenterTreeNode(
      id: 'root',
      value: 'new',
      label: 'Новое',
    );
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeUpdated(replacement),
    );
    expect(next.single, same(replacement));
  });
}
