import 'dart:async';

import 'package:bloc/bloc.dart';
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

/// Cubit backing a loading boundary.
///
/// Manual start/finish calls are idempotent per id. Tracked calls use internal
/// leases, so two overlapping `track(..., id: 'save')` calls are both counted
/// and the loading state survives until both complete.
final class LoadingCubit extends Cubit<LoadingState>
    implements LoadingController {
  LoadingCubit() : super(LoadingState.idle);

  final Object _manualLease = Object();
  final Map<Object, Set<Object>> _leasesById = <Object, Set<Object>>{};

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

  void _acquire(Object id, Object lease) {
    if (isClosed) return;
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
    if (isClosed) return;
    emit(LoadingState._from(_leasesById));
  }
}

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

/// Builds UI around a locally-owned [LoadingCubit].
typedef LoadingBoundaryBuilder = Widget Function(
  BuildContext context,
  LoadingState state,
  Widget child,
);

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
  late final LoadingCubit _cubit = LoadingCubit();
  late LoadingState _state = _cubit.state;
  StreamSubscription<LoadingState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _cubit.stream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoadingScope(
    controller: _cubit,
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
