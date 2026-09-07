import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'drag_operation.dart';
import 'drag_payload.dart';

@immutable
final class CarpenterDragSession {
  /// Creates one immutable snapshot of an in-progress drag session.
  const CarpenterDragSession({
    required this.payload,
    required this.operation,
    required this.preferredOperation,
    this.sourceId,
    this.targetId,
    this.dropPosition,
    this.targetAccepts = false,
  });

  final CarpenterDragPayload<Object?> payload;
  final CarpenterDragOperation operation;

  /// Source-preferred operation used when modifiers stop requesting another one.
  final CarpenterDragOperation preferredOperation;

  final Object? sourceId;
  final Object? targetId;
  final CarpenterDropPosition? dropPosition;
  final bool targetAccepts;

  /// Copies this session while optionally changing operation or target state.
  CarpenterDragSession copyWith({
    CarpenterDragOperation? operation,
    Object? targetId,
    CarpenterDropPosition? dropPosition,
    bool? targetAccepts,
    bool clearTarget = false,
  }) => CarpenterDragSession(
    payload: payload,
    operation: operation ?? this.operation,
    preferredOperation: preferredOperation,
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

  /// Starts a drag session after validating that [operation] is allowed.
  void begin<T>({
    required CarpenterDragPayload<T> payload,
    required CarpenterDragOperation operation,
    CarpenterDragOperation? preferredOperation,
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
      preferredOperation: preferredOperation ?? operation,
      sourceId: sourceId,
    );
    notifyListeners();
  }

  /// Changes the operation of the active session when the payload supports it.
  void setOperation(CarpenterDragOperation operation) {
    final current = _session;
    if (current == null || current.operation == operation) return;
    if (!current.payload.supports(operation)) return;
    _session = current.copyWith(operation: operation);
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
      first.targetAccepts == second.targetAccepts &&
      first.operation == second.operation;
}

typedef CarpenterDragSessionCallback =
    void Function(CarpenterDragSession? session);

/// Shared drag-and-drop runtime for coordinated sources and targets.
///
/// The scope also keeps the current operation synchronized with desktop
/// modifier keys while a drag is in progress, so a user can change move/copy/
/// link intent without restarting the gesture.
final class CarpenterDragScope extends StatefulWidget {
  /// Creates a drag runtime boundary around [child].
  const CarpenterDragScope({
    super.key,
    required this.child,
    this.controller,
    this.onSessionChanged,
    this.platform,
    this.operationPolicy = const CarpenterDragOperationPolicy.standard(),
    this.trackOperationModifiers = true,
  });

  final Widget child;
  final CarpenterDragController? controller;
  final CarpenterDragSessionCallback? onSessionChanged;

  /// Optional platform override, primarily for deterministic policy testing.
  final TargetPlatform? platform;

  /// Policy that maps pressed modifier keys to move, copy, or link.
  final CarpenterDragOperationPolicy operationPolicy;

  /// Whether hardware modifier changes may change the active drag operation.
  final bool trackOperationModifiers;

  static _CarpenterDragScopeInherited? _binding(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CarpenterDragScopeInherited>();

  static CarpenterDragController of(BuildContext context) {
    final scope = _binding(context);
    assert(scope != null, 'No CarpenterDragScope found in context.');
    return scope!.controller;
  }

  static CarpenterDragController? maybeOf(BuildContext context) =>
      _binding(context)?.controller;

  /// Resolves the operation a new [payload] should use in the nearest scope.
  static CarpenterDragOperation resolveOperationOf<T>(
    BuildContext context,
    CarpenterDragPayload<T> payload, {
    CarpenterDragOperation preferred = CarpenterDragOperation.move,
  }) {
    final binding = _binding(context);
    final policy =
        binding?.operationPolicy ??
        const CarpenterDragOperationPolicy.standard();
    final platform = binding?.platform ?? defaultTargetPlatform;
    return policy.resolve(
      platform: platform,
      pressedKeys: HardwareKeyboard.instance.logicalKeysPressed,
      allowedOperations: payload.allowedOperations,
      preferred: preferred,
    );
  }

  /// Creates the state that coordinates controller and hardware-key lifecycles.
  @override
  State<CarpenterDragScope> createState() => _CarpenterDragScopeState();
}

final class _CarpenterDragScopeState extends State<CarpenterDragScope> {
  late CarpenterDragController _controller =
      widget.controller ?? CarpenterDragController();
  bool get _ownsController => widget.controller == null;
  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChange);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(CarpenterDragScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleChange);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? CarpenterDragController();
      _controller.addListener(_handleChange);
    }
    _syncOperation();
  }

  void _handleChange() => widget.onSessionChanged?.call(_controller.session);

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.trackOperationModifiers || !_controller.isDragging) {
      return false;
    }
    _syncOperation();
    return false;
  }

  void _syncOperation() {
    final session = _controller.session;
    if (session == null || !widget.trackOperationModifiers) return;
    final resolved = widget.operationPolicy.resolve(
      platform: _platform,
      pressedKeys: HardwareKeyboard.instance.logicalKeysPressed,
      allowedOperations: session.payload.allowedOperations,
      preferred: session.preferredOperation,
    );
    _controller.setOperation(resolved);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _controller.removeListener(_handleChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _CarpenterDragScopeInherited(
    controller: _controller,
    operationPolicy: widget.operationPolicy,
    platform: _platform,
    child: widget.child,
  );
}

final class _CarpenterDragScopeInherited
    extends InheritedNotifier<CarpenterDragController> {
  const _CarpenterDragScopeInherited({
    required this.controller,
    required this.operationPolicy,
    required this.platform,
    required super.child,
  }) : super(notifier: controller);

  final CarpenterDragController controller;
  final CarpenterDragOperationPolicy operationPolicy;
  final TargetPlatform platform;

  @override
  bool updateShouldNotify(_CarpenterDragScopeInherited oldWidget) =>
      operationPolicy != oldWidget.operationPolicy ||
      platform != oldWidget.platform ||
      super.updateShouldNotify(oldWidget);
}
