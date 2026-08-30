import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'drag_operation.dart';
import 'drag_payload.dart';

@immutable
final class CarpenterDragSession {
  const CarpenterDragSession({
    required this.payload,
    required this.operation,
    this.sourceId,
    this.targetId,
    this.dropPosition,
    this.targetAccepts = false,
  });

  final CarpenterDragPayload<Object?> payload;
  final CarpenterDragOperation operation;
  final Object? sourceId;
  final Object? targetId;
  final CarpenterDropPosition? dropPosition;
  final bool targetAccepts;

  CarpenterDragSession copyWith({
    Object? targetId,
    CarpenterDropPosition? dropPosition,
    bool? targetAccepts,
    bool clearTarget = false,
  }) => CarpenterDragSession(
    payload: payload,
    operation: operation,
    sourceId: sourceId,
    targetId: clearTarget ? null : targetId ?? this.targetId,
    dropPosition: clearTarget ? null : dropPosition ?? this.dropPosition,
    targetAccepts: clearTarget ? false : targetAccepts ?? this.targetAccepts,
  );
}

final class CarpenterDragController extends ChangeNotifier {
  CarpenterDragSession? _session;

  CarpenterDragSession? get session => _session;
  bool get isDragging => _session != null;

  void begin<T>({
    required CarpenterDragPayload<T> payload,
    required CarpenterDragOperation operation,
    Object? sourceId,
  }) {
    if (!payload.supports(operation)) {
      throw ArgumentError.value(
        operation,
        'operation',
        'The drag payload does not allow this operation.',
      );
    }
    _session = CarpenterDragSession(
      payload: payload,
      operation: operation,
      sourceId: sourceId,
    );
    notifyListeners();
  }

  void hover({
    required Object? targetId,
    required CarpenterDropPosition position,
    required bool accepted,
  }) {
    final current = _session;
    if (current == null) return;
    final next = current.copyWith(
      targetId: targetId,
      dropPosition: position,
      targetAccepts: accepted,
    );
    if (_sameTargetState(current, next)) return;
    _session = next;
    notifyListeners();
  }

  void leave(Object? targetId) {
    final current = _session;
    if (current == null || current.targetId != targetId) return;
    _session = current.copyWith(clearTarget: true);
    notifyListeners();
  }

  void complete() {
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }

  void cancel() => complete();

  bool _sameTargetState(
    CarpenterDragSession first,
    CarpenterDragSession second,
  ) =>
      first.targetId == second.targetId &&
      first.dropPosition == second.dropPosition &&
      first.targetAccepts == second.targetAccepts;
}

typedef CarpenterDragSessionCallback =
    void Function(CarpenterDragSession? session);

/// Shared drag-and-drop runtime for coordinated sources and targets.
final class CarpenterDragScope extends StatefulWidget {
  const CarpenterDragScope({
    super.key,
    required this.child,
    this.controller,
    this.onSessionChanged,
  });

  final Widget child;
  final CarpenterDragController? controller;
  final CarpenterDragSessionCallback? onSessionChanged;

  static CarpenterDragController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_CarpenterDragScopeInherited>();
    assert(scope != null, 'No CarpenterDragScope found in context.');
    return scope!.controller;
  }

  static CarpenterDragController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CarpenterDragScopeInherited>()
      ?.controller;

  @override
  State<CarpenterDragScope> createState() => _CarpenterDragScopeState();
}

final class _CarpenterDragScopeState extends State<CarpenterDragScope> {
  late CarpenterDragController _controller =
      widget.controller ?? CarpenterDragController();
  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CarpenterDragScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    _controller.removeListener(_handleChange);
    if (oldWidget.controller == null) _controller.dispose();
    _controller = widget.controller ?? CarpenterDragController();
    _controller.addListener(_handleChange);
  }

  void _handleChange() => widget.onSessionChanged?.call(_controller.session);

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _CarpenterDragScopeInherited(
    controller: _controller,
    child: widget.child,
  );
}

final class _CarpenterDragScopeInherited
    extends InheritedNotifier<CarpenterDragController> {
  const _CarpenterDragScopeInherited({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final CarpenterDragController controller;
}
