import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Semantic operation represented by Carpenter's internal structured clipboard.
enum CarpenterClipboardOperation {
  /// Paste should duplicate the referenced items.
  copy,

  /// Paste should move the referenced items and then clear the cut state.
  cut,
}

/// Immutable structured clipboard payload.
///
/// Carpenter deliberately does not serialize arbitrary application objects into
/// the operating-system clipboard. Applications may mirror compatible values to
/// the system clipboard separately while this payload keeps typed data for
/// finder-like copy/cut/paste interactions inside the application.
@immutable
final class CarpenterClipboardContent<T> {
  /// Creates a typed clipboard snapshot for [items] and [operation].
  const CarpenterClipboardContent({
    required this.items,
    required this.operation,
    this.sourceId,
  });

  /// Immutable application items captured when copy or cut was invoked.
  final List<T> items;

  /// Paste semantics requested for [items].
  final CarpenterClipboardOperation operation;

  /// Optional caller-owned identity of the source location.
  final Object? sourceId;

  /// Whether this payload represents a pending cut operation.
  bool get isCut => operation == CarpenterClipboardOperation.cut;

  /// Whether this payload represents a copy operation.
  bool get isCopy => operation == CarpenterClipboardOperation.copy;
}

/// Explicit owner for a typed application clipboard.
///
/// The controller is intentionally caller-ownable so a clipboard can survive
/// navigation between explorer locations without becoming hidden widget state.
final class CarpenterClipboardController<T>
    extends ValueNotifier<CarpenterClipboardContent<T>?> {
  /// Creates an empty typed clipboard.
  CarpenterClipboardController() : super(null);

  /// Whether the clipboard currently contains at least one item.
  bool get hasContent => value != null && value!.items.isNotEmpty;

  /// Replaces the clipboard with a copy snapshot of [items].
  void copy(Iterable<T> items, {Object? sourceId}) => _write(
    items,
    operation: CarpenterClipboardOperation.copy,
    sourceId: sourceId,
  );

  /// Replaces the clipboard with a cut snapshot of [items].
  ///
  /// Calling this method does not mutate application data. The move happens
  /// only when application paste succeeds.
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

  /// Clears copy/cut content and any cut presentation state.
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
  /// Creates a clipboard boundary around [child].
  const CarpenterClipboardScope({
    super.key,
    required this.child,
    this.controller,
  });

  /// Descendant subtree that can read the scoped clipboard.
  final Widget child;

  /// Optional caller-owned clipboard controller.
  final CarpenterClipboardController<T>? controller;

  /// Reads the nearest typed clipboard and asserts that a scope exists.
  static CarpenterClipboardController<T> of<T>(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_CarpenterClipboardInherited<T>>();
    assert(binding != null, 'No CarpenterClipboardScope<$T> found in context.');
    return binding!.controller;
  }

  /// Reads the nearest typed clipboard, or returns null outside a scope.
  static CarpenterClipboardController<T>? maybeOf<T>(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CarpenterClipboardInherited<T>>()
          ?.controller;

  /// Creates the state that owns an implicit controller when necessary.
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
