import 'dart:async';

import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension type const CarpenterCommandId(String value) {}

enum CarpenterCommandVisibility { visible, hidden }

enum CarpenterCommandExecution { idle, executing, failed }

enum CarpenterCommandPresentation { primary, secondary, danger, automatic }

abstract interface class CarpenterCommandEffect {
  const CarpenterCommandEffect();
}

final class CarpenterRefreshCommandEffect implements CarpenterCommandEffect {
  const CarpenterRefreshCommandEffect(this.scopes);

  final Set<String> scopes;
}

final class CarpenterBlockingCommandEffect implements CarpenterCommandEffect {
  const CarpenterBlockingCommandEffect();
}

class CarpenterCommandState {
  const CarpenterCommandState({
    this.visibility = CarpenterCommandVisibility.visible,
    this.enabled = true,
    this.disabledReason,
    this.execution = CarpenterCommandExecution.idle,
    this.error,
  });

  final CarpenterCommandVisibility visibility;
  final bool enabled;
  final String? disabledReason;
  final CarpenterCommandExecution execution;
  final Object? error;

  CarpenterCommandState copyWith({
    CarpenterCommandVisibility? visibility,
    bool? enabled,
    String? disabledReason,
    CarpenterCommandExecution? execution,
    Object? error,
    bool clearError = false,
  }) => CarpenterCommandState(
    visibility: visibility ?? this.visibility,
    enabled: enabled ?? this.enabled,
    disabledReason: disabledReason ?? this.disabledReason,
    execution: execution ?? this.execution,
    error: clearError ? null : error ?? this.error,
  );
}

class CarpenterCommandResult {
  const CarpenterCommandResult({
    this.message,
    this.undo,
    this.refreshScopes = const {},
    this.blockingEffect = false,
  });

  final String? message;
  final FutureOr<void> Function()? undo;
  final Set<String> refreshScopes;
  final bool blockingEffect;
}

abstract interface class CarpenterCommand<I> {
  String get id;

  String get title;

  String get group;

  String? get description;

  List<ShortcutActivator> get shortcuts;

  List<ShortcutActivator>? get macOSShortcuts;

  List<ShortcutActivator>? get windowsShortcuts;

  List<ShortcutActivator>? get linuxShortcuts;

  List<ShortcutActivator>? get iOSShortcuts;

  List<ShortcutActivator>? get androidShortcuts;

  List<ShortcutActivator>? get fuchsiaShortcuts;

  CarpenterCommandPresentation get presentation;

  List<CarpenterCommandEffect> get effects;

  ValueListenable<CarpenterCommandState> get state;

  Future<CarpenterCommandResult> execute(I input);
}

class CarpenterCommandController<I> extends ValueNotifier<CarpenterCommandState>
    implements CarpenterCommand<I> {
  CarpenterCommandController({
    required this.id,
    required this.title,
    FutureOr<CarpenterCommandResult> Function(I input)? execute,
    this.group = 'General',
    this.description,
    List<ShortcutActivator> shortcuts = const [],
    List<ShortcutActivator>? activators,
    List<ShortcutActivator>? macOSShortcuts,
    List<ShortcutActivator>? macOSActivators,
    List<ShortcutActivator>? windowsShortcuts,
    List<ShortcutActivator>? windowsActivators,
    List<ShortcutActivator>? linuxShortcuts,
    List<ShortcutActivator>? linuxActivators,
    List<ShortcutActivator>? iOSShortcuts,
    List<ShortcutActivator>? iOSActivators,
    List<ShortcutActivator>? androidShortcuts,
    List<ShortcutActivator>? androidActivators,
    List<ShortcutActivator>? fuchsiaShortcuts,
    List<ShortcutActivator>? fuchsiaActivators,
    this.presentation = CarpenterCommandPresentation.automatic,
    this.effects = const [],
    CarpenterCommandState initialState = const CarpenterCommandState(),
  }) : shortcuts = activators ?? shortcuts,
       macOSShortcuts = macOSActivators ?? macOSShortcuts,
       windowsShortcuts = windowsActivators ?? windowsShortcuts,
       linuxShortcuts = linuxActivators ?? linuxShortcuts,
       iOSShortcuts = iOSActivators ?? iOSShortcuts,
       androidShortcuts = androidActivators ?? androidShortcuts,
       fuchsiaShortcuts = fuchsiaActivators ?? fuchsiaShortcuts,
       _execute = execute ?? ((_) => const CarpenterCommandResult()),
       super(initialState);

  @override
  final String id;

  @override
  final String title;

  @override
  final String group;

  @override
  final String? description;

  @override
  final List<ShortcutActivator> shortcuts;

  @override
  final List<ShortcutActivator>? macOSShortcuts;
  @override
  final List<ShortcutActivator>? windowsShortcuts;
  @override
  final List<ShortcutActivator>? linuxShortcuts;
  @override
  final List<ShortcutActivator>? iOSShortcuts;
  @override
  final List<ShortcutActivator>? androidShortcuts;
  @override
  final List<ShortcutActivator>? fuchsiaShortcuts;

  @override
  final CarpenterCommandPresentation presentation;

  @override
  final List<CarpenterCommandEffect> effects;

  final FutureOr<CarpenterCommandResult> Function(I input) _execute;

  @override
  ValueListenable<CarpenterCommandState> get state => this;

  void setAvailability({
    CarpenterCommandVisibility visibility = CarpenterCommandVisibility.visible,
    required bool enabled,
    String? disabledReason,
  }) {
    value = value.copyWith(
      visibility: visibility,
      enabled: enabled,
      disabledReason: disabledReason,
    );
  }

  @override
  Future<CarpenterCommandResult> execute(I input) async {
    if (!value.enabled ||
        value.visibility == CarpenterCommandVisibility.hidden ||
        value.execution == CarpenterCommandExecution.executing) {
      throw StateError(value.disabledReason ?? 'Команда $id недоступна.');
    }
    value = value.copyWith(
      execution: CarpenterCommandExecution.executing,
      clearError: true,
    );
    try {
      final result = await _execute(input);
      value = value.copyWith(
        execution: CarpenterCommandExecution.idle,
        clearError: true,
      );
      return result;
    } catch (error) {
      value = value.copyWith(
        execution: CarpenterCommandExecution.failed,
        error: error,
      );
      rethrow;
    }
  }
}

/// Exposes the commands available in the current page or block.
class CarpenterCommandScope extends InheritedWidget {
  const CarpenterCommandScope({
    super.key,
    required this.commands,
    required super.child,
  });

  final List<CarpenterCommand<dynamic>> commands;

  static CarpenterCommandScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarpenterCommandScope>();

  static CarpenterCommandScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No CarpenterCommandScope found in context.');
    return scope!;
  }

  CarpenterCommand<dynamic>? find(String id) {
    for (final command in commands) {
      if (command.id == id) return command;
    }
    return null;
  }

  @override
  bool updateShouldNotify(CarpenterCommandScope oldWidget) =>
      !listEquals(commands, oldWidget.commands);
}

/// Renders one command as a button without creating a second action model.
class CarpenterCommandButton<I> extends StatelessWidget {
  const CarpenterCommandButton({
    super.key,
    required this.command,
    required this.input,
    this.child,
    this.secondary,
  });

  final CarpenterCommand<I> command;
  final I input;
  final Widget? child;
  final bool? secondary;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CarpenterCommandState>(
        valueListenable: command.state,
        builder: (context, state, _) {
          if (state.visibility == CarpenterCommandVisibility.hidden) {
            return const SizedBox.shrink();
          }
          final enabled =
              state.enabled &&
              state.execution != CarpenterCommandExecution.executing;
          final label = state.execution == CarpenterCommandExecution.executing
              ? '${command.title}…'
              : command.title;
          final useSecondary =
              secondary ??
              command.presentation == CarpenterCommandPresentation.secondary;
          final useDanger =
              command.presentation == CarpenterCommandPresentation.danger;
          if (useDanger) {
            return CarpenterButton(
              label: label,
              prominence: .outlined,
              colorRole: .danger,
              onInvoke: enabled ? () => _executeSafely(command, input) : null,
            );
          }
          if (useSecondary) {
            return CarpenterButton(
              label: label,
              prominence: .outlined,
              onInvoke: enabled ? () => _executeSafely(command, input) : null,
            );
          }
          return CarpenterButton(
            label: label,
            colorRole: .primary,
            prominence: .high,
            onInvoke: enabled ? () => _executeSafely(command, input) : null,
          );
        },
      );
}

typedef CarpenterCommandInputBuilder<I> =
    Future<I?> Function(BuildContext context);

/// Renders a command whose input is collected from a dialog or another surface.
class CarpenterCommandInputButton<I> extends StatelessWidget {
  const CarpenterCommandInputButton({
    super.key,
    required this.command,
    required this.inputBuilder,
    this.child,
    this.secondary,
  });

  final CarpenterCommand<I> command;
  final CarpenterCommandInputBuilder<I> inputBuilder;
  final Widget? child;
  final bool? secondary;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CarpenterCommandState>(
        valueListenable: command.state,
        builder: (context, state, _) {
          if (state.visibility == CarpenterCommandVisibility.hidden) {
            return const SizedBox.shrink();
          }
          final enabled =
              state.enabled &&
              state.execution != CarpenterCommandExecution.executing;
          final label = state.execution == CarpenterCommandExecution.executing
              ? '${command.title}…'
              : command.title;
          Future<void> invoke() async {
            final input = await inputBuilder(context);
            if (input != null) await _executeSafely(command, input);
          }

          final useSecondary =
              secondary ??
              command.presentation == CarpenterCommandPresentation.secondary;
          return useSecondary
              ? CarpenterButton(
                  label: label,
                  prominence: .outlined,
                  onInvoke: enabled ? invoke : null,
                )
              : CarpenterButton(
                  label: label,
                  colorRole: .primary,
                  prominence: .high,
                  onInvoke: enabled ? invoke : null,
                );
        },
      );
}

Future<void> _executeSafely<I>(CarpenterCommand<I> command, I input) async {
  try {
    await command.execute(input);
  } catch (_) {
    // The command state is the canonical error channel. Avoid an unhandled
    // asynchronous exception from buttons while observers render that state.
  }
}

/// Binds shortcut metadata of the same commands used by buttons and menus.
class CarpenterCommandShortcutScope extends StatelessWidget {
  const CarpenterCommandShortcutScope({
    super.key,
    required this.bindings,
    required this.child,
  });

  final List<CarpenterCommandBinding<dynamic>> bindings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final callbacks = <ShortcutActivator, VoidCallback>{};
    for (final binding in bindings) {
      final command = binding.command;
      for (final shortcut in command.shortcuts) {
        if (callbacks.containsKey(shortcut)) {
          throw StateError(
            'Shortcut $shortcut is assigned to multiple page commands.',
          );
        }
        callbacks[shortcut] = () {
          final state = command.state.value;
          if (state.visibility == CarpenterCommandVisibility.visible &&
              state.enabled &&
              state.execution != CarpenterCommandExecution.executing) {
            unawaited(command.execute(binding.input));
          }
        };
      }
    }
    if (callbacks.isEmpty) return child;
    return CallbackShortcuts(
      bindings: callbacks,
      child: Focus(autofocus: true, child: child),
    );
  }
}

final class CarpenterCommandBinding<I> {
  const CarpenterCommandBinding({required this.command, required this.input});

  final CarpenterCommand<I> command;
  final I input;
}
