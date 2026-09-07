import 'package:flutter/foundation.dart';

import '../../behaviour/drag_and_drop/drag_operation.dart';
import 'tree_state.dart';

@immutable
final class CarpenterTreeDropDetails<T> {
  const CarpenterTreeDropDetails({
    required this.dragged,
    required this.target,
    required this.position,
    required this.operation,
    this.draggedNodes = const [],
  });

  final CarpenterTreeNode<T> dragged;
  final CarpenterTreeNode<T> target;
  final CarpenterDropPosition position;
  final CarpenterDragOperation operation;

  /// Full drag selection when the gesture started from a selected row.
  /// Empty means the legacy single [dragged] node only.
  final List<CarpenterTreeNode<T>> draggedNodes;

  List<CarpenterTreeNode<T>> get effectiveDraggedNodes =>
      draggedNodes.isEmpty ? [dragged] : draggedNodes;
}

typedef CarpenterTreeExpansionChanged =
    void Function(Object nodeId, bool expanded);
typedef CarpenterTreeSelectionChanged = void Function(Set<Object> selectedIds);
typedef CarpenterTreeDropCallback<T> =
    void Function(CarpenterTreeDropDetails<T> details);
typedef CarpenterTreeDropAcceptance<T> =
    bool Function(CarpenterTreeDropDetails<T> details);
typedef CarpenterTreeNodeCallback<T> = void Function(CarpenterTreeNode<T> node);
