import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'drag_operation.dart';
import 'drag_payload.dart';
import 'drag_scope.dart';

@immutable
final class CarpenterDropDetails<T> {
  const CarpenterDropDetails({
    required this.payload,
    required this.operation,
    required this.position,
    required this.localOffset,
    this.targetId,
  });

  final CarpenterDragPayload<T> payload;
  final CarpenterDragOperation operation;
  final CarpenterDropPosition position;
  final Offset localOffset;
  final Object? targetId;
}

@immutable
final class CarpenterDropTargetState<T> {
  const CarpenterDropTargetState({
    required this.hovering,
    required this.accepts,
    this.payload,
    this.operation,
    this.position,
  });

  final bool hovering;
  final bool accepts;
  final CarpenterDragPayload<T>? payload;
  final CarpenterDragOperation? operation;
  final CarpenterDropPosition? position;
}

typedef CarpenterDropTargetBuilder<T> =
    Widget Function(BuildContext context, CarpenterDropTargetState<T> state);
typedef CarpenterDropAcceptance<T> = bool Function(CarpenterDropDetails<T> details);
typedef CarpenterDropCallback<T> = void Function(CarpenterDropDetails<T> details);

/// Typed drop target with operation negotiation and before/inside/after geometry.
final class CarpenterDropTarget<T> extends StatefulWidget {
  const CarpenterDropTarget({
    super.key,
    required this.builder,
    required this.onDrop,
    this.canAccept,
    this.targetId,
    this.axis = CarpenterDropAxis.vertical,
    this.fixedPosition,
    this.edgeFraction = .25,
    this.acceptedOperations = const {
      CarpenterDragOperation.move,
      CarpenterDragOperation.copy,
      CarpenterDragOperation.link,
    },
  }) : assert(edgeFraction >= 0 && edgeFraction < .5),
       assert(acceptedOperations.length > 0);

  final CarpenterDropTargetBuilder<T> builder;
  final CarpenterDropCallback<T> onDrop;
  final CarpenterDropAcceptance<T>? canAccept;
  final Object? targetId;
  final CarpenterDropAxis axis;
  final CarpenterDropPosition? fixedPosition;
  final double edgeFraction;
  final Set<CarpenterDragOperation> acceptedOperations;

  @override
  State<CarpenterDropTarget<T>> createState() => _CarpenterDropTargetWidgetState<T>();
}

final class _CarpenterDropTargetWidgetState<T>
    extends State<CarpenterDropTarget<T>> {
  final Object _fallbackTargetId = Object();
  CarpenterDragPayload<T>? _payload;
  CarpenterDragOperation? _operation;
  CarpenterDropPosition? _position;
  bool _hovering = false;
  bool _accepts = false;

  Object get _targetId => widget.targetId ?? _fallbackTargetId;

  CarpenterDragOperation? _resolveOperation(CarpenterDragPayload<T> payload) {
    final session = CarpenterDragScope.maybeOf(context)?.session;
    final sessionOperation = session?.operation;
    if (sessionOperation != null &&
        payload.supports(sessionOperation) &&
        widget.acceptedOperations.contains(sessionOperation)) {
      return sessionOperation;
    }
    for (final operation in CarpenterDragOperation.values) {
      if (payload.supports(operation) &&
          widget.acceptedOperations.contains(operation)) {
        return operation;
      }
    }
    return null;
  }

  Offset _localOffset(Offset globalOffset) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return Offset.zero;
    return renderObject.globalToLocal(globalOffset);
  }

  CarpenterDropPosition _resolvePosition(Offset localOffset) {
    final fixed = widget.fixedPosition;
    if (fixed != null) return fixed;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return CarpenterDropPosition.inside;
    }
    final size = renderObject.size;
    var ratio = switch (widget.axis) {
      CarpenterDropAxis.vertical => size.height == 0 ? .5 : localOffset.dy / size.height,
      CarpenterDropAxis.horizontal => size.width == 0 ? .5 : localOffset.dx / size.width,
    };
    if (widget.axis == CarpenterDropAxis.horizontal &&
        Directionality.of(context) == TextDirection.rtl) {
      ratio = 1 - ratio;
    }
    if (ratio < widget.edgeFraction) return CarpenterDropPosition.before;
    if (ratio > 1 - widget.edgeFraction) return CarpenterDropPosition.after;
    return CarpenterDropPosition.inside;
  }

  CarpenterDropDetails<T>? _buildDetails(
    CarpenterDragPayload<T> payload,
    Offset globalOffset,
  ) {
    final operation = _resolveOperation(payload);
    if (operation == null) return null;
    final localOffset = _localOffset(globalOffset);
    return CarpenterDropDetails<T>(
      payload: payload,
      operation: operation,
      position: _resolvePosition(localOffset),
      localOffset: localOffset,
      targetId: _targetId,
    );
  }

  bool _updateHover(CarpenterDropDetails<T>? details) {
    final accepts = details != null && (widget.canAccept?.call(details) ?? true);
    if (mounted) {
      setState(() {
        _hovering = true;
        _accepts = accepts;
        _payload = details?.payload;
        _operation = details?.operation;
        _position = details?.position;
      });
    }
    final controller = CarpenterDragScope.maybeOf(context);
    if (details != null) {
      controller?.hover(
        targetId: _targetId,
        position: details.position,
        accepted: accepts,
      );
    }
    return accepts;
  }

  void _clearHover() {
    if (_hovering && mounted) {
      setState(() {
        _hovering = false;
        _accepts = false;
        _payload = null;
        _operation = null;
        _position = null;
      });
    }
    CarpenterDragScope.maybeOf(context)?.leave(_targetId);
  }

  @override
  Widget build(BuildContext context) => DragTarget<CarpenterDragPayload<T>>(
    onWillAcceptWithDetails: (details) =>
        _updateHover(_buildDetails(details.data, details.offset)),
    onMove: (details) => _updateHover(
      _buildDetails(details.data, details.offset),
    ),
    onLeave: (_) => _clearHover(),
    onAcceptWithDetails: (details) {
      final drop = _buildDetails(details.data, details.offset);
      if (drop != null && (widget.canAccept?.call(drop) ?? true)) {
        widget.onDrop(drop);
      }
      _clearHover();
    },
    builder: (context, candidateData, rejectedData) => widget.builder(
      context,
      CarpenterDropTargetState<T>(
        hovering: _hovering,
        accepts: _accepts,
        payload: _payload,
        operation: _operation,
        position: _position,
      ),
    ),
  );
}
