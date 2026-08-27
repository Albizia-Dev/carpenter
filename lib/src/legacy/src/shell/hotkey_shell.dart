import 'package:carpenter/src/legacy/src/component/hotkey/carpenter_hotkey.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';
import 'package:flutter/widgets.dart';

/// Runtime capability hotkey shell-а.
class CarpenterHotkeyRuntime {
  /// Создает hotkey runtime.
  const CarpenterHotkeyRuntime({
    required this.controller,
    required this.commands,
  });

  /// Контроллер текущего состояния клавиатуры.
  final CarpenterHotkeyController controller;

  /// Зарегистрированные команды.
  final List<CarpenterCommand<void>> commands;
}

/// Typed access к hotkey capability.
extension CarpenterHotkeyRuntimeAccess on CarpenterRuntime {
  /// Hotkey runtime.
  CarpenterHotkeyRuntime get hotkeys => read<CarpenterHotkeyRuntime>();
}

/// Callback команды hotkey с доступом к typed runtime.
typedef CarpenterRuntimeHotkeyCommandCallback =
    void Function(CarpenterRuntime runtime, CarpenterCommand<void> command);

/// Shell, который подключает `CarpenterHotkeyScope` и capability hotkeys.
class CarpenterHotkeyShell extends CarpenterShellBase {
  /// Создает hotkey shell.
  CarpenterHotkeyShell({
    this.commands = const [],
    this.onCommand,
    CarpenterHotkeyController? controller,
    this.enabled = true,
    this.trackPressedKeys = true,
    this.autofocus = true,
    this.platform,
  }) : controller = controller ?? CarpenterHotkeyController();

  /// Hotkey-команды.
  final List<CarpenterCommand<void>> commands;

  /// Callback выполнения команды с доступом к runtime.
  final CarpenterRuntimeHotkeyCommandCallback? onCommand;

  /// Контроллер hotkey state.
  final CarpenterHotkeyController controller;

  /// Включить shortcuts и мониторинг.
  final bool enabled;

  /// Отслеживать текущие нажатые клавиши.
  final bool trackPressedKeys;

  /// Автофокус hotkey-ветки.
  final bool autofocus;

  /// Platform override для выбора hotkey-комбинаций.
  final TargetPlatform? platform;

  @override
  String get id => 'carpenter.hotkeys';

  @override
  Set<Type> get provides => const {CarpenterHotkeyRuntime};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime.extend(
      CarpenterHotkeyRuntime(controller: controller, commands: commands),
    );
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) {
    return CarpenterHotkeyScope(
      commands: commands,
      onCommand: (command) {
        onCommand?.call(context.runtime, command);
      },
      controller: controller,
      platform: platform,
      enabled: enabled,
      trackPressedKeys: trackPressedKeys,
      autofocus: autofocus,
      child: child,
    );
  }
}
