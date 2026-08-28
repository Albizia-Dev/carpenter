import 'package:flutter/widgets.dart';

import '../application/command.dart';
import 'controller.dart';
import 'state.dart';

enum CarpenterResourceLoadReason { initial, refresh }

final class CarpenterResourceCancellation extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() { if (!_cancelled) { _cancelled = true; notifyListeners(); } }
}

final class CarpenterResourceLoadRequest {
  const CarpenterResourceLoadRequest({required this.reason, required this.cancellation});
  final CarpenterResourceLoadReason reason;
  final CarpenterResourceCancellation cancellation;
  bool get refresh => reason == CarpenterResourceLoadReason.refresh;
}

typedef CarpenterResourceLoader<T> = Future<T> Function(CarpenterResourceLoadRequest request);

final class CarpenterResourceController<T> extends ValueNotifier<CarpenterPageState> implements CarpenterPageController {
  CarpenterResourceController({required CarpenterResourceLoader<T> load, this.errorMessage})
      : _load = load, super(const CarpenterPageInitialLoading()) {
    refreshCommand = CarpenterCommandController<void>(id: 'resource.refresh', title: 'Refresh', presentation: CarpenterCommandPresentation.secondary, execute: (_) async { await refresh(); return const CarpenterCommandResult(); });
    retryCommand = CarpenterCommandController<void>(id: 'resource.retry', title: 'Retry', execute: (_) async { await refresh(); return const CarpenterCommandResult(); });
  }

  final CarpenterResourceLoader<T> _load;
  final String Function(Object error)? errorMessage;
  CarpenterResourceCancellation? _cancellation;
  int _generation = 0;
  T? data;
  late final CarpenterCommandController<void> refreshCommand;
  late final CarpenterCommandController<void> retryCommand;

  @override
  List<CarpenterCommand<dynamic>> get pageCommands => [refreshCommand, retryCommand];
  Future<void> initialize() => _run(CarpenterResourceLoadReason.initial);
  @override
  Future<void> refresh() => _run(CarpenterResourceLoadReason.refresh);

  Future<void> _run(CarpenterResourceLoadReason reason) async {
    final generation = ++_generation;
    _cancellation?.cancel();
    final cancellation = CarpenterResourceCancellation();
    _cancellation = cancellation;
    value = data == null ? const CarpenterPageInitialLoading() : const CarpenterPageRefreshing();
    try {
      final loaded = await _load(CarpenterResourceLoadRequest(reason: reason, cancellation: cancellation));
      if (generation != _generation || cancellation.isCancelled) return;
      data = loaded;
      value = const CarpenterPageReady();
    } catch (error) {
      if (generation != _generation || cancellation.isCancelled) return;
      value = CarpenterPageFailure(error: error, message: errorMessage?.call(error), retryCommand: retryCommand);
    } finally {
      if (identical(_cancellation, cancellation)) _cancellation = null;
      cancellation.dispose();
    }
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    _cancellation?.dispose();
    refreshCommand.dispose();
    retryCommand.dispose();
    super.dispose();
  }
}
