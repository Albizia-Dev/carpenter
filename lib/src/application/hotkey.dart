import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/card.dart';
import '../components/basic/status_indicator.dart';
import '../components/basic/text.dart';
import '../foundation/roles.dart';
import 'command.dart';
import 'package:carpenter_units/carpenter_units.dart';

/// Selects and normalizes a command shortcut set for a concrete target platform.
extension CarpenterCommandPlatformShortcuts on CarpenterCommand<dynamic> {
  /// Selects the most specific shortcut list for `platform`; Apple platforms
  /// additionally normalize control modifiers to command/meta semantics.
  List<ShortcutActivator> shortcutsFor(TargetPlatform platform) {
    final selected = switch (platform) {
      TargetPlatform.macOS => macOSShortcuts ?? shortcuts,
      TargetPlatform.windows => windowsShortcuts ?? shortcuts,
      TargetPlatform.linux => linuxShortcuts ?? shortcuts,
      TargetPlatform.iOS => iOSShortcuts ?? macOSShortcuts ?? shortcuts,
      TargetPlatform.android => androidShortcuts ?? shortcuts,
      TargetPlatform.fuchsia => fuchsiaShortcuts ?? shortcuts,
    };
    if (platform != TargetPlatform.macOS && platform != TargetPlatform.iOS)
      return selected;
    return selected.map(_macOSActivator).toList(growable: false);
  }
}

ShortcutActivator _macOSActivator(ShortcutActivator activator) {
  if (activator is! SingleActivator) return activator;
  return SingleActivator(
    activator.trigger,
    control: false,
    shift: activator.shift,
    alt: activator.alt,
    meta: activator.meta || activator.control,
    includeRepeats: activator.includeRepeats,
  );
}

/// Identifies the hardware-key event phase captured in a hotkey snapshot.
enum CarpenterHotkeyPhase {
  /// A physical key transitioned from released to pressed.
  down,

  /// A held key emitted a repeat event.
  repeat,

  /// A physical key transitioned from pressed to released.
  up,
}

/// Immutable snapshot of currently pressed logical and physical keys plus the most
/// recent key event and phase.
@immutable
final class CarpenterHotkeySnapshot {
  /// Creates an immutable logical/physical pressed-key snapshot with optional
  /// most-recent keys and phase.
  const CarpenterHotkeySnapshot({
    required this.logicalKeys,
    required this.physicalKeys,
    this.lastLogicalKey,
    this.lastPhysicalKey,
    this.phase,
  });

  /// Canonical snapshot with no pressed logical or physical keys.
  static const empty = CarpenterHotkeySnapshot(
    logicalKeys: {},
    physicalKeys: {},
  );

  /// Logical keyboard keys currently reported as pressed.
  final Set<LogicalKeyboardKey> logicalKeys;

  /// Physical keyboard keys currently reported as pressed.
  final Set<PhysicalKeyboardKey> physicalKeys;

  /// Logical key from the most recently observed hardware-key event, if any.
  final LogicalKeyboardKey? lastLogicalKey;

  /// Physical key from the most recently observed hardware-key event, if any.
  final PhysicalKeyboardKey? lastPhysicalKey;

  /// Phase of the most recently observed hardware-key event, if any.
  final CarpenterHotkeyPhase? phase;

  /// Whether at least one logical key is currently pressed.
  bool get hasPressedKeys => logicalKeys.isNotEmpty;
}

/// Change-notifier owner for the latest pressed-key snapshot observed by a hotkey
/// scope.
final class CarpenterHotkeyController extends ChangeNotifier {
  CarpenterHotkeySnapshot _snapshot = CarpenterHotkeySnapshot.empty;

  /// Latest immutable pressed-key snapshot owned by this controller.
  CarpenterHotkeySnapshot get snapshot => _snapshot;

  /// Stores a defensive immutable copy of the supplied pressed-key sets and notifies
  /// listeners.
  void setSnapshot(CarpenterHotkeySnapshot value) {
    _snapshot = CarpenterHotkeySnapshot(
      logicalKeys: Set.unmodifiable(value.logicalKeys),
      physicalKeys: Set.unmodifiable(value.physicalKeys),
      lastLogicalKey: value.lastLogicalKey,
      lastPhysicalKey: value.lastPhysicalKey,
      phase: value.phase,
    );
    notifyListeners();
  }

  /// Replaces the current state with [CarpenterHotkeySnapshot.empty] and notifies
  /// listeners.
  void clear() => setSnapshot(CarpenterHotkeySnapshot.empty);
}

/// Formats shortcut activators and pressed logical keys using platform-appropriate
/// modifier names and separators.
final class CarpenterHotkeyFormatter {
  /// Creates a key formatter for `platform`.
  const CarpenterHotkeyFormatter({required this.platform});

  /// Target platform used for platform-sensitive Carpenter behavior.
  final TargetPlatform platform;

  /// Formats a shortcut activator for display, using platform-specific modifier names
  /// and compact Apple glyph notation where applicable.
  String formatActivator(ShortcutActivator activator) {
    if (activator is! SingleActivator) return activator.debugDescribeKeys();
    final parts = <String>[
      if (activator.meta) _meta,
      if (activator.control) _control,
      if (activator.alt) _alt,
      if (activator.shift) _shift,
      _key(activator.trigger),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(_separator);
  }

  /// Formats pressed logical keys in iteration order using the same platform-specific
  /// key naming as shortcut activators.
  String formatPressedKeys(Iterable<LogicalKeyboardKey> keys) =>
      keys.map(_key).where((value) => value.isNotEmpty).join(_separator);

  bool get _apple =>
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  String get _separator => _apple ? '' : '+';
  String get _meta => _apple
      ? '⌘'
      : platform == TargetPlatform.linux
      ? 'Super'
      : 'Win';
  String get _control => _apple ? '⌃' : 'Ctrl';
  String get _alt => _apple ? '⌥' : 'Alt';
  String get _shift => _apple ? '⇧' : 'Shift';

  String _key(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight)
      return _meta;
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight)
      return _control;
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight)
      return _alt;
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight)
      return _shift;
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    final label = key.keyLabel;
    return label.length == 1
        ? label.toUpperCase()
        : label.isNotEmpty
        ? label
        : key.debugName ?? '';
  }
}

final class _HotkeyIntent extends Intent {
  const _HotkeyIntent(this.command);
  final CarpenterCommand<void> command;
}

/// Observes a command immediately before a hotkey scope invokes it.
typedef CarpenterHotkeyCommandCallback =
    void Function(CarpenterCommand<void> command);

/// Keyboard interaction scope that installs command shortcuts, optionally tracks
/// pressed keys, and exposes hotkey state to descendants.
final class CarpenterHotkeyScope extends StatefulWidget {
  /// Creates a hotkey scope. Commands are empty and tracking/autofocus are enabled by
  /// default; supplying a controller leaves its lifecycle with the caller.
  const CarpenterHotkeyScope({
    super.key,
    required this.child,
    this.commands = const [],
    this.onCommand,
    this.controller,
    this.platform,
    this.enabled = true,
    this.trackPressedKeys = true,
    this.autofocus = true,
  });

  /// Content wrapped by this hotkey interaction scope.
  final Widget child;

  /// Commands exposed to shortcuts and diagnostic descendants.
  final List<CarpenterCommand<void>> commands;

  /// Optional callback notified before a command is invoked by the hotkey surface.
  final CarpenterHotkeyCommandCallback? onCommand;

  /// Optional externally owned controller; when omitted the scope creates and owns one.
  final CarpenterHotkeyController? controller;

  /// Target platform used for platform-sensitive shortcut selection and formatting.
  final TargetPlatform? platform;

  /// Whether this hotkey scope installs shortcuts and reacts to hardware-key events.
  /// When false, descendants remain mounted but no command shortcuts are bound.
  final bool enabled;

  /// Whether the active hotkey scope records the current hardware key set for
  /// diagnostics or UI.
  final bool trackPressedKeys;

  /// Whether the hotkey focus node requests focus automatically when the scope is
  /// built.
  final bool autofocus;

  static _HotkeyBinding _bindingOf(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_HotkeyBinding>();
    assert(binding != null, 'No CarpenterHotkeyScope found in context.');
    return binding!;
  }

  /// Returns the latest hotkey snapshot from the nearest scope and establishes an
  /// inherited dependency.
  static CarpenterHotkeySnapshot snapshotOf(BuildContext context) =>
      _bindingOf(context).controller.snapshot;

  /// Returns the controller owned or supplied by the nearest hotkey scope.
  static CarpenterHotkeyController controllerOf(BuildContext context) =>
      _bindingOf(context).controller;

  /// Returns the command list exposed by the nearest hotkey scope.
  static List<CarpenterCommand<void>> commandsOf(BuildContext context) =>
      _bindingOf(context).commands;

  /// Returns the platform-aware formatter exposed by the nearest hotkey scope.
  static CarpenterHotkeyFormatter formatterOf(BuildContext context) =>
      _bindingOf(context).formatter;

  /// Creates the state object that owns hardware-key observation and an internal
  /// controller when no controller is supplied.
  @override
  State<CarpenterHotkeyScope> createState() => _CarpenterHotkeyScopeState();
}

final class _CarpenterHotkeyScopeState extends State<CarpenterHotkeyScope> {
  late CarpenterHotkeyController _controller =
      widget.controller ?? CarpenterHotkeyController();
  late bool _ownsController = widget.controller == null;
  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(CarpenterHotkeyScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? CarpenterHotkeyController();
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled || !widget.trackPressedKeys) return false;
    final phase = switch (event) {
      KeyDownEvent() => CarpenterHotkeyPhase.down,
      KeyRepeatEvent() => CarpenterHotkeyPhase.repeat,
      KeyUpEvent() => CarpenterHotkeyPhase.up,
      _ => null,
    };
    _controller.setSnapshot(
      CarpenterHotkeySnapshot(
        logicalKeys: HardwareKeyboard.instance.logicalKeysPressed,
        physicalKeys: HardwareKeyboard.instance.physicalKeysPressed,
        lastLogicalKey: event.logicalKey,
        lastPhysicalKey: event.physicalKey,
        phase: phase,
      ),
    );
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{};
    for (final command in widget.commands) {
      final state = command.state.value;
      if (!widget.enabled ||
          !state.enabled ||
          state.visibility == CarpenterCommandVisibility.hidden)
        continue;
      for (final activator in command.shortcutsFor(_platform)) {
        shortcuts[activator] = _HotkeyIntent(command);
      }
    }
    return Actions(
      actions: <Type, Action<Intent>>{
        _HotkeyIntent: CallbackAction<_HotkeyIntent>(
          onInvoke: (intent) {
            widget.onCommand?.call(intent.command);
            return intent.command.execute(null);
          },
        ),
      },
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Focus(
          autofocus: widget.autofocus,
          child: _HotkeyBinding(
            controller: _controller,
            commands: widget.commands,
            formatter: CarpenterHotkeyFormatter(platform: _platform),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

final class _HotkeyBinding
    extends InheritedNotifier<CarpenterHotkeyController> {
  const _HotkeyBinding({
    required this.controller,
    required this.commands,
    required this.formatter,
    required super.child,
  }) : super(notifier: controller);
  final CarpenterHotkeyController controller;
  final List<CarpenterCommand<void>> commands;
  final CarpenterHotkeyFormatter formatter;

  @override
  bool updateShouldNotify(_HotkeyBinding oldWidget) =>
      controller != oldWidget.controller ||
      commands != oldWidget.commands ||
      formatter.platform != oldWidget.formatter.platform ||
      super.updateShouldNotify(oldWidget);
}

/// Diagnostic Carpenter surface that renders the current pressed-key state and
/// optionally lists active command shortcuts.
final class CarpenterHotkeyDisplay extends StatelessWidget {
  /// Creates a diagnostic hotkey display with the default `Hotkeys` title and command
  /// listing enabled.
  const CarpenterHotkeyDisplay({
    super.key,
    this.title = 'Hotkeys',
    this.showCommands = true,
  });

  /// Human-readable heading displayed above the hotkey diagnostics.
  final String title;

  /// Whether the diagnostic hotkey display includes the configured command/shortcut
  /// list.
  final bool showCommands;

  /// Builds the diagnostic hotkey card from the nearest scope snapshot, formatter, and
  /// optional command list.
  @override
  Widget build(BuildContext context) {
    final snapshot = CarpenterHotkeyScope.snapshotOf(context);
    final commands = CarpenterHotkeyScope.commandsOf(context);
    final formatter = CarpenterHotkeyScope.formatterOf(context);
    final pressed = snapshot.hasPressedKeys
        ? formatter.formatPressedKeys(snapshot.logicalKeys)
        : 'Nothing pressed';
    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.title(title),
          SizedBox(height: context.units(.5.rem)),
          Wrap(
            spacing: context.units(.5.rem),
            runSpacing: context.units(.5.rem),
            children: [
              CarpenterStatusIndicator(
                label: pressed,
                role: FeedbackColorRole.info,
              ),
              if (snapshot.phase != null)
                CarpenterStatusIndicator(
                  label: snapshot.phase!.name,
                  role: FeedbackColorRole.neutral,
                ),
            ],
          ),
          if (showCommands && commands.isNotEmpty) ...[
            SizedBox(height: context.units(.75.rem)),
            for (final command in commands)
              Padding(
                padding: EdgeInsets.only(bottom: context.units(.375.rem)),
                child: CarpenterText.body(
                  '${command.title}  ${command.shortcutsFor(formatter.platform).map(formatter.formatActivator).join(' / ')}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
