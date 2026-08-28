import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../foundation/roles.dart';

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

@immutable
final class CarpenterCommandState {
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

final class CarpenterCommandResult {
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

final class CarpenterCommandController<I>
    extends ValueNotifier<CarpenterCommandState>
    implements CarpenterCommand<I> {
  CarpenterCommandController({
    required this.id,
    required this.title,
    FutureOr<CarpenterCommandResult> Function(I input)? execute,
    this.group = 'General',
    this.description,
    this.shortcuts = const [],
    this.macOSShortcuts,
    this.windowsShortcuts,
    this.linuxShortcuts,
    this.iOSShortcuts,
    this.androidShortcuts,
    this.fuchsiaShortcuts,
    this.presentation = CarpenterCommandPresentation.automatic,
    this.effects = const [],
    CarpenterCommandState initialState = const CarpenterCommandState(),
  }) : _execute = execute ?? ((_) => const CarpenterCommandResult()),
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
      throw StateError(value.disabledReason ?? 'Command $id is unavailable.');
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

final class CarpenterCommandScope extends InheritedWidget {
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

final class CarpenterCommandBinding<I> {
  const CarpenterCommandBinding({
    required this.command,
    required this.input,
    this.shortcuts,
  });
  final CarpenterCommand<I> command;
  final I input;
  final List<ShortcutActivator>? shortcuts;
}

final class _CarpenterCommandIntent extends Intent {
  const _CarpenterCommandIntent(this.invoke);
  final Future<void> Function() invoke;
}

final class CarpenterCommandShortcutScope extends StatelessWidget {
  const CarpenterCommandShortcutScope({
    super.key,
    required this.bindings,
    required this.child,
  });
  final List<CarpenterCommandBinding<dynamic>> bindings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{};
    for (final binding in bindings) {
      final state = binding.command.state.value;
      if (!state.enabled ||
          state.visibility == CarpenterCommandVisibility.hidden)
        continue;
      for (final activator in binding.shortcuts ?? binding.command.shortcuts) {
        shortcuts[activator] = _CarpenterCommandIntent(() async {
          await binding.command.execute(binding.input);
        });
      }
    }
    return Actions(
      actions: <Type, Action<Intent>>{
        _CarpenterCommandIntent: CallbackAction<_CarpenterCommandIntent>(
          onInvoke: (intent) => intent.invoke(),
        ),
      },
      child: Shortcuts(shortcuts: shortcuts, child: child),
    );
  }
}

final class CarpenterCommandButton<I> extends StatelessWidget {
  const CarpenterCommandButton({
    super.key,
    required this.command,
    required this.input,
  });
  final CarpenterCommand<I> command;
  final I input;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CarpenterCommandState>(
        valueListenable: command.state,
        builder: (context, state, _) {
          if (state.visibility == CarpenterCommandVisibility.hidden)
            return const SizedBox.shrink();
          final presentation = command.presentation;
          return CarpenterButton(
            label: state.execution == CarpenterCommandExecution.executing
                ? '${command.title}…'
                : command.title,
            onInvoke:
                state.enabled &&
                    state.execution != CarpenterCommandExecution.executing
                ? () => command.execute(input)
                : null,
            colorRole: presentation == CarpenterCommandPresentation.danger
                ? ActionColorRole.danger
                : ActionColorRole.primary,
            prominence: presentation == CarpenterCommandPresentation.primary
                ? ActionProminence.high
                : presentation == CarpenterCommandPresentation.danger
                ? ActionProminence.outlined
                : ActionProminence.outlined,
            executionPhase: switch (state.execution) {
              CarpenterCommandExecution.idle => ActionExecutionPhase.idle,
              CarpenterCommandExecution.executing =>
                ActionExecutionPhase.running,
              CarpenterCommandExecution.failed => ActionExecutionPhase.failed,
            },
          );
        },
      );
}
