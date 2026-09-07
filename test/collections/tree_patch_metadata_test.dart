import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ancestry rewrite preserves lazy load metadata', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Root',
        hasChildren: true,
        loadState: CarpenterTreeLoadState.failed,
        errorText: 'Retry me',
        children: [
          CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        ],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeUpdated(
        CarpenterTreeNode(id: 'child', value: 'new', label: 'New'),
      ),
    );
    expect(next.single.hasChildren, isTrue);
    expect(next.single.loadState, CarpenterTreeLoadState.failed);
    expect(next.single.errorText, 'Retry me');
  });
}
