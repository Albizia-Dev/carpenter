import 'package:flutter/widgets.dart';

import 'drag_operation.dart';
import 'drag_payload.dart';
import 'drag_scope.dart';
import 'drag_transport.dart';

enum CarpenterDragActivation { immediate, longPress }

typedef CarpenterDragCanceledCallback =
    void Function(Velocity velocity, Offset offset);

final class _CarpenterSizedDragFeedback extends StatelessWidget {
  const _CarpenterSizedDragFeedback({
    required this.sourceKey,
    required this.child,
  });

  final GlobalKey sourceKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final renderObject = sourceKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return child;
    return SizedBox.fromSize(size: renderObject.size, child: child);
  }
}

/// Typed pointer drag source backed by Flutter's drag recognizers and Carpenter sessions.
final class CarpenterDraggable<T> extends StatefulWidget {
  const CarpenterDraggable({
    super.key,
    required this.payload,
    required this.child,
    this.feedback,
    this.childWhenDragging,
    this.sourceId,
    this.operation = CarpenterDragOperation.move,
    this.activation = CarpenterDragActivation.immediate,
    this.axis,
    this.maxSimultaneousDrags = 1,
    this.semanticLabel,
    this.onDragStarted,
    this.onDragCompleted,
    this.onDragCanceled,
  });

  final CarpenterDragPayload<T> payload;
  final Widget child;
  final Widget? feedback;
  final Widget? childWhenDragging;
  final Object? sourceId;
  final CarpenterDragOperation operation;
  final CarpenterDragActivation activation;
  final Axis? axis;
  final int? maxSimultaneousDrags;
  final String? semanticLabel;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;
  final CarpenterDragCanceledCallback? onDragCanceled;

  @override
  State<CarpenterDraggable<T>> createState() => _CarpenterDraggableState<T>();
}

final class _CarpenterDraggableState<T> extends State<CarpenterDraggable<T>> {
  final GlobalKey _sourceKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    assert(
      widget.payload.supports(widget.operation),
      'CarpenterDraggable operation must be allowed by its payload.',
    );
    final controller = CarpenterDragScope.maybeOf(context);
    final sourceChild = KeyedSubtree(key: _sourceKey, child: widget.child);
    final dragFeedback =
        widget.feedback ??
        _CarpenterSizedDragFeedback(
          sourceKey: _sourceKey,
          child: Opacity(opacity: .82, child: widget.child),
        );
    final transport = CarpenterDragTransport<T>(widget.payload);

    Offset anchorStrategy(
      Draggable<Object> draggable,
      BuildContext dragContext,
      Offset position,
    ) {
      final anchor = childDragAnchorStrategy(draggable, dragContext, position);
      transport.dragStartPoint = anchor;
      return anchor;
    }

    void started() {
      controller?.begin(
        payload: widget.payload,
        operation: widget.operation,
        sourceId: widget.sourceId,
      );
      widget.onDragStarted?.call();
    }

    void completed() {
      controller?.complete();
      widget.onDragCompleted?.call();
    }

    void canceled(Velocity velocity, Offset offset) {
      controller?.cancel();
      widget.onDragCanceled?.call(velocity, offset);
    }

    void ended(DraggableDetails details) {
      if (!details.wasAccepted) controller?.cancel();
    }

    final draggable = switch (widget.activation) {
      CarpenterDragActivation.immediate => Draggable<CarpenterDragTransport<T>>(
        data: transport,
        feedback: dragFeedback,
        childWhenDragging: widget.childWhenDragging,
        dragAnchorStrategy: anchorStrategy,
        axis: widget.axis,
        maxSimultaneousDrags: widget.maxSimultaneousDrags,
        onDragStarted: started,
        onDragCompleted: completed,
        onDraggableCanceled: canceled,
        onDragEnd: ended,
        child: sourceChild,
      ),
      CarpenterDragActivation.longPress =>
        LongPressDraggable<CarpenterDragTransport<T>>(
          data: transport,
          feedback: dragFeedback,
          childWhenDragging: widget.childWhenDragging,
          dragAnchorStrategy: anchorStrategy,
          axis: widget.axis,
          maxSimultaneousDrags: widget.maxSimultaneousDrags,
          onDragStarted: started,
          onDragCompleted: completed,
          onDraggableCanceled: canceled,
          onDragEnd: ended,
          child: sourceChild,
        ),
    };

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: draggable,
    );
  }
}
