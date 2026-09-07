import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../foundation/icon_data.dart';
import '../foundation/roles.dart';

/// Strongly typed semantic identifier for an application command.
///
/// Use stable IDs for lookup, analytics, routing, and persistence; the value is
/// not a localized presentation label.
extension type const CarpenterCommandId(String value) {}

/// Whether a command participates in command surfaces.
enum CarpenterCommandVisibility {
  /// The command may be presented when the surrounding surface chooses to show it.
  visible,

  /// The command is omitted from command surfaces and cannot be invoked there.
  hidden,
}

/// Current execution phase exposed by a command's observable state.
enum CarpenterCommandExecution {
  /// No invocation is currently running and no failure is being presented.
  idle,

  /// An invocation is currently in progress.
  executing,

  /// The most recent invocation failed; inspect [CarpenterCommandState.error].
  failed,
}

/// Semantic prominence requested when a command is projected into an action surface.
enum CarpenterCommandPresentation {
  /// Prefer the surface's primary-action treatment.
  primary,

  /// Prefer a secondary or outlined treatment.
  secondary,

  /// Present the action as destructive or otherwise dangerous.
  danger,

  /// Let the consuming surface choose its normal command treatment.
  automatic,
}

/// Marker for semantic side effects declared by a command.
///
/// Effects describe application policy such as invalidation or blocking UI; they
/// do not perform that work by themselves.
abstract interface class CarpenterCommandEffect {
  /// Creates a semantic command effect marker.
  const CarpenterCommandEffect();
}

/// Declares semantic data scopes that should be refreshed after success.
final class CarpenterRefreshCommandEffect implements CarpenterCommandEffect {
  /// Creates a refresh effect for the supplied semantic [scopes].
  const CarpenterRefreshCommandEffect(this.scopes);

  /// Semantic invalidation scopes consumed by application refresh policy.
  final Set<String> scopes;
}

/// Marks a command as requiring blocking presentation while application policy handles it.
///
/// This effect is descriptive only; [CarpenterCommandExecutor] listeners decide
/// how, or whether, to render a blocking state.
final class CarpenterBlockingCommandEffect implements CarpenterCommandEffect {
  /// Creates the blocking semantic effect marker.
  const CarpenterBlockingCommandEffect();
}

/// Immutable observable availability and execution state for a command.
///
/// Visibility, enabled state, execution phase, and the latest error are kept
/// separate so presentation surfaces can distinguish unavailable, hidden, running,
/// and failed commands without inferring state from callbacks.
@immutable
final class CarpenterCommandState {
  /// Creates command state with visible, enabled, idle defaults.
  const CarpenterCommandState({
    this.visibility = CarpenterCommandVisibility.visible,
    this.enabled = true,
    this.disabledReason,
    this.execution = CarpenterCommandExecution.idle,
    this.error,
  });

  /// Whether the command is visible to presentation surfaces.
  final CarpenterCommandVisibility visibility;

  /// Whether the command may currently be invoked.
  final bool enabled;

  /// Optional user-facing reason explaining why an unavailable command is disabled.
  final String? disabledReason;

  /// Current execution phase for the command.
  final CarpenterCommandExecution execution;

  /// Error retained from the latest failed invocation, otherwise `null`.
  final Object? error;

  /// Returns a state copy, preserving nullable values unless their corresponding
  /// clear flag is set.
  CarpenterCommandState copyWith({
    CarpenterCommandVisibility? visibility,
    bool? enabled,
    String? disabledReason,
    CarpenterCommandExecution? execution,
    Object? error,
    bool clearDisabledReason = false,
    bool clearError = false,
  }) => CarpenterCommandState(
    visibility: visibility ?? this.visibility,
    enabled: enabled ?? this.enabled,
    disabledReason: clearDisabledReason
        ? null
        : disabledReason ?? this.disabledReason,
    execution: execution ?? this.execution,
    error: clearError ? null : error ?? this.error,
  );
}

/// Semantic result returned by a successful command invocation.
///
/// The result can carry feedback, undo, invalidation, and blocking hints without
/// coupling the command to any particular UI or data framework.
final class CarpenterCommandResult {
  /// Creates a successful command result with no feedback or effects by default.
  const CarpenterCommandResult({
    this.message,
    this.undo,
    this.redo,
    this.refreshScopes = const {},
    this.blockingEffect = false,
  });

  /// Optional user-facing success message for application feedback policy.
  final String? message;

  /// Optional undo operation that application policy may register or present.
  final FutureOr<void> Function()? undo;

  /// Optional redo operation paired with [undo]. A null value makes the
  /// successful command undo-only.
  final FutureOr<void> Function()? redo;

  /// Additional semantic invalidation scopes requested by this concrete result.
  final Set<String> refreshScopes;

  /// Whether this result requests blocking presentation in addition to declared effects.
  final bool blockingEffect;
}

/// Typed application command contract shared by buttons, shortcuts, and policy.
///
/// Implementations own business execution and observable availability. Carpenter
/// surfaces only project this contract and do not own domain state.
abstract interface class CarpenterCommand<I> {
  /// Stable semantic identifier used for lookup and execution events.
  String get id;

  /// Human-readable action title used by default presentation surfaces.
  String get title;

  /// Logical command group used by command discovery and organization.
  String get group;

  /// Optional longer description of the command's intent.
  String? get description;

  /// Default shortcut activators used when no platform-specific override exists.
  List<ShortcutActivator> get shortcuts;

  /// macOS-specific shortcut override, or `null` to use [shortcuts].
  List<ShortcutActivator>? get macOSShortcuts;

  /// Windows-specific shortcut override, or `null` to use [shortcuts].
  List<ShortcutActivator>? get windowsShortcuts;

  /// Linux-specific shortcut override, or `null` to use [shortcuts].
  List<ShortcutActivator>? get linuxShortcuts;

  /// iOS-specific shortcut override, or `null` to fall back to Apple/default shortcuts.
  List<ShortcutActivator>? get iOSShortcuts;

  /// Android-specific shortcut override, or `null` to use [shortcuts].
  List<ShortcutActivator>? get androidShortcuts;

  /// Fuchsia-specific shortcut override, or `null` to use [shortcuts].
  List<ShortcutActivator>? get fuchsiaShortcuts;

  /// Semantic prominence requested when this command is rendered as an action.
  CarpenterCommandPresentation get presentation;

  /// Semantic application effects declared independently of concrete execution results.
  List<CarpenterCommandEffect> get effects;

  /// Observable command availability, execution phase, and latest failure.
  ValueListenable<CarpenterCommandState> get state;

  /// Executes the command for [input], returning a semantic success result or
  /// propagating the original failure.
  Future<CarpenterCommandResult> execute(I input);
}

/// One application-level execution event emitted around a command invocation.
///
/// The event carries semantic command metadata only. It deliberately does not
/// know how feedback is rendered, how data is cached, or which state-management
/// package an application uses.
@immutable
sealed class CarpenterCommandExecutionEvent {
  /// Creates an execution lifecycle event from immutable command metadata and effects.
  const CarpenterCommandExecutionEvent({
    required this.commandId,
    required this.title,
    required this.group,
    required this.effects,
  });

  /// Stable identifier of the command that produced this lifecycle event.
  final String commandId;

  /// Command title captured at invocation time.
  final String title;

  /// Command group captured at invocation time.
  final String group;

  /// Immutable semantic effects captured before execution begins.
  final List<CarpenterCommandEffect> effects;

  /// Whether the captured effects include a blocking-command marker.
  bool get isBlocking =>
      effects.any((effect) => effect is CarpenterBlockingCommandEffect);
}

/// Lifecycle event emitted immediately before command execution begins.
final class CarpenterCommandStarted extends CarpenterCommandExecutionEvent {
  /// Creates a command-started event from the metadata captured by the executor.
  const CarpenterCommandStarted({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
  });
}

/// Lifecycle event emitted after a command completes successfully.
final class CarpenterCommandSucceeded extends CarpenterCommandExecutionEvent {
  /// Creates a success event carrying the command's semantic [result].
  const CarpenterCommandSucceeded({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
    required this.result,
  });

  /// Semantic result returned by the completed command.
  final CarpenterCommandResult result;

  /// Convenience view of [CarpenterCommandResult.message].
  String? get message => result.message;

  /// Convenience view of [CarpenterCommandResult.undo].
  FutureOr<void> Function()? get undo => result.undo;

  /// Union of refresh scopes declared by command effects and the concrete result.
  Set<String> get refreshScopes => Set<String>.unmodifiable({
    for (final effect in effects)
      if (effect is CarpenterRefreshCommandEffect) ...effect.scopes,
    ...result.refreshScopes,
  });

  /// Whether either the command effects or concrete result request blocking presentation.
  @override
  bool get isBlocking => super.isBlocking || result.blockingEffect;
}

/// Lifecycle event emitted when command execution throws.
final class CarpenterCommandFailed extends CarpenterCommandExecutionEvent {
  /// Creates a failed event with the original [error] and [stackTrace].
  const CarpenterCommandFailed({
    required super.commandId,
    required super.title,
    required super.group,
    required super.effects,
    required this.error,
    required this.stackTrace,
  });

  /// Original error thrown by command execution.
  final Object error;

  /// Stack trace captured with [error].
  final StackTrace stackTrace;
}

/// Listener notified synchronously for command started, succeeded, and failed events.
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
  /// Creates an executor with zero or more synchronous lifecycle [listeners].
  const CarpenterCommandExecutor({this.listeners = const []});

  /// Application-policy listeners notified for each execution lifecycle event.
  final List<CarpenterCommandExecutionListener> listeners;

  /// Executes [command], emitting started then succeeded/failed events while preserving
  /// the command's returned result or thrown failure.
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
  /// Creates an inherited execution-policy boundary around [child].
  const CarpenterCommandExecutionScope({
    super.key,
    required this.executor,
    required super.child,
  });

  /// Executor used by descendant presentation surfaces.
  final CarpenterCommandExecutor executor;

  /// Returns the nearest execution scope while establishing an inherited dependency,
  /// or `null` when no scope exists.
  static CarpenterCommandExecutionScope? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CarpenterCommandExecutionScope>();

  /// Notifies descendants when the executor instance changes.
  @override
  bool updateShouldNotify(CarpenterCommandExecutionScope oldWidget) =>
      oldWidget.executor != executor;
}

/// Convenience helpers for resolving and using command execution policy from context.
extension CarpenterCommandExecutionBuildContext on BuildContext {
  /// Executor supplied by the nearest [CarpenterCommandExecutionScope], if present.
  CarpenterCommandExecutor? get commandExecutor =>
      CarpenterCommandExecutionScope.maybeOf(this)?.executor;

  /// Executes [command] through the nearest executor when available, otherwise invokes
  /// the command directly so programmatic failures still propagate to the caller.
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

/// Runs a command from a presentation-only surface.
///
/// Command state and [CarpenterCommandExecutor] listeners own failure
/// presentation. A button or shortcut therefore consumes the already-recorded
/// asynchronous error instead of also leaking it as an uncaught Future error.
/// Programmatic callers should use [CarpenterCommand.execute] or
/// [CarpenterCommandExecutionBuildContext.executeCommand] when they need the
/// failure to propagate.
Future<void> _executeCommandForSurface<I>(
  CarpenterCommand<I> command,
  I input,
  CarpenterCommandExecutor? executor,
) async {
  try {
    if (executor == null) {
      await command.execute(input);
    } else {
      await executor.execute(command, input);
    }
  } catch (_) {
    // Failure is already represented by command state and execution policy.
  }
}

/// Projects an executable application command into Carpenter's shared action
/// language. The returned descriptor is a snapshot of the command state; build
/// it inside a listener when the presentation must react to availability or
/// execution changes.
extension CarpenterCommandActionProjection<I> on CarpenterCommand<I> {
  /// Creates a presentation-only action snapshot for [input] from the command's current
  /// visibility, availability, execution state, shortcuts, and semantic prominence.
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
              unawaited(_executeCommandForSurface(this, input, executor));
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

/// Mutable default implementation of [CarpenterCommand] with observable state.
///
/// The controller prevents hidden, disabled, and concurrent invocations, records
/// execution/failure state, and delegates successful work to the supplied callback.
final class CarpenterCommandController<I>
    extends ValueNotifier<CarpenterCommandState>
    implements CarpenterCommand<I> {
  /// Creates a command controller with stable metadata, optional platform shortcuts,
  /// semantic effects, and an optional execution callback.
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

  /// Stable semantic identifier for this command.
  @override
  final String id;

  /// Human-readable action title.
  @override
  final String title;

  /// Logical discovery/organization group; defaults to `General`.
  @override
  final String group;

  /// Optional longer description of the command intent.
  @override
  final String? description;

  /// Default shortcut activators.
  @override
  final List<ShortcutActivator> shortcuts;

  /// Optional macOS-specific shortcut override.
  @override
  final List<ShortcutActivator>? macOSShortcuts;

  /// Optional Windows-specific shortcut override.
  @override
  final List<ShortcutActivator>? windowsShortcuts;

  /// Optional Linux-specific shortcut override.
  @override
  final List<ShortcutActivator>? linuxShortcuts;

  /// Optional iOS-specific shortcut override.
  @override
  final List<ShortcutActivator>? iOSShortcuts;

  /// Optional Android-specific shortcut override.
  @override
  final List<ShortcutActivator>? androidShortcuts;

  /// Optional Fuchsia-specific shortcut override.
  @override
  final List<ShortcutActivator>? fuchsiaShortcuts;

  /// Semantic presentation preference used when projecting this command into actions.
  @override
  final CarpenterCommandPresentation presentation;

  /// Semantic application effects declared by this command.
  @override
  final List<CarpenterCommandEffect> effects;
  final FutureOr<CarpenterCommandResult> Function(I input) _execute;

  /// This controller itself is the observable command-state listenable.
  @override
  ValueListenable<CarpenterCommandState> get state => this;

  /// Replaces visibility/enabled state and its optional disabled reason without starting
  /// or cancelling execution.
  void setAvailability({
    CarpenterCommandVisibility visibility = CarpenterCommandVisibility.visible,
    required bool enabled,
    String? disabledReason,
  }) {
    value = value.copyWith(
      visibility: visibility,
      enabled: enabled,
      disabledReason: disabledReason,
      clearDisabledReason: disabledReason == null,
    );
  }

  /// Executes the configured callback for [input].
  ///
  /// Throws [StateError] when hidden, disabled, or already executing; transitions to
  /// `executing`, then back to `idle` on success or `failed` with the original error.
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

/// Inherited registry of commands available to descendant application surfaces.
final class CarpenterCommandScope extends InheritedWidget {
  /// Creates a command registry boundary around [child].
  const CarpenterCommandScope({
    super.key,
    required this.commands,
    required super.child,
  });

  /// Commands exposed to descendants in caller-provided order.
  final List<CarpenterCommand<dynamic>> commands;

  /// Returns the nearest command scope, or `null` when absent.
  static CarpenterCommandScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarpenterCommandScope>();

  /// Returns the nearest command scope and asserts in debug mode when absent.
  static CarpenterCommandScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No CarpenterCommandScope found in context.');
    return scope!;
  }

  /// Finds the first registered command whose stable [CarpenterCommand.id] equals [id],
  /// or returns `null`.
  CarpenterCommand<dynamic>? find(String id) {
    for (final command in commands) {
      if (command.id == id) return command;
    }
    return null;
  }

  /// Notifies dependents when the registered command list changes by [listEquals].
  @override
  bool updateShouldNotify(CarpenterCommandScope oldWidget) =>
      !listEquals(commands, oldWidget.commands);
}

/// Binds a command to the concrete input and optional shortcuts used by a surface.
final class CarpenterCommandBinding<I> {
  /// Creates a binding from [command] and [input], optionally overriding its shortcuts.
  const CarpenterCommandBinding({
    required this.command,
    required this.input,
    this.shortcuts,
  });

  /// Command invoked by this binding.
  final CarpenterCommand<I> command;

  /// Input supplied when the bound command is invoked.
  final I input;

  /// Shortcut activators for this binding, or `null` to use the command defaults.
  final List<ShortcutActivator>? shortcuts;
}

final class _CarpenterCommandIntent extends Intent {
  const _CarpenterCommandIntent(this.invoke);
  final Future<void> Function() invoke;
}

/// Installs Flutter [Shortcuts] and [Actions] for caller-provided command bindings.
///
/// Disabled or hidden commands are not bound. Surface execution consumes failures
/// after command state/execution policy has recorded them.
final class CarpenterCommandShortcutScope extends StatelessWidget {
  /// Creates a shortcut scope around [child] for the supplied [bindings].
  const CarpenterCommandShortcutScope({
    super.key,
    required this.bindings,
    required this.child,
  });

  /// Command/input bindings used to build the shortcut map.
  final List<CarpenterCommandBinding<dynamic>> bindings;

  /// Descendant subtree receiving the generated Flutter shortcut/action mapping.
  final Widget child;

  /// Builds shortcut mappings from currently visible/enabled bindings and uses the
  /// nearest command executor when one is available.
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
        shortcuts[activator] = _CarpenterCommandIntent(
          () => _executeCommandForSurface(
            binding.command,
            binding.input,
            executor,
          ),
        );
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

/// Reactive Carpenter button that projects one command and input into a standard action.
final class CarpenterCommandButton<I> extends StatelessWidget {
  /// Creates a command-backed button for [command] and concrete [input].
  const CarpenterCommandButton({
    super.key,
    required this.command,
    required this.input,
  });

  /// Command whose state, title, presentation, and execution drive the button.
  final CarpenterCommand<I> command;

  /// Input supplied when the command-backed button is activated.
  final I input;

  /// Rebuilds from command state, hides the button for hidden commands, and maps
  /// execution state to Carpenter's standard action phase.
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<CarpenterCommandState>(
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
          executor: CarpenterCommandExecutionScope.maybeOf(context)?.executor,
        ),
        prominence: presentation == CarpenterCommandPresentation.primary
            ? ActionProminence.high
            : ActionProminence.outlined,
        executionPhase: switch (state.execution) {
          CarpenterCommandExecution.idle => ActionExecutionPhase.idle,
          CarpenterCommandExecution.executing => ActionExecutionPhase.running,
          CarpenterCommandExecution.failed => ActionExecutionPhase.failed,
        },
      );
    },
  );
}
