import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nodes = <CarpenterTreeNode<String>>[
    CarpenterTreeNode<String>(
      id: 'root',
      value: 'root',
      label: 'Root',
      children: [
        CarpenterTreeNode<String>(
          id: 'documents',
          value: 'documents',
          label: 'Documents',
          children: [
            CarpenterTreeNode<String>(
              id: 'specification',
              value: 'specification',
              label: 'Specification.md',
            ),
            CarpenterTreeNode<String>(
              id: 'budget',
              value: 'budget',
              label: 'Budget.xlsx',
            ),
          ],
        ),
      ],
    ),
    CarpenterTreeNode<String>(
      id: 'archive',
      value: 'archive',
      label: 'Archive',
    ),
  ];

  test('filtered flattening keeps the complete matching path visible', () {
    final flattened = flattenFilteredCarpenterTree<String>(
      nodes,
      const {},
      (node) => node.label.contains('Specification'),
    );

    expect(
      flattened.map((entry) => entry.node.id),
      orderedEquals(['root', 'documents', 'specification']),
    );
    expect(flattened.map((entry) => entry.depth), orderedEquals([0, 1, 2]));
  });

  test('find path returns ancestors in root-to-node order', () {
    final path = findCarpenterTreePath<String>(nodes, 'budget');

    expect(path, isNotNull);
    expect(
      path!.map((node) => node.id),
      orderedEquals(['root', 'documents', 'budget']),
    );
  });

  test('find path returns null for unknown node', () {
    expect(findCarpenterTreePath<String>(nodes, 'missing'), isNull);
  });
}
