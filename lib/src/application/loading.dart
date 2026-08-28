import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Immutable snapshot of the operations currently owned by a loading scope.
@immutable
final class LoadingState {
  const LoadingState._(this.activeOperations);

  /// Empty loading state.
  static const idle = LoadingState._(<Object>{});

  /// Stable operation identifiers currently marked as active.
  final Set<Object> activeOperations;

  /// Whether at least one operation is active.
  bool get isLoading => activeOperations.isNotEmpty;

  /// Number of active operations.
  int get activeCount => activeOperations.length;

  /// Whether [id] is currently active.
  bool isActive(Object id) => activeOperations.contains(id);

  LoadingState _start(Object id) {
    if (activeOperations.contains(id)) return this;
    return LoadingState._(
      Set<Object>.unmodifiable(<Object>{...activeOperations, id}),
    );
  }

  LoadingState _finish(Object id) {
    if (!activeOperations.contains(id)) return this;
    return LoadingState._(
      Set<Object>.unmodifiable(activeOperations.where((item) => item != id)),
    );
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
  /// Errors are rethrown after the loading state is cleared.
  Future<T> track<T>(FutureOr<T> Function() operation, {Object? id});
}

/// Cubit backing a loading boundary.
///
/// Operations are represented by stable identifiers rather than a single bool,
/// so finishing one operation never hides loading while another is still active.
final class LoadingCubit extends Cubit<LoadingState>
    implements LoadingController {
  LoadingCubit() : super(LoadingState.idle);

  @override
  void start(Object id) {
    final next = state._start(id);
    if (identical(next, state)) return;
    emit(next);
  }

  @override
  void finish(Object id) {
    final next = state._finish(id);
    if (identical(next, state)) return;
    emit(next);
  }

  @override
  Future<T> track<T>(FutureOr<T> Function() operation, {Object? id}) async {
    final operationId = id ?? Object();
    start(operationId);
    try {
      return await Future<T>.sync(operation);
    } finally {
      finish(operationId);
    }
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
