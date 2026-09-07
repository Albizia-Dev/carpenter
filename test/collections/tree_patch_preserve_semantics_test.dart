import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ancestry copy preserves label and semantic metadata', () {
    final roots = <CarpenterTreeNode<String>>[
      const CarpenterTreeNode(
        id: 'root',
        value: 'root',
        label: 'Visible root',
        semanticLabel: 'Semantic root',
        children: [
          CarpenterTreeNode(id: 'child', value: 'child', label: 'Child'),
        ],
      ),
    ];
    final next = roots.applyCarpenterTreePatch(
      const CarpenterTreeUpdated(
        CarpenterTreeNode(id: 'child', value: 'new', label: 'New child'),
      ),
    );
    expect(next.single.label, 'Visible root');
    expect(next.single.semanticLabel, 'Semantic root');
  });
}
