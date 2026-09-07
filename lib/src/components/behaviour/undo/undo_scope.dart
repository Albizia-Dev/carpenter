import 'package:flutter/widgets.dart';

import 'undo_controller.dart';

/// Inherited undo/redo boundary with optional caller-owned history.
final class CarpenterUndoScope extends StatefulWidget {
  const CarpenterUndoScope({super.key, required this.child, this.controller});

  final Widget child;
  final CarpenterUndoController? controller;

  static CarpenterUndoController of(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_CarpenterUndoInherited>();
    assert(binding != null, 'No CarpenterUndoScope found in context.');
    return binding!.controller;
  }

  static CarpenterUndoController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_CarpenterUndoInherited>()
      ?.controller;

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
