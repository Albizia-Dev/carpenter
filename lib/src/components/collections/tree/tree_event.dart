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
  });

  final CarpenterTreeNode<T> dragged;
  final CarpenterTreeNode<T> target;
  final CarpenterDropPosition position;
  final CarpenterDragOperation operation;
}

typedef CarpenterTreeExpansionChanged =
    void Function(Object nodeId, bool expanded);
typedef CarpenterTreeSelectionChanged = void Function(Set<Object> selectedIds);
typedef CarpenterTreeDropCallback<T> =
    void Function(CarpenterTreeDropDetails<T> details);
typedef CarpenterTreeDropAcceptance<T> =
    bool Function(CarpenterTreeDropDetails<T> details);
typedef CarpenterTreeNodeCallback<T> = void Function(CarpenterTreeNode<T> node);
