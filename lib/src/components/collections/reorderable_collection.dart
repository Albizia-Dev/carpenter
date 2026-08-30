import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../behaviour/drag_and_drop/drag_operation.dart';
import '../behaviour/drag_and_drop/drag_payload.dart';
import '../behaviour/drag_and_drop/drag_scope.dart';
import '../behaviour/drag_and_drop/draggable.dart';
import '../behaviour/drag_and_drop/drop_target.dart';

@immutable
final class CarpenterReorderDetails<T> {
  const CarpenterReorderDetails({
    required this.item,
    required this.oldIndex,
    required this.targetIndex,
    required this.newIndex,
    required this.position,
  });

  final T item;
  final int oldIndex;
  final int targetIndex;
  final int newIndex;
  final CarpenterDropPosition position;
}

@immutable
final class CarpenterReorderItemState {
  const CarpenterReorderItemState({
    required this.index,
    required this.dragging,
    required this.hovering,
    required this.accepts,
    this.dropPosition,
  });

  final int index;
  final bool dragging;
  final bool hovering;
  final bool accepts;
  final CarpenterDropPosition? dropPosition;
}

typedef CarpenterReorderItemBuilder<T> =
    Widget Function(BuildContext context, T item, CarpenterReorderItemState state);
typedef CarpenterReorderCallback<T> =
    void Function(CarpenterReorderDetails<T> details);

@immutable
final class _ReorderDragData<T> {
  const _ReorderDragData({
    required this.collectionId,
    required this.item,
    required this.index,
  });

  final Object collectionId;
  final T item;
  final int index;
}

/// Presentation-neutral controlled reorderable collection built on Carpenter DnD.
final class CarpenterReorderableCollection<T> extends StatefulWidget {
  const CarpenterReorderableCollection({
    super.key,
    required this.items,
    required this.itemKey,
    required this.itemBuilder,
    this.onReorder,
    this.axis = Axis.vertical,
    this.activation = CarpenterDragActivation.immediate,
    this.semanticLabel = 'Reorderable collection',
  });

  final List<T> items;
  final Object Function(T item) itemKey;
  final CarpenterReorderItemBuilder<T> itemBuilder;
  final CarpenterReorderCallback<T>? onReorder;
  final Axis axis;
  final CarpenterDragActivation activation;
  final String semanticLabel;

  @override
  State<CarpenterReorderableCollection<T>> createState() =>
      _CarpenterReorderableCollectionState<T>();
}

final class _CarpenterReorderableCollectionState<T>
    extends State<CarpenterReorderableCollection<T>> {
  final Object _collectionId = Object();
  Object? _draggingKey;

  CarpenterDropAxis get _dropAxis => widget.axis == Axis.vertical
      ? CarpenterDropAxis.vertical
      : CarpenterDropAxis.horizontal;

  CarpenterDropPosition _effectivePosition(
    CarpenterDropDetails<_ReorderDragData<T>> details,
  ) {
    if (details.position != CarpenterDropPosition.inside) {
      return details.position;
    }
    final size = details.targetSize;
    if (widget.axis == Axis.vertical) {
      if (size.height == 0) return CarpenterDropPosition.after;
      return details.localOffset.dy < size.height / 2
          ? CarpenterDropPosition.before
          : CarpenterDropPosition.after;
    }
    if (size.width == 0) return CarpenterDropPosition.after;
    var before = details.localOffset.dx < size.width / 2;
    if (Directionality.of(context) == TextDirection.rtl) before = !before;
    return before ? CarpenterDropPosition.before : CarpenterDropPosition.after;
  }

  void _drop(
    int targetIndex,
    CarpenterDropDetails<_ReorderDragData<T>> details,
  ) {
    final callback = widget.onReorder;
    if (callback == null) return;
    final source = details.payload.data;
    final position = _effectivePosition(details);
    var insertion = targetIndex +
        (position == CarpenterDropPosition.after ? 1 : 0);
    if (source.index < insertion) insertion -= 1;
    final maxIndex = widget.items.isEmpty ? 0 : widget.items.length - 1;
    final newIndex = insertion.clamp(0, maxIndex);
    if (newIndex == source.index) return;
    callback(
      CarpenterReorderDetails<T>(
        item: source.item,
        oldIndex: source.index,
        targetIndex: targetIndex,
        newIndex: newIndex,
        position: position,
      ),
    );
  }

  Widget _item(BuildContext context, T item, int index) {
    final key = widget.itemKey(item);
    final enabled = widget.onReorder != null;
    Widget buildItem(CarpenterDropTargetState<_ReorderDragData<T>> targetState) {
      final normal = widget.itemBuilder(
        context,
        item,
        CarpenterReorderItemState(
          index: index,
          dragging: _draggingKey == key,
          hovering: targetState.hovering,
          accepts: targetState.accepts,
          dropPosition: targetState.position,
        ),
      );
      if (!enabled) return normal;
      return CarpenterDraggable<_ReorderDragData<T>>(
        sourceId: key,
        operation: CarpenterDragOperation.move,
        activation: widget.activation,
        axis: widget.axis,
        payload: CarpenterDragPayload<_ReorderDragData<T>>(
          id: key,
          data: _ReorderDragData<T>(
            collectionId: _collectionId,
            item: item,
            index: index,
          ),
        ),
        semanticLabel: 'Move item ${index + 1}',
        onDragStarted: () => setState(() => _draggingKey = key),
        onDragCompleted: () {
          if (mounted) setState(() => _draggingKey = null);
        },
        onDragCanceled: (_, __) {
          if (mounted) setState(() => _draggingKey = null);
        },
        child: normal,
      );
    }

    if (!enabled) {
      return KeyedSubtree(
        key: ValueKey<Object>(key),
        child: buildItem(
          const CarpenterDropTargetState<_ReorderDragData<T>>(
            hovering: false,
            accepts: false,
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: ValueKey<Object>(key),
      child: CarpenterDropTarget<_ReorderDragData<T>>(
        targetId: key,
        axis: _dropAxis,
        edgeFraction: .35,
        acceptedOperations: const {CarpenterDragOperation.move},
        canAccept: (details) =>
            details.payload.data.collectionId == _collectionId &&
            details.payload.data.index != index,
        onDrop: (details) => _drop(index, details),
        builder: (context, targetState) => buildItem(targetState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      for (var index = 0; index < widget.items.length; index++)
        _item(context, widget.items[index], index),
    ];
    final content = widget.axis == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: CarpenterDragScope(child: content),
    );
  }
}
