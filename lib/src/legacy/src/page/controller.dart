import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:flutter/foundation.dart';

/// Coordinates page infrastructure while domain state stays in domain code.
abstract interface class CarpenterPageController
    implements ValueListenable<CarpenterPageState> {
  List<CarpenterCommand<dynamic>> get pageCommands;
  Future<void> refresh();
}

/// Small controller suitable for pages that do not need a custom adapter.
class CarpenterPageControllerBase extends ValueNotifier<CarpenterPageState>
    implements CarpenterPageController {
  CarpenterPageControllerBase({
    CarpenterPageState initialState = const CarpenterPageReady(),
    List<CarpenterCommand<dynamic>> commands = const [],
    Future<void> Function()? onRefresh,
  }) : pageCommands = commands,
       _onRefresh = onRefresh,
       super(initialState);

  @override
  final List<CarpenterCommand<dynamic>> pageCommands;
  final Future<void> Function()? _onRefresh;

  @override
  Future<void> refresh() async {
    final refresh = _onRefresh;
    if (refresh != null) await refresh();
  }
}
