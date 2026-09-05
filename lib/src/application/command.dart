import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../foundation/icon_data.dart';
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

/// One application-level execution event emitted around a command invocation.
///
/// The event carries semantic command metadata only. It deliberately does not
/// know how feedback is rendered, how data is cached, or which state-management
/// package an application uses.
@immutable
sealed class CarpenterCommandExecutionEvent {
  const CarpenterCommandExecutionEvent({
    required this.commandId,
    required this.title,
    required this.group,
    required this.effects,
  });

  final String commandId;
  final String title;
  final String group;
  final List<CarpenterCommandEffect> effects;

  bool get isBlocking =>
      effects.any((effect) => effect is CarpenterBlockingCommandEffect);
}

final class CarpenterCommandStarted extends CarpenterCommandExecutionEvent {
  const CarpenterCommandStarted({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
  });
}

final class CarpenterCommandSucceeded extends CarpenterCommandExecutionEvent {
  const CarpenterCommandSucceeded({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
    required this.result,
  });

  final CarpenterCommandResult result;

  String? get message => result.message;
  FutureOr<void> Function()? get undo => result.undo;

  Set<String> get refreshScopes => Set<String>.unmodifiable({
    for (final effect in effects)
      if (effect is CarpenterRefreshCommandEffect) ...effect.scopes,
    ...result.refreshScopes,
  });

  @override
  bool get isBlocking => super.isBlocking || result.blockingEffect;
}

final class CarpenterCommandFailed extends CarpenterCommandExecutionEvent {
  const CarpenterCommandFailed({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}

typedef CarpenterCommandExecutionListener =
    void Function(CarpenterCommandExecutionEvent event);

/// Executes commands and emits one uniform lifecycle for application policy.
///
/// Listeners can translate command outcomes into feedback, undo registration,
/// cache invalidation, blocking presentation, analytics, or other application
/// concerns without those concerns leaking into the command itself. Listener
/// failures are reported to Flutter but never turn a successful business
/// command into a failed command.
final class CarpenterCommandExecutor {
  const CarpenterCommandExecutor({this.listeners = const []});

  final List<CarpenterCommandExecutionListener> listeners;

  Future<CarpenterCommandResult> execute<I>(
    CarpenterCommand<I> command,
    I input,
  ) async {
    final effects = List<CarpenterCommandEffect>.unmodifiable(command.effects);
    _emit(
      CarpenterCommandStarted(
        commandId: command.id,
        title: command.title,
        group: command.group,
        effects: effects,
      ),
    );
    try {
      final result = await command.execute(input);
      _emit(
        CarpenterCommandSucceeded(
          commandId: command.id,
          title: command.title,
          group: command.group,
          effects: effects,
          result: result,
        ),
      );
      return result;
    } catch (error, stackTrace) {
      _emit(
        CarpenterCommandFailed(
          commandId: command.id,
          title: command.title,
          group: command.group,
          effects: effects,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      rethrow;
    }
  }

  void _emit(CarpenterCommandExecutionEvent event) {
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'carpenter',
            context: ErrorDescription(
              'while dispatching a Carpenter command execution event',
            ),
          ),
        );
      }
    }
  }
}

/// Supplies the application command execution policy to descendant surfaces.
final class CarpenterCommandExecutionScope extends InheritedWidget {
  const CarpenterCommandExecutionScope({
    super.key,
    required this.executor,
    required super.child,
  });

  final CarpenterCommandExecutor executor;

  static CarpenterCommandExecutionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarpenterCommandExecutionScope>();

  @override
  bool updateShouldNotify(CarpenterCommandExecutionScope oldWidget) =>
      oldWidget.executor != executor;
}

extension CarpenterCommandExecutionBuildContext on BuildContext {
  CarpenterCommandExecutor? get commandExecutor =>
      CarpenterCommandExecutionScope.maybeOf(this)?.executor;

  Future<CarpenterCommandResult> executeCommand<I>(
    CarpenterCommand<I> command,
    I input,
  ) {
    final executor = commandExecutor;
    return executor == null
        ? command.execute(input)
        : executor.execute(command, input);
  }
}

/// Projects an executable application command into Carpenter's shared action
/// language. The returned descriptor is a snapshot of the command state; build
/// it inside a listener when the presentation must react to availability or
/// execution changes.
extension CarpenterCommandActionProjection<I> on CarpenterCommand<I> {
  CarpenterActionDescriptor toAction(
    I input, {
    String? label,
    String? semanticLabel,
    CarpenterIconSource? icon,
    ActionColorRole? colorRole,
    ShortcutActivator? shortcut,
    CarpenterCommandExecutor? executor,
  }) {
    final current = state.value;
    final visible = current.visibility == CarpenterCommandVisibility.visible;
    final available =
        visible &&
        current.enabled &&
        current.execution != CarpenterCommandExecution.executing;
    return CarpenterActionDescriptor(
      id: id,
      label: label ?? title,
      semanticLabel: semanticLabel,
      icon: icon,
      colorRole: colorRole ?? _commandColorRole(presentation),
      shortcut: shortcut ?? (shortcuts.isEmpty ? null : shortcuts.first),
      visible: visible,
      disabledReason: available ? null : current.disabledReason,
      onInvoke: available
          ? () {
              unawaited(
                executor == null
                    ? execute(input)
                    : executor.execute(this, input),
              );
            }
          : null,
    );
  }
}

ActionColorRole _commandColorRole(CarpenterCommandPresentation presentation) =>
    switch (presentation) {
      CarpenterCommandPresentation.danger => ActionColorRole.danger,
      CarpenterCommandPresentation.primary => ActionColorRole.primary,
      CarpenterCommandPresentation.secondary ||
      CarpenterCommandPresentation.automatic => ActionColorRole.neutral,
    };

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
    final executor = CarpenterCommandExecutionScope.maybeOf(context)?.executor;
    for (final binding in bindings) {
      final state = binding.command.state.value;
      if (!state.enabled ||
          state.visibility == CarpenterCommandVisibility.hidden) {
        continue;
      }
      for (final activator in binding.shortcuts ?? binding.command.shortcuts) {
        shortcuts[activator] = _CarpenterCommandIntent(() async {
          if (executor == null) {
            await binding.command.execute(binding.input);
          } else {
            await executor.execute(binding.command, binding.input);
          }
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
          if (state.visibility == CarpenterCommandVisibility.hidden) {
            return const SizedBox.shrink();
          }
          final presentation = command.presentation;
          return CarpenterButton.fromAction(
            command.toAction(
              input,
              label: state.execution == CarpenterCommandExecution.executing
                  ? '${command.title}…'
                  : command.title,
              executor: CarpenterCommandExecutionScope.maybeOf(
                context,
              )?.executor,
            ),
            prominence: presentation == CarpenterCommandPresentation.primary
                ? ActionProminence.high
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
