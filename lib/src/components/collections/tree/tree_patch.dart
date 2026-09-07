import 'tree_state.dart';

/// Pure presentation patch for a caller-owned Carpenter tree.
///
/// Patches never persist data and never own tree state. Applications apply
/// authoritative mutation results to their current roots and keep the result
/// in their own state layer.
sealed class CarpenterTreePatch<T> {
  const CarpenterTreePatch();
}

/// Replaces an already loaded node with the same stable [node] id.
///
/// Applying an update for an absent id is a no-op.
final class CarpenterTreeUpdated<T> extends CarpenterTreePatch<T> {
  const CarpenterTreeUpdated(this.node);

  final CarpenterTreeNode<T> node;
}

/// Inserts [node] under [parentId], or at the root when [parentId] is null.
///
/// Duplicate ids and missing parents are rejected as no-ops. [index] is
/// clamped to the destination list bounds; omitting it appends.
final class CarpenterTreeInserted<T> extends CarpenterTreePatch<T> {
  const CarpenterTreeInserted({
    required this.node,
    this.parentId,
    this.index,
  });

  final CarpenterTreeNode<T> node;
  final Object? parentId;
  final int? index;
}

/// Removes a loaded node and its loaded descendants from presentation data.
final class CarpenterTreeRemoved<T> extends CarpenterTreePatch<T> {
  const CarpenterTreeRemoved(this.id);

  final Object id;
}

/// Moves a loaded node under [parentId], or to the root when it is null.
///
/// The node object itself is preserved. Moving a node into itself or one of
/// its descendants, or targeting a missing parent, is rejected as a no-op.
final class CarpenterTreeMoved<T> extends CarpenterTreePatch<T> {
  const CarpenterTreeMoved({required this.id, this.parentId, this.index});

  final Object id;
  final Object? parentId;
  final int? index;
}

/// Pure application of tree patches with structural sharing.
extension CarpenterTreePatchApplication<T> on List<CarpenterTreeNode<T>> {
  /// Applies one presentation [patch].
  ///
  /// Unaffected branches retain their existing node identities. Invalid or
  /// stale patches return this list unchanged, which lets callers cheaply
  /// suppress unrelated rebuilds with ordinary state selectors.
  List<CarpenterTreeNode<T>> applyCarpenterTreePatch(
    CarpenterTreePatch<T> patch,
  ) {
    switch (patch) {
      case CarpenterTreeUpdated<T>():
        final result = _updateTreeNode(this, patch.node);
        return result.changed ? List.unmodifiable(result.nodes) : this;
      case CarpenterTreeInserted<T>():
        if (findCarpenterTreeNode(this, patch.node.id) != null) return this;
        final result = _insertTreeNode(
          this,
          patch.node,
          parentId: patch.parentId,
          index: patch.index,
        );
        return result.changed ? List.unmodifiable(result.nodes) : this;
      case CarpenterTreeRemoved<T>():
        final result = _removeTreeNode(this, patch.id);
        return result.changed ? List.unmodifiable(result.nodes) : this;
      case CarpenterTreeMoved<T>():
        final source = findCarpenterTreeNode(this, patch.id);
        if (source == null) return this;
        final parentId = patch.parentId;
        if (parentId != null) {
          if (parentId == source.id || carpenterTreeContains(source, parentId)) {
            return this;
          }
          if (findCarpenterTreeNode(this, parentId) == null) return this;
        }
        final removal = _removeTreeNode(this, patch.id);
        if (!removal.changed || removal.removed == null) return this;
        final insertion = _insertTreeNode(
          removal.nodes,
          removal.removed!,
          parentId: parentId,
          index: patch.index,
        );
        return insertion.changed ? List.unmodifiable(insertion.nodes) : this;
    }
  }

  /// Applies [patches] in order, returning the original roots when every patch
  /// is a no-op.
  List<CarpenterTreeNode<T>> applyCarpenterTreePatches(
    Iterable<CarpenterTreePatch<T>> patches,
  ) {
    List<CarpenterTreeNode<T>> current = this;
    for (final patch in patches) {
      current = current.applyCarpenterTreePatch(patch);
    }
    return current;
  }
}

final class _TreeRewrite<T> {
  const _TreeRewrite(this.nodes, {required this.changed, this.removed});

  final List<CarpenterTreeNode<T>> nodes;
  final bool changed;
  final CarpenterTreeNode<T>? removed;
}

_TreeRewrite<T> _updateTreeNode<T>(
  List<CarpenterTreeNode<T>> nodes,
  CarpenterTreeNode<T> replacement,
) {
  for (var index = 0; index < nodes.length; index++) {
    final node = nodes[index];
    if (node.id == replacement.id) {
      final next = [...nodes]..[index] = replacement;
      return _TreeRewrite(next, changed: true);
    }
    final children = _updateTreeNode(node.children, replacement);
    if (!children.changed) continue;
    final next = [...nodes]
      ..[index] = _treeNodeWithChildren(node, children.nodes);
    return _TreeRewrite(next, changed: true);
  }
  return _TreeRewrite(nodes, changed: false);
}

_TreeRewrite<T> _insertTreeNode<T>(
  List<CarpenterTreeNode<T>> nodes,
  CarpenterTreeNode<T> inserted, {
  required Object? parentId,
  required int? index,
}) {
  if (parentId == null) {
    final next = [...nodes];
    next.insert((index ?? next.length).clamp(0, next.length), inserted);
    return _TreeRewrite(next, changed: true);
  }

  for (var nodeIndex = 0; nodeIndex < nodes.length; nodeIndex++) {
    final node = nodes[nodeIndex];
    if (node.id == parentId) {
      final children = [...node.children];
      children.insert(
        (index ?? children.length).clamp(0, children.length),
        inserted,
      );
      final next = [...nodes]
        ..[nodeIndex] = _treeNodeWithChildren(node, children);
      return _TreeRewrite(next, changed: true);
    }
    final nested = _insertTreeNode(
      node.children,
      inserted,
      parentId: parentId,
      index: index,
    );
    if (!nested.changed) continue;
    final next = [...nodes]
      ..[nodeIndex] = _treeNodeWithChildren(node, nested.nodes);
    return _TreeRewrite(next, changed: true);
  }
  return _TreeRewrite(nodes, changed: false);
}

_TreeRewrite<T> _removeTreeNode<T>(
  List<CarpenterTreeNode<T>> nodes,
  Object id,
) {
  for (var index = 0; index < nodes.length; index++) {
    final node = nodes[index];
    if (node.id == id) {
      final next = [...nodes]..removeAt(index);
      return _TreeRewrite(next, changed: true, removed: node);
    }
    final nested = _removeTreeNode(node.children, id);
    if (!nested.changed) continue;
    final next = [...nodes]
      ..[index] = _treeNodeWithChildren(node, nested.nodes);
    return _TreeRewrite(next, changed: true, removed: nested.removed);
  }
  return _TreeRewrite(nodes, changed: false);
}

CarpenterTreeNode<T> _treeNodeWithChildren<T>(
  CarpenterTreeNode<T> node,
  List<CarpenterTreeNode<T>> children,
) => CarpenterTreeNode<T>(
  id: node.id,
  value: node.value,
  label: node.label,
  children: List.unmodifiable(children),
  hasChildren: children.isNotEmpty ? true : node.hasChildren,
  loadState: node.loadState,
  errorText: node.errorText,
  semanticLabel: node.semanticLabel,
);
