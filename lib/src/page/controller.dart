import 'package:flutter/foundation.dart';

import '../application/command.dart';
import 'state.dart';

abstract interface class CarpenterPageController
    implements ValueListenable<CarpenterPageState> {
  List<CarpenterCommand<dynamic>> get pageCommands;
  Future<void> refresh();
}

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
    final callback = _onRefresh;
    if (callback != null) await callback();
  }
}
