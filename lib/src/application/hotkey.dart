import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/card.dart';
import '../components/basic/status_indicator.dart';
import '../components/basic/text.dart';
import '../foundation/roles.dart';
import 'command.dart';

import 'package:carpenter_units/carpenter_units.dart';

extension CarpenterCommandPlatformShortcuts on CarpenterCommand<dynamic> {
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

enum CarpenterHotkeyPhase { down, repeat, up }

@immutable
final class CarpenterHotkeySnapshot {
  const CarpenterHotkeySnapshot({
    required this.logicalKeys,
    required this.physicalKeys,
    this.lastLogicalKey,
    this.lastPhysicalKey,
    this.phase,
  });

  static const empty = CarpenterHotkeySnapshot(
    logicalKeys: {},
    physicalKeys: {},
  );
  final Set<LogicalKeyboardKey> logicalKeys;
  final Set<PhysicalKeyboardKey> physicalKeys;
  final LogicalKeyboardKey? lastLogicalKey;
  final PhysicalKeyboardKey? lastPhysicalKey;
  final CarpenterHotkeyPhase? phase;
  bool get hasPressedKeys => logicalKeys.isNotEmpty;
}

final class CarpenterHotkeyController extends ChangeNotifier {
  CarpenterHotkeySnapshot _snapshot = CarpenterHotkeySnapshot.empty;
  CarpenterHotkeySnapshot get snapshot => _snapshot;

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

  void clear() => setSnapshot(CarpenterHotkeySnapshot.empty);
}

final class CarpenterHotkeyFormatter {
  const CarpenterHotkeyFormatter({required this.platform});
  final TargetPlatform platform;

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

typedef CarpenterHotkeyCommandCallback = void Function(
  CarpenterCommand<void> command,
);

final class CarpenterHotkeyScope extends StatefulWidget {
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

  final Widget child;
  final List<CarpenterCommand<void>> commands;
  final CarpenterHotkeyCommandCallback? onCommand;
  final CarpenterHotkeyController? controller;
  final TargetPlatform? platform;
  final bool enabled;
  final bool trackPressedKeys;
  final bool autofocus;

  static _HotkeyBinding _bindingOf(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_HotkeyBinding>();
    assert(binding != null, 'No CarpenterHotkeyScope found in context.');
    return binding!;
  }

  static CarpenterHotkeySnapshot snapshotOf(BuildContext context) =>
      _bindingOf(context).controller.snapshot;
  static CarpenterHotkeyController controllerOf(BuildContext context) =>
      _bindingOf(context).controller;
  static List<CarpenterCommand<void>> commandsOf(BuildContext context) =>
      _bindingOf(context).commands;
  static CarpenterHotkeyFormatter formatterOf(BuildContext context) =>
      _bindingOf(context).formatter;

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

final class CarpenterHotkeyDisplay extends StatelessWidget {
  const CarpenterHotkeyDisplay({
    super.key,
    this.title = 'Hotkeys',
    this.showCommands = true,
  });
  final String title;
  final bool showCommands;

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
