import 'package:flutter/widgets.dart';

import 'drag_operation.dart';
import 'drag_payload.dart';
import 'drag_scope.dart';
import 'drag_transport.dart';

enum CarpenterDragActivation { immediate, longPress }

typedef CarpenterDragCanceledCallback =
    void Function(Velocity velocity, Offset offset);

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
  final GlobalKey _sourceGeometryKey = GlobalKey();

  Size? get _sourceSize {
    final renderObject = _sourceGeometryKey.currentContext?.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size
        : null;
  }

  Widget _defaultFeedback() => Builder(
    builder: (context) {
      final visual = Opacity(opacity: .82, child: widget.child);
      final size = _sourceSize;
      if (size == null) return visual;
      return SizedBox(width: size.width, height: size.height, child: visual);
    },
  );

  @override
  Widget build(BuildContext context) {
    assert(
      widget.payload.supports(widget.operation),
      'CarpenterDraggable operation must be allowed by its payload.',
    );
    final controller = CarpenterDragScope.maybeOf(context);
    final dragFeedback = widget.feedback ?? _defaultFeedback();
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

    final sourceChild = KeyedSubtree(
      key: _sourceGeometryKey,
      child: widget.child,
    );
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
