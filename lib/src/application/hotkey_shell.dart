import 'package:flutter/widgets.dart';

import 'command.dart';
import 'hotkey.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

final class CarpenterHotkeyRuntime {
  const CarpenterHotkeyRuntime({required this.controller, required this.commands, required this.platform});
  final CarpenterHotkeyController controller;
  final List<CarpenterCommand<void>> commands;
  final TargetPlatform platform;
}

extension CarpenterHotkeyRuntimeAccess on CarpenterRuntime {
  CarpenterHotkeyRuntime get hotkeys => read<CarpenterHotkeyRuntime>();
}

final class CarpenterHotkeyShell extends CarpenterShellBase {
  const CarpenterHotkeyShell({
    this.commands = const [],
    this.onCommand,
    this.controller,
    this.platform,
    this.trackPressedKeys = true,
    this.autofocus = true,
  });

  final List<CarpenterCommand<void>> commands;
  final CarpenterHotkeyCommandCallback? onCommand;
  final CarpenterHotkeyController? controller;
  final TargetPlatform? platform;
  final bool trackPressedKeys;
  final bool autofocus;

  @override
  String get id => 'carpenter.hotkeys';
  @override
  Set<Type> get provides => const {CarpenterHotkeyRuntime};

  CarpenterHotkeyController get _controller => controller ?? CarpenterHotkeyController();

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    final target = platform ?? context.runtime.core.platform;
    return context.runtime.extend(CarpenterHotkeyRuntime(controller: _controller, commands: commands, platform: target));
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) {
    final runtime = context.runtime.read<CarpenterHotkeyRuntime>();
    return CarpenterHotkeyScope(
      commands: commands,
      onCommand: onCommand,
      controller: runtime.controller,
      platform: runtime.platform,
      trackPressedKeys: trackPressedKeys,
      autofocus: autofocus,
      child: child,
    );
  }
}
