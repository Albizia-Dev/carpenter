import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Semantic operation represented by Carpenter's internal structured clipboard.
enum CarpenterClipboardOperation { copy, cut }

/// Immutable structured clipboard payload.
///
/// Carpenter deliberately does not serialize arbitrary application objects into
/// the operating-system clipboard. Applications may mirror compatible values to
/// the system clipboard separately while this payload keeps typed data for
/// finder-like copy/cut/paste interactions inside the application.
@immutable
final class CarpenterClipboardContent<T> {
  const CarpenterClipboardContent({
    required this.items,
    required this.operation,
    this.sourceId,
  });

  final List<T> items;
  final CarpenterClipboardOperation operation;
  final Object? sourceId;

  bool get isCut => operation == CarpenterClipboardOperation.cut;
  bool get isCopy => operation == CarpenterClipboardOperation.copy;
}

/// Explicit owner for a typed application clipboard.
///
/// The controller is intentionally caller-ownable so a clipboard can survive
/// navigation between explorer locations without becoming hidden widget state.
final class CarpenterClipboardController<T>
    extends ValueNotifier<CarpenterClipboardContent<T>?> {
  CarpenterClipboardController() : super(null);

  bool get hasContent => value != null && value!.items.isNotEmpty;

  void copy(Iterable<T> items, {Object? sourceId}) => _write(
    items,
    operation: CarpenterClipboardOperation.copy,
    sourceId: sourceId,
  );

  void cut(Iterable<T> items, {Object? sourceId}) => _write(
    items,
    operation: CarpenterClipboardOperation.cut,
    sourceId: sourceId,
  );

  void _write(
    Iterable<T> items, {
    required CarpenterClipboardOperation operation,
    Object? sourceId,
  }) {
    final snapshot = List<T>.unmodifiable(items);
    value = snapshot.isEmpty
        ? null
        : CarpenterClipboardContent<T>(
            items: snapshot,
            operation: operation,
            sourceId: sourceId,
          );
  }

  void clear() => value = null;

  /// Returns whether [item] is currently represented as cut.
  ///
  /// Stable application keys keep the comparison independent from object
  /// identity and from refreshed collection instances.
  bool isCutItem<K>(T item, K Function(T item) keyOf) {
    final content = value;
    if (content == null || !content.isCut) return false;
    final key = keyOf(item);
    return content.items.any((candidate) => keyOf(candidate) == key);
  }

  /// Stable keys that should currently use cut presentation.
  Set<K> cutKeys<K>(K Function(T item) keyOf) {
    final content = value;
    if (content == null || !content.isCut) return <K>{};
    return Set<K>.unmodifiable(content.items.map(keyOf));
  }
}

/// Inherited typed clipboard boundary.
///
/// When [controller] is omitted the scope owns a local controller. Supplying a
/// controller keeps its lifecycle with the caller and allows the clipboard to
/// span several explorer views.
final class CarpenterClipboardScope<T> extends StatefulWidget {
  const CarpenterClipboardScope({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final CarpenterClipboardController<T>? controller;

  static CarpenterClipboardController<T> of<T>(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_CarpenterClipboardInherited<T>>();
    assert(binding != null, 'No CarpenterClipboardScope<$T> found in context.');
    return binding!.controller;
  }

  static CarpenterClipboardController<T>? maybeOf<T>(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CarpenterClipboardInherited<T>>()
          ?.controller;

  @override
  State<CarpenterClipboardScope<T>> createState() =>
      _CarpenterClipboardScopeState<T>();
}

final class _CarpenterClipboardScopeState<T>
    extends State<CarpenterClipboardScope<T>> {
  late CarpenterClipboardController<T> _controller =
      widget.controller ?? CarpenterClipboardController<T>();
  late bool _ownsController = widget.controller == null;

  @override
  void didUpdateWidget(CarpenterClipboardScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CarpenterClipboardController<T>();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _CarpenterClipboardInherited<T>(
    controller: _controller,
    child: widget.child,
  );
}

final class _CarpenterClipboardInherited<T>
    extends InheritedNotifier<CarpenterClipboardController<T>> {
  const _CarpenterClipboardInherited({
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final CarpenterClipboardController<T> controller;
}
