import 'package:flutter/widgets.dart';

import 'undo_controller.dart';

/// Inherited undo/redo boundary with optional caller-owned history.
final class CarpenterUndoScope extends StatefulWidget {
  /// Creates an undo scope around [child].
  const CarpenterUndoScope({super.key, required this.child, this.controller});

  /// Descendant subtree that can resolve the scoped history controller.
  final Widget child;

  /// Optional caller-owned history controller.
  final CarpenterUndoController? controller;

  /// Reads the nearest history controller and asserts that a scope exists.
  static CarpenterUndoController of(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_CarpenterUndoInherited>();
    assert(binding != null, 'No CarpenterUndoScope found in context.');
    return binding!.controller;
  }

  /// Reads the nearest history controller, or null outside an undo scope.
  static CarpenterUndoController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CarpenterUndoInherited>()
      ?.controller;

  /// Creates state that owns an implicit controller when one is not supplied.
  @override
  State<CarpenterUndoScope> createState() => _CarpenterUndoScopeState();
}

final class _CarpenterUndoScopeState extends State<CarpenterUndoScope> {
  late CarpenterUndoController _controller =
      widget.controller ?? CarpenterUndoController();
  late bool _ownsController = widget.controller == null;

  @override
  void didUpdateWidget(CarpenterUndoScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CarpenterUndoController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _CarpenterUndoInherited(controller: _controller, child: widget.child);
}

final class _CarpenterUndoInherited
    extends InheritedNotifier<CarpenterUndoController> {
  const _CarpenterUndoInherited({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final CarpenterUndoController controller;
}
