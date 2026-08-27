import 'dart:async';

import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/controller.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:flutter/widgets.dart';

enum CarpenterResourceLoadReason { initial, refresh }

class CarpenterResourceCancellation extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
  }
}

final class CarpenterResourceLoadRequest {
  const CarpenterResourceLoadRequest({
    required this.reason,
    required this.cancellation,
  });

  final CarpenterResourceLoadReason reason;
  final CarpenterResourceCancellation cancellation;
  bool get refresh => reason == CarpenterResourceLoadReason.refresh;
}

typedef CarpenterResourceLoader<T> =
    Future<T> Function(CarpenterResourceLoadRequest request);

/// Owns the complete lifecycle of one asynchronously loaded record/resource.
class CarpenterResourceController<T> extends ValueNotifier<CarpenterPageState>
    implements CarpenterPageController {
  CarpenterResourceController({
    required CarpenterResourceLoader<T> load,
    this.errorMessage,
  }) : _load = load,
       super(const CarpenterPageInitialLoading()) {
    refreshCommand = CarpenterCommandController<void>(
      id: 'resource.refresh',
      title: 'Обновить',
      presentation: CarpenterCommandPresentation.secondary,
      effects: const [
        CarpenterRefreshCommandEffect({'resource'}),
      ],
      execute: (_) async {
        await refresh();
        return const CarpenterCommandResult();
      },
    );
    _retryCommand = CarpenterCommandController<void>(
      id: 'resource.retry',
      title: 'Повторить',
      execute: (_) async {
        await refresh();
        return const CarpenterCommandResult();
      },
    );
  }

  final CarpenterResourceLoader<T> _load;
  final String Function(Object error)? errorMessage;
  CarpenterResourceCancellation? _cancellation;
  int _generation = 0;
  T? data;
  late final CarpenterCommandController<void> refreshCommand;
  late final CarpenterCommandController<void> _retryCommand;

  @override
  List<CarpenterCommand<dynamic>> get pageCommands => [
    refreshCommand,
    _retryCommand,
  ];

  Future<void> initialize() => _run(CarpenterResourceLoadReason.initial);

  @override
  Future<void> refresh() => _run(CarpenterResourceLoadReason.refresh);

  Future<void> _run(CarpenterResourceLoadReason reason) async {
    final generation = ++_generation;
    _cancellation?.cancel();
    final cancellation = CarpenterResourceCancellation();
    _cancellation = cancellation;
    value = data == null
        ? const CarpenterPageInitialLoading()
        : const CarpenterPageRefreshing();
    try {
      final loaded = await _load(
        CarpenterResourceLoadRequest(
          reason: reason,
          cancellation: cancellation,
        ),
      );
      if (generation != _generation || cancellation.isCancelled) return;
      data = loaded;
      value = const CarpenterPageReady();
    } catch (error) {
      if (generation != _generation || cancellation.isCancelled) return;
      reportFailure(error);
    } finally {
      if (identical(_cancellation, cancellation)) {
        _cancellation = null;
      }
      cancellation.dispose();
    }
  }

  void reportFailure(Object error) {
    value = CarpenterPageFailure(
      error: error,
      message: errorMessage?.call(error),
      retryCommand: _retryCommand,
    );
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    _cancellation?.dispose();
    refreshCommand.dispose();
    _retryCommand.dispose();
    super.dispose();
  }
}

typedef CarpenterResourceControllerFactory<
  T,
  C extends CarpenterResourceController<T>
> = C Function(BuildContext context);

class CarpenterResourceControllerHost<
  T,
  C extends CarpenterResourceController<T>
>
    extends StatefulWidget {
  const CarpenterResourceControllerHost({
    super.key,
    required this.create,
    required this.builder,
  });

  final CarpenterResourceControllerFactory<T, C> create;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<CarpenterResourceControllerHost<T, C>> createState() =>
      _CarpenterResourceControllerHostState<T, C>();
}

class _CarpenterResourceControllerHostState<
  T,
  C extends CarpenterResourceController<T>
>
    extends State<CarpenterResourceControllerHost<T, C>> {
  C? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller != null) return;
    final created = widget.create(context);
    controller = created;
    unawaited(created.initialize());
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller!,
    builder: (context, _) => widget.builder(context, controller!),
  );
}
