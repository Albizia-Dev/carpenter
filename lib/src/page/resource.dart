import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../components/behaviour/request_gate.dart';
import 'controller.dart';
import 'state.dart';

enum CarpenterResourceLoadReason { initial, refresh }

/// Resource-specific compatibility type over Carpenter's shared cancellation
/// signal.
final class CarpenterResourceCancellation extends CarpenterCancellationSignal {}

final class CarpenterResourceLoadRequest {
  const CarpenterResourceLoadRequest({
    required this.reason,
    required this.cancellation,
  });
  final CarpenterResourceLoadReason reason;
  final CarpenterResourceCancellation cancellation;
  bool get refresh => reason == CarpenterResourceLoadReason.refresh;
}

final class CarpenterResourceFailure {
  const CarpenterResourceFailure({
    required this.error,
    required this.stackTrace,
    this.message,
  });

  final Object error;
  final StackTrace stackTrace;
  final String? message;
}

typedef CarpenterResourceLoader<T> =
    Future<T> Function(CarpenterResourceLoadRequest request);

/// Extensible resource lifecycle base for application-specific controllers.
class CarpenterResourceController<T> extends ValueNotifier<CarpenterPageState>
    implements CarpenterPageController {
  CarpenterResourceController({
    required CarpenterResourceLoader<T> load,
    this.errorMessage,
  }) : _load = load,
       super(const CarpenterPageInitialLoading()) {
    refreshCommand = CarpenterCommandController<void>(
      id: 'resource.refresh',
      title: 'Refresh',
      presentation: CarpenterCommandPresentation.secondary,
      execute: (_) async {
        await refresh();
        return const CarpenterCommandResult();
      },
    );
    retryCommand = CarpenterCommandController<void>(
      id: 'resource.retry',
      title: 'Retry',
      execute: (_) async {
        await refresh();
        return const CarpenterCommandResult();
      },
    );
  }

  final CarpenterResourceLoader<T> _load;
  final String Function(Object error)? errorMessage;
  final CarpenterRequestGate<CarpenterResourceCancellation> _requests =
      CarpenterRequestGate<CarpenterResourceCancellation>(
        createCancellation: CarpenterResourceCancellation.new,
      );
  T? _data;
  CarpenterResourceFailure? _refreshFailure;
  late final CarpenterCommandController<void> refreshCommand;
  late final CarpenterCommandController<void> retryCommand;

  T? get data => _data;
  bool get hasData => _data != null;
  CarpenterResourceFailure? get refreshFailure => _refreshFailure;
  bool get hasRefreshFailure => _refreshFailure != null;

  /// Replaces the currently loaded resource without starting a new request.
  ///
  /// Use this for optimistic updates or for applying a mutation response to the
  /// resource already on screen. The current page state is preserved and
  /// listeners are notified exactly once.
  void replaceData(T next) => _setData(next, notify: true);

  /// Replaces the currently loaded resource using its latest value.
  ///
  /// Throws when no resource has been loaded yet. This keeps local mutations
  /// explicit instead of silently dropping an update during initial loading.
  void updateData(T Function(T current) update) {
    final current = _data;
    if (current == null) {
      throw StateError('Cannot update resource data before it has loaded.');
    }
    replaceData(update(current));
  }

  /// Called after resource data changes from load, refresh, replace, or update.
  ///
  /// Application controllers can override this to recompute derived state or
  /// command availability in one place. The new [data] value is already
  /// installed when this hook runs. Do not call [notifyListeners] here;
  /// Carpenter completes the owning lifecycle notification after the hook.
  @protected
  void didChangeData(T? previous, T next) {}

  @override
  List<CarpenterCommand<dynamic>> get pageCommands => [
    refreshCommand,
    retryCommand,
  ];
  Future<void> initialize() => _run(CarpenterResourceLoadReason.initial);
  @override
  Future<void> refresh() => _run(CarpenterResourceLoadReason.refresh);

  void _setData(T next, {required bool notify}) {
    final previous = _data;
    _data = next;
    didChangeData(previous, next);
    if (notify) notifyListeners();
  }

  Future<void> _run(CarpenterResourceLoadReason reason) async {
    final lease = _requests.begin();
    _refreshFailure = null;
    value = _data == null
        ? const CarpenterPageInitialLoading()
        : const CarpenterPageRefreshing();
    try {
      final loaded = await _load(
        CarpenterResourceLoadRequest(
          reason: reason,
          cancellation: lease.cancellation,
        ),
      );
      if (!_requests.isCurrent(lease)) return;
      _setData(loaded, notify: false);
      _refreshFailure = null;
      value = const CarpenterPageReady();
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(lease)) return;
      final failure = CarpenterResourceFailure(
        error: error,
        stackTrace: stackTrace,
        message: errorMessage?.call(error),
      );
      if (_data != null) {
        _refreshFailure = failure;
        value = const CarpenterPageReady();
      } else {
        value = CarpenterPageFailure(
          error: error,
          message: failure.message,
          retryCommand: retryCommand,
        );
      }
    } finally {
      _requests.finish(lease);
    }
  }

  @override
  void dispose() {
    _requests.dispose();
    refreshCommand.dispose();
    retryCommand.dispose();
    super.dispose();
  }
}
