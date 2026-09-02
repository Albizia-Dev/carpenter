import 'package:flutter/foundation.dart';

import '../../behaviour/drag_and_drop/drag_operation.dart';

/// Loading state of a node whose children may be resolved lazily.
enum CarpenterTreeLoadState { ready, loading, failed }

enum CarpenterTreeSelectionMode { none, single, multiple }

typedef CarpenterTreeNodePredicate<T> =
    bool Function(CarpenterTreeNode<T> node);

@immutable
final class CarpenterTreeNode<T> {
  const CarpenterTreeNode({
    required this.id,
    required this.value,
    required this.label,
    this.children = const [],
    this.hasChildren,
    this.loadState = CarpenterTreeLoadState.ready,
    this.errorText,
    this.semanticLabel,
  });

  final Object id;
  final T value;
  final String label;
  final List<CarpenterTreeNode<T>> children;

  /// Set to true for lazy nodes that currently have no loaded children.
  final bool? hasChildren;
  final CarpenterTreeLoadState loadState;
  final String? errorText;
  final String? semanticLabel;

  bool get canExpand => hasChildren ?? children.isNotEmpty;
  String get effectiveSemanticLabel => semanticLabel ?? label;
}

@immutable
final class CarpenterTreeRowState<T> {
  const CarpenterTreeRowState({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.selected,
    required this.focused,
    required this.dragging,
    required this.hovering,
    required this.acceptsDrop,
    this.dropPosition,
  });

  final CarpenterTreeNode<T> node;
  final int depth;
  final bool expanded;
  final bool selected;
  final bool focused;
  final bool dragging;
  final bool hovering;
  final bool acceptsDrop;
  final CarpenterDropPosition? dropPosition;
}

@immutable
final class CarpenterTreeFlatNode<T> {
  const CarpenterTreeFlatNode({
    required this.node,
    required this.depth,
    this.parentId,
  });

  final CarpenterTreeNode<T> node;
  final int depth;
  final Object? parentId;
}

List<CarpenterTreeFlatNode<T>> flattenCarpenterTree<T>(
  List<CarpenterTreeNode<T>> roots,
  Set<Object> expandedIds,
) {
  final result = <CarpenterTreeFlatNode<T>>[];

  void visit(
    Iterable<CarpenterTreeNode<T>> nodes,
    int depth,
    Object? parentId,
  ) {
    for (final node in nodes) {
      result.add(
        CarpenterTreeFlatNode<T>(node: node, depth: depth, parentId: parentId),
      );
      if (expandedIds.contains(node.id) && node.children.isNotEmpty) {
        visit(node.children, depth + 1, node.id);
      }
    }
  }

  visit(roots, 0, null);
  return List.unmodifiable(result);
}

/// Flattens a filtered tree while retaining ancestors of matching nodes.
///
/// Matching paths are expanded for presentation without mutating the caller's
/// controlled [expandedIds]. Explicit expansion still controls unrelated
/// branches while the filter is active.
List<CarpenterTreeFlatNode<T>> flattenFilteredCarpenterTree<T>(
  List<CarpenterTreeNode<T>> roots,
  Set<Object> expandedIds,
  CarpenterTreeNodePredicate<T> predicate,
) {
  final matches = <Object, bool>{};

  bool subtreeMatches(CarpenterTreeNode<T> node) {
    final cached = matches[node.id];
    if (cached != null) return cached;
    final result = predicate(node) || node.children.any(subtreeMatches);
    matches[node.id] = result;
    return result;
  }

  final result = <CarpenterTreeFlatNode<T>>[];
  void visit(
    Iterable<CarpenterTreeNode<T>> nodes,
    int depth,
    Object? parentId,
  ) {
    for (final node in nodes) {
      if (!subtreeMatches(node)) continue;
      result.add(
        CarpenterTreeFlatNode<T>(node: node, depth: depth, parentId: parentId),
      );
      final hasMatchingChild = node.children.any(subtreeMatches);
      if ((expandedIds.contains(node.id) || hasMatchingChild) &&
          node.children.isNotEmpty) {
        visit(node.children, depth + 1, node.id);
      }
    }
  }

  visit(roots, 0, null);
  return List.unmodifiable(result);
}

bool carpenterTreeContains<T>(CarpenterTreeNode<T> root, Object id) {
  if (root.id == id) return true;
  return root.children.any((child) => carpenterTreeContains(child, id));
}

CarpenterTreeNode<T>? findCarpenterTreeNode<T>(
  Iterable<CarpenterTreeNode<T>> roots,
  Object id,
) {
  for (final node in roots) {
    if (node.id == id) return node;
    final nested = findCarpenterTreeNode(node.children, id);
    if (nested != null) return nested;
  }
  return null;
}

/// Returns the root-to-node path for [id], or null when the node is absent.
List<CarpenterTreeNode<T>>? findCarpenterTreePath<T>(
  Iterable<CarpenterTreeNode<T>> roots,
  Object id,
) {
  for (final node in roots) {
    if (node.id == id) return <CarpenterTreeNode<T>>[node];
    final nested = findCarpenterTreePath(node.children, id);
    if (nested != null) return <CarpenterTreeNode<T>>[node, ...nested];
  }
  return null;
}
