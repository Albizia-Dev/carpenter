import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Immutable snapshot of the operations currently owned by a loading scope.
@immutable
final class LoadingState {
  const LoadingState._(this.operationCounts, this.activeCount);

  /// Empty loading state.
  static const idle = LoadingState._(<Object, int>{}, 0);

  /// Number of active executions grouped by stable operation identifier.
  final Map<Object, int> operationCounts;

  /// Total number of active executions, including repeated ids tracked in
  /// parallel.
  final int activeCount;

  /// Stable operation identifiers currently marked as active.
  Set<Object> get activeOperations =>
      Set<Object>.unmodifiable(operationCounts.keys);

  /// Whether at least one operation is active.
  bool get isLoading => activeCount > 0;

  /// Whether [id] is currently active.
  bool isActive(Object id) => operationCounts.containsKey(id);

  /// Number of active executions currently grouped under [id].
  int countFor(Object id) => operationCounts[id] ?? 0;

  factory LoadingState._from(Map<Object, Set<Object>> leasesById) {
    if (leasesById.isEmpty) return idle;
    final counts = <Object, int>{
      for (final MapEntry(key: id, value: leases) in leasesById.entries)
        id: leases.length,
    };
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return LoadingState._(Map<Object, int>.unmodifiable(counts), total);
  }
}

/// UI-agnostic handle exposed to descendants through [BuildContext.loading].
abstract interface class LoadingController {
  /// Current state of this loading scope.
  LoadingState get state;

  /// Marks [id] as active. Calling this repeatedly for the same id is a no-op.
  void start(Object id);

  /// Marks [id] as finished. Calling this repeatedly for the same id is a no-op.
  void finish(Object id);

  /// Runs [operation] while this scope owns an active operation.
  ///
  /// If [id] is omitted, a unique identity is created for this invocation.
  /// Multiple concurrent tracked operations may share one id; each gets its own
  /// internal lease, so the id remains active until the last invocation ends.
  /// Errors are rethrown after the loading state is cleared.
  Future<T> track<T>(FutureOr<T> Function() operation, {Object? id});
}

/// Framework-neutral loading state owner.
///
/// Manual start/finish calls are idempotent per id. Tracked calls use internal
/// leases, so two overlapping `track(..., id: 'save')` calls are both counted
/// and the loading state survives until both complete.
///
/// [stream] and [close] are retained as lightweight compatibility affordances
/// for older code that consumed [LoadingCubit] directly. Carpenter itself uses
/// the notifier contract and does not depend on Bloc or another state manager.
class LoadingNotifier extends ValueNotifier<LoadingState>
    implements LoadingController {
  LoadingNotifier() : super(LoadingState.idle);

  final Object _manualLease = Object();
  final Map<Object, Set<Object>> _leasesById = <Object, Set<Object>>{};
  final StreamController<LoadingState> _streamController =
      StreamController<LoadingState>.broadcast(sync: true);
  bool _closed = false;

  @override
  LoadingState get state => value;

  /// Compatibility stream for callers that previously listened to a Cubit.
  Stream<LoadingState> get stream => _streamController.stream;

  bool get isClosed => _closed;

  @override
  void start(Object id) => _acquire(id, _manualLease);

  @override
  void finish(Object id) => _release(id, _manualLease);

  @override
  Future<T> track<T>(FutureOr<T> Function() operation, {Object? id}) async {
    final lease = Object();
    final operationId = id ?? Object();
    _acquire(operationId, lease);
    try {
      return await Future<T>.sync(operation);
    } finally {
      _release(operationId, lease);
    }
  }

  /// Closes compatibility streams and notifier listeners.
  Future<void> close() {
    if (_closed) return Future<void>.value();
    _closed = true;
    super.dispose();
    return _streamController.close();
  }

  void _acquire(Object id, Object lease) {
    if (_closed) return;
    final leases = _leasesById.putIfAbsent(id, () => <Object>{});
    if (!leases.add(lease)) return;
    _emitSnapshot();
  }

  void _release(Object id, Object lease) {
    final leases = _leasesById[id];
    if (leases == null || !leases.remove(lease)) return;
    if (leases.isEmpty) _leasesById.remove(id);
    _emitSnapshot();
  }

  void _emitSnapshot() {
    if (_closed) return;
    value = LoadingState._from(_leasesById);
    _streamController.add(value);
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    super.dispose();
    unawaited(_streamController.close());
  }
}

/// Compatibility name for code written against Carpenter's former Bloc-backed
/// loading implementation.
@Deprecated('Use LoadingNotifier. Carpenter no longer depends on Bloc.')
final class LoadingCubit extends LoadingNotifier {}

/// Dependency-injection boundary for loading state.
///
/// Descendants resolve only the nearest scope. A nested scope therefore cuts off
/// access to any outer loading controller without using Flutter Notifications.
final class LoadingScope extends InheritedWidget {
  const LoadingScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final LoadingController controller;

  static LoadingController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LoadingScope>()?.controller;

  @override
  bool updateShouldNotify(LoadingScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Builds UI around a locally-owned [LoadingNotifier].
typedef LoadingBoundaryBuilder =
    Widget Function(BuildContext context, LoadingState state, Widget child);

/// Owns a loading scope and lets its parent choose the loading presentation.
///
/// The child only talks to [BuildContext.loading]. It does not know whether the
/// boundary renders a top progress bar, overlay, skeleton, blocked region, or
/// nothing at all.
final class LoadingBoundary extends StatefulWidget {
  const LoadingBoundary({
    super.key,
    required this.builder,
    required this.child,
  });

  final LoadingBoundaryBuilder builder;
  final Widget child;

  @override
  State<LoadingBoundary> createState() => _LoadingBoundaryState();
}

final class _LoadingBoundaryState extends State<LoadingBoundary> {
  late final LoadingNotifier _controller = LoadingNotifier();
  late LoadingState _state = _controller.state;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChanged);
  }

  void _handleStateChanged() {
    if (!mounted) return;
    setState(() => _state = _controller.state);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChanged);
    unawaited(_controller.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoadingScope(
    controller: _controller,
    child: Builder(
      builder: (context) => widget.builder(context, _state, widget.child),
    ),
  );
}

extension LoadingBuildContext on BuildContext {
  /// Nearest loading scope, or a no-op controller when none exists.
  LoadingController get loading => LoadingScope.maybeOf(this) ?? _noLoading;
}

const _NoLoadingController _noLoading = _NoLoadingController();

final class _NoLoadingController implements LoadingController {
  const _NoLoadingController();

  @override
  LoadingState get state => LoadingState.idle;

  @override
  void start(Object id) {}

  @override
  void finish(Object id) {}

  @override
  Future<T> track<T>(FutureOr<T> Function() operation, {Object? id}) =>
      Future<T>.sync(operation);
}
