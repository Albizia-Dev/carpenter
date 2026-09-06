import 'package:flutter/widgets.dart';

import 'command.dart';
import 'hotkey.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

/// Runtime capability published by the hotkey shell, containing the effective
/// controller, commands, and target platform.
final class CarpenterHotkeyRuntime {
  /// Creates hotkey runtime state from a concrete controller, command list, and
  /// platform selected during shell configuration.
  const CarpenterHotkeyRuntime({
    required this.controller,
    required this.commands,
    required this.platform,
  });

  /// Controller used by the hosted hotkey scope to expose pressed-key snapshots.
  final CarpenterHotkeyController controller;

  /// Commands made available to the hosted hotkey scope.
  final List<CarpenterCommand<void>> commands;

  /// Effective platform used for shortcut selection and formatting.
  final TargetPlatform platform;
}

/// Typed access to hotkey capability registered in a [CarpenterRuntime].
extension CarpenterHotkeyRuntimeAccess on CarpenterRuntime {
  /// Mandatory hotkey runtime capability; throws when no hotkey shell registered it.
  CarpenterHotkeyRuntime get hotkeys => read<CarpenterHotkeyRuntime>();
}

/// Application shell that publishes hotkey runtime capability and wraps content
/// in a [CarpenterHotkeyScope].
final class CarpenterHotkeyShell extends CarpenterShellBase {
  /// Creates a hotkey shell.
  ///
  /// A supplied [controller] remains caller-owned. When omitted, configuration
  /// creates the controller that is retained by the published runtime capability.
  const CarpenterHotkeyShell({
    this.commands = const [],
    this.onCommand,
    this.controller,
    this.platform,
    this.trackPressedKeys = true,
    this.autofocus = true,
  });

  /// Commands bound by the hosted hotkey scope.
  final List<CarpenterCommand<void>> commands;

  /// Optional observer invoked immediately before a keyboard shortcut executes
  /// its command.
  final CarpenterHotkeyCommandCallback? onCommand;

  /// Optional externally owned hotkey controller.
  ///
  /// When absent, a controller is created during shell configuration and retained
  /// in runtime. The shell API itself has no independent disposal hook.
  final CarpenterHotkeyController? controller;

  /// Optional shortcut-platform override; otherwise the core runtime platform is
  /// used.
  final TargetPlatform? platform;

  /// Whether the hosted hotkey scope records pressed-key snapshots.
  final bool trackPressedKeys;

  /// Whether the hosted hotkey focus scope requests focus automatically.
  final bool autofocus;

  /// Stable shell identifier used for diagnostics and capability-composition
  /// errors.
  @override
  String get id => 'carpenter.hotkeys';

  /// Declares that successful configuration registers [CarpenterHotkeyRuntime].
  @override
  Set<Type> get provides => const {CarpenterHotkeyRuntime};

  CarpenterHotkeyController get _controller =>
      controller ?? CarpenterHotkeyController();

  /// Chooses the effective platform and extends runtime with the concrete
  /// controller and command set used by [wrap].
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    final target = platform ?? context.runtime.core.platform;
    return context.runtime.extend(
      CarpenterHotkeyRuntime(
        controller: _controller,
        commands: commands,
        platform: target,
      ),
    );
  }

  /// Reads the configured hotkey capability and installs [CarpenterHotkeyScope]
  /// around hosted content.
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
