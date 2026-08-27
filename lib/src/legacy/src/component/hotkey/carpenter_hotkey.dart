import 'package:carpenter/src/components/basic/card.dart';
import 'package:carpenter/src/components/basic/text.dart';
import 'package:carpenter/src/legacy/src/component/tag/carpenter_tag.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Фаза последнего события клавиатуры.
enum CarpenterHotkeyPhase {
  /// Клавиша нажата впервые.
  down,

  /// Клавиша удерживается и система прислала повтор.
  repeat,

  /// Клавиша отпущена.
  up,
}

/// Снимок текущего состояния клавиатуры внутри Carpenter.
///
/// `logicalKeys` и `physicalKeys` показывают клавиши, которые Flutter сейчас
/// считает зажатыми. `lastLogicalKey` и `lastPhysicalKey` сохраняют последнюю
/// клавишу события даже после отпускания, чтобы debug-страницы могли показать,
/// что только что произошло.
class CarpenterHotkeySnapshot {
  /// Создает снимок клавиатуры.
  const CarpenterHotkeySnapshot({
    required this.logicalKeys,
    required this.physicalKeys,
    this.lastLogicalKey,
    this.lastPhysicalKey,
    this.phase,
  });

  /// Пустой снимок без зажатых клавиш.
  static const empty = CarpenterHotkeySnapshot(
    logicalKeys: {},
    physicalKeys: {},
  );

  /// Сейчас зажатые logical keys.
  final Set<LogicalKeyboardKey> logicalKeys;

  /// Сейчас зажатые physical keys.
  final Set<PhysicalKeyboardKey> physicalKeys;

  /// Logical key последнего события.
  final LogicalKeyboardKey? lastLogicalKey;

  /// Physical key последнего события.
  final PhysicalKeyboardKey? lastPhysicalKey;

  /// Фаза последнего события.
  final CarpenterHotkeyPhase? phase;

  /// Есть ли сейчас зажатые клавиши.
  bool get hasPressedKeys => logicalKeys.isNotEmpty;

  /// Возвращает копию снимка с неизменяемыми наборами клавиш.
  CarpenterHotkeySnapshot normalized() {
    return CarpenterHotkeySnapshot(
      logicalKeys: Set<LogicalKeyboardKey>.unmodifiable(logicalKeys),
      physicalKeys: Set<PhysicalKeyboardKey>.unmodifiable(physicalKeys),
      lastLogicalKey: lastLogicalKey,
      lastPhysicalKey: lastPhysicalKey,
      phase: phase,
    );
  }
}

/// Transitional source-compatible name for the unified command model.
///
/// Hotkeys are presentation bindings of [CarpenterCommand], not a second
/// business-action abstraction.
typedef CarpenterHotkeyCommand = CarpenterCommandController<void>;

extension CarpenterCommandPlatformShortcuts on CarpenterCommand<dynamic> {
  /// Returns the command shortcuts resolved for one target platform.
  List<ShortcutActivator> shortcutsFor(TargetPlatform platform) {
    final selected = switch (platform) {
      TargetPlatform.macOS => macOSShortcuts ?? shortcuts,
      TargetPlatform.windows => windowsShortcuts ?? shortcuts,
      TargetPlatform.linux => linuxShortcuts ?? shortcuts,
      TargetPlatform.iOS => iOSShortcuts ?? macOSShortcuts ?? shortcuts,
      TargetPlatform.android => androidShortcuts ?? shortcuts,
      TargetPlatform.fuchsia => fuchsiaShortcuts ?? shortcuts,
    };
    if (platform != TargetPlatform.macOS && platform != TargetPlatform.iOS) {
      return selected;
    }
    return selected.map(_macOSActivator).toList(growable: false);
  }

  /// Compatibility spelling retained during the command-model migration.
  List<ShortcutActivator> activatorsFor(TargetPlatform platform) =>
      shortcutsFor(platform);
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

/// Intent, который прокидывает выбранную Carpenter-команду в Actions.
class CarpenterHotkeyIntent extends Intent {
  /// Создает intent для команды.
  const CarpenterHotkeyIntent(this.command);

  /// Команда, найденная через `Shortcuts`.
  final CarpenterCommand<void> command;
}

/// Callback выполнения hotkey-команды.
typedef CarpenterHotkeyCommandCallback =
    void Function(CarpenterCommand<void> command);

/// Контроллер состояния клавиатуры.
///
/// Его можно передать в `CarpenterHotkeyScope`, если нужно читать состояние
/// вне widget tree или синхронизировать несколько панелей отображения.
class CarpenterHotkeyController extends ChangeNotifier {
  CarpenterHotkeySnapshot _snapshot = CarpenterHotkeySnapshot.empty;

  /// Текущий снимок зажатых клавиш.
  CarpenterHotkeySnapshot get snapshot => _snapshot;

  void _setSnapshot(CarpenterHotkeySnapshot value) {
    final normalized = value.normalized();
    if (_sameSnapshot(_snapshot, normalized)) {
      return;
    }
    _snapshot = normalized;
    notifyListeners();
  }

  /// Сбрасывает состояние зажатых клавиш.
  void clear() {
    _setSnapshot(CarpenterHotkeySnapshot.empty);
  }

  bool _sameSnapshot(
    CarpenterHotkeySnapshot left,
    CarpenterHotkeySnapshot right,
  ) {
    return setEquals(left.logicalKeys, right.logicalKeys) &&
        setEquals(left.physicalKeys, right.physicalKeys) &&
        left.lastLogicalKey == right.lastLogicalKey &&
        left.lastPhysicalKey == right.lastPhysicalKey &&
        left.phase == right.phase;
  }
}

/// Форматтер hotkey-комбинаций под платформу.
///
/// macOS получает символы `⌘`, `⌥`, `⌃`, `⇧`, а Windows/Linux - привычные
/// текстовые модификаторы. Сам форматтер не зависит от `BuildContext`, поэтому
/// его удобно тестировать и переиспользовать в документации.
class CarpenterHotkeyFormatter {
  /// Создает форматтер для платформы.
  const CarpenterHotkeyFormatter({required this.platform});

  /// Платформа, под которую форматируются подписи.
  final TargetPlatform platform;

  /// Форматирует набор сейчас зажатых logical keys.
  String formatPressedKeys(Iterable<LogicalKeyboardKey> keys) {
    final sorted = keys.toList()
      ..sort((a, b) {
        final rank = _modifierRank(a).compareTo(_modifierRank(b));
        if (rank != 0) {
          return rank;
        }
        return _keyLabel(a).compareTo(_keyLabel(b));
      });

    final labels = <String>[];
    for (final key in sorted) {
      final label = _keyLabel(key);
      if (label.isNotEmpty && !labels.contains(label)) {
        labels.add(label);
      }
    }

    return labels.join(_separator);
  }

  /// Форматирует `ShortcutActivator` из Flutter Shortcuts.
  String formatActivator(ShortcutActivator activator) {
    if (activator is SingleActivator) {
      final labels = <String>[
        if (activator.meta) _metaLabel,
        if (activator.control) _controlLabel,
        if (activator.alt) _altLabel,
        if (activator.shift) _shiftLabel,
        _keyLabel(activator.trigger),
      ];

      return labels.where((label) => label.isNotEmpty).join(_separator);
    }

    return activator.debugDescribeKeys();
  }

  String get _separator {
    return platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? ''
        : '+';
  }

  String get _metaLabel {
    return switch (platform) {
      TargetPlatform.macOS || TargetPlatform.iOS => '⌘',
      TargetPlatform.linux => 'Super',
      _ => 'Win',
    };
  }

  String get _controlLabel {
    return platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? '⌃'
        : 'Ctrl';
  }

  String get _altLabel {
    return platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? '⌥'
        : 'Alt';
  }

  String get _shiftLabel {
    return platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? '⇧'
        : 'Shift';
  }

  int _modifierRank(LogicalKeyboardKey key) {
    if (_isMeta(key)) {
      return 0;
    }
    if (_isControl(key)) {
      return 1;
    }
    if (_isAlt(key)) {
      return 2;
    }
    if (_isShift(key)) {
      return 3;
    }
    return 4;
  }

  String _keyLabel(LogicalKeyboardKey key) {
    if (_isMeta(key)) {
      return _metaLabel;
    }
    if (_isControl(key)) {
      return _controlLabel;
    }
    if (_isAlt(key)) {
      return _altLabel;
    }
    if (_isShift(key)) {
      return _shiftLabel;
    }

    if (key == LogicalKeyboardKey.enter) {
      return 'Enter';
    }
    if (key == LogicalKeyboardKey.escape) {
      return 'Esc';
    }
    if (key == LogicalKeyboardKey.tab) {
      return 'Tab';
    }
    if (key == LogicalKeyboardKey.space) {
      return 'Space';
    }
    if (key == LogicalKeyboardKey.backspace) {
      return 'Backspace';
    }
    if (key == LogicalKeyboardKey.delete) {
      return 'Delete';
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      return '↑';
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return '→';
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return '↓';
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return '←';
    }

    final label = key.keyLabel;
    if (label.length == 1) {
      return label.toUpperCase();
    }
    if (label.isNotEmpty) {
      return label;
    }
    return key.debugName ?? key.keyId.toRadixString(16);
  }

  bool _isMeta(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  bool _isControl(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;
  }

  bool _isAlt(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight;
  }

  bool _isShift(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight;
  }
}

/// Scope hotkey-системы Carpenter.
///
/// Компонент делает три вещи:
/// - регистрирует команды как Flutter `Shortcuts`;
/// - прокидывает их в один универсальный `CarpenterHotkeyIntent`;
/// - пассивно отслеживает текущее состояние клавиатуры через
///   `HardwareKeyboard`, не перехватывая события у вложенных widgets.
class CarpenterHotkeyScope extends StatefulWidget {
  /// Создает hotkey scope.
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

  /// Дочернее дерево, где работают shortcuts и мониторинг клавиатуры.
  final Widget child;

  /// Команды, доступные на этой ветке дерева.
  final List<CarpenterCommand<void>> commands;

  /// Callback для найденной команды. Это будущая точка подключения роутинга.
  final CarpenterHotkeyCommandCallback? onCommand;

  /// Внешний контроллер состояния клавиатуры.
  final CarpenterHotkeyController? controller;

  /// Платформа для выбора комбинаций и форматирования.
  final TargetPlatform? platform;

  /// Включены ли shortcuts и мониторинг.
  final bool enabled;

  /// Нужно ли отслеживать текущие зажатые клавиши.
  final bool trackPressedKeys;

  /// Запрашивать ли фокус для hotkey-ветки при первом показе.
  final bool autofocus;

  /// Возвращает текущий снимок клавиатуры и подписывает widget на обновления.
  static CarpenterHotkeySnapshot snapshotOf(BuildContext context) {
    return _bindingOf(context).controller.snapshot;
  }

  /// Возвращает контроллер scope без подписки на обновления.
  static CarpenterHotkeyController controllerOf(BuildContext context) {
    final binding = context
        .getInheritedWidgetOfExactType<_CarpenterHotkeyBinding>();
    assert(binding != null, 'No CarpenterHotkeyScope found in context.');
    return binding!.controller;
  }

  /// Возвращает команды ближайшего hotkey scope.
  static List<CarpenterCommand<void>> commandsOf(BuildContext context) {
    return _bindingOf(context).commands;
  }

  /// Возвращает платформенный форматтер ближайшего hotkey scope.
  static CarpenterHotkeyFormatter formatterOf(BuildContext context) {
    return _bindingOf(context).formatter;
  }

  static _CarpenterHotkeyBinding _bindingOf(BuildContext context) {
    final binding = context
        .dependOnInheritedWidgetOfExactType<_CarpenterHotkeyBinding>();
    assert(binding != null, 'No CarpenterHotkeyScope found in context.');
    return binding!;
  }

  @override
  State<CarpenterHotkeyScope> createState() => _CarpenterHotkeyScopeState();
}

class _CarpenterHotkeyScopeState extends State<CarpenterHotkeyScope> {
  late CarpenterHotkeyController _controller;
  late bool _ownsController;

  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CarpenterHotkeyController();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void didUpdateWidget(CarpenterHotkeyScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? CarpenterHotkeyController();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled || !widget.trackPressedKeys) {
      return false;
    }

    final phase = switch (event) {
      KeyDownEvent() => CarpenterHotkeyPhase.down,
      KeyRepeatEvent() => CarpenterHotkeyPhase.repeat,
      KeyUpEvent() => CarpenterHotkeyPhase.up,
      _ => null,
    };

    _controller._setSnapshot(
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
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{};
    for (final command in widget.commands) {
      final state = command.state.value;
      if (!widget.enabled ||
          !state.enabled ||
          state.visibility == CarpenterCommandVisibility.hidden) {
        continue;
      }
      for (final activator in command.shortcutsFor(_platform)) {
        shortcuts[activator] = CarpenterHotkeyIntent(command);
      }
    }

    return Actions(
      actions: <Type, Action<Intent>>{
        CarpenterHotkeyIntent: CallbackAction<CarpenterHotkeyIntent>(
          onInvoke: (intent) {
            if (!widget.commands.contains(intent.command)) {
              return Actions.maybeInvoke(context, intent);
            }
            widget.onCommand?.call(intent.command);
            return intent.command;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Focus(
          autofocus: widget.autofocus,
          child: _CarpenterHotkeyBinding(
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

class _CarpenterHotkeyBinding
    extends InheritedNotifier<CarpenterHotkeyController> {
  const _CarpenterHotkeyBinding({
    required this.controller,
    required this.commands,
    required this.formatter,
    required super.child,
  }) : super(notifier: controller);

  final CarpenterHotkeyController controller;
  final List<CarpenterCommand<void>> commands;
  final CarpenterHotkeyFormatter formatter;

  @override
  bool updateShouldNotify(_CarpenterHotkeyBinding oldWidget) {
    return controller != oldWidget.controller ||
        commands != oldWidget.commands ||
        formatter.platform != oldWidget.formatter.platform ||
        super.updateShouldNotify(oldWidget);
  }
}

/// Debug/help-панель hotkey-состояния.
///
/// Виджет показывает текущую зажатую комбинацию, последнюю клавишу и список
/// зарегистрированных команд. Его можно положить в example, settings, command
/// palette или временную debug-страницу.
class CarpenterHotkeyDisplay extends StatelessWidget {
  /// Создает панель отображения hotkeys.
  const CarpenterHotkeyDisplay({
    super.key,
    this.title = 'Hotkeys',
    this.emptyLabel = 'Nothing pressed',
    this.showCommands = true,
  });

  /// Заголовок панели.
  final String title;

  /// Текст, когда клавиши не зажаты.
  final String emptyLabel;

  /// Показывать ли команды из ближайшего `CarpenterHotkeyScope`.
  final bool showCommands;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final snapshot = CarpenterHotkeyScope.snapshotOf(context);
    final commands = CarpenterHotkeyScope.commandsOf(context);
    final formatter = CarpenterHotkeyScope.formatterOf(context);
    final pressedLabel = snapshot.hasPressedKeys
        ? formatter.formatPressedKeys(snapshot.logicalKeys)
        : emptyLabel;
    final lastLabel = snapshot.lastLogicalKey == null
        ? 'none'
        : formatter.formatPressedKeys([snapshot.lastLogicalKey!]);
    final phaseLabel = switch (snapshot.phase) {
      CarpenterHotkeyPhase.down => 'down',
      CarpenterHotkeyPhase.repeat => 'repeat',
      CarpenterHotkeyPhase.up => 'up',
      null => 'idle',
    };

    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText(title, role: .title),
          SizedBox(height: face.space('1')),
          Wrap(
            spacing: face.space('0.75'),
            runSpacing: face.space('0.75'),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HotkeyValue(label: 'Pressed', value: pressedLabel),
              CarpenterTag(label: phaseLabel, tone: CarpenterTagTone.info),
              _HotkeyValue(label: 'Last', value: lastLabel),
            ],
          ),
          if (showCommands && commands.isNotEmpty) ...[
            SizedBox(height: face.space('1.5')),
            CarpenterText(
              'Registered commands',
              role: .label,
              emphasis: .strong,
            ),
            SizedBox(height: face.space('0.75')),
            ..._commandRows(context, commands, formatter),
          ],
        ],
      ),
    );
  }

  List<Widget> _commandRows(
    BuildContext context,
    List<CarpenterCommand<void>> commands,
    CarpenterHotkeyFormatter formatter,
  ) {
    final face = context.face;
    final rows = <Widget>[];
    String? group;

    for (final command in commands) {
      if (group != command.group) {
        group = command.group;
        if (rows.isNotEmpty) {
          rows.add(SizedBox(height: face.space('0.75')));
        }
        rows.add(CarpenterText(group, role: .label));
        rows.add(SizedBox(height: face.space('0.375')));
      }

      rows.add(_HotkeyCommandRow(command: command, formatter: formatter));
      rows.add(SizedBox(height: face.space('0.5')));
    }

    if (rows.isNotEmpty) {
      rows.removeLast();
    }
    return rows;
  }
}

class _HotkeyValue extends StatelessWidget {
  const _HotkeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final face = context.face;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: face.color('surface.muted'),
        border: Border.all(color: face.color('border.subtle')),
        borderRadius: BorderRadius.circular(face.radius('md')),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: face.space('0.75'),
          vertical: face.space('0.5'),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterText(label, role: .caption, colorRole: .secondary),
            SizedBox(width: face.space('0.5')),
            CarpenterText(value, role: .label, emphasis: .strong),
          ],
        ),
      ),
    );
  }
}

class _HotkeyCommandRow extends StatelessWidget {
  const _HotkeyCommandRow({required this.command, required this.formatter});

  final CarpenterCommand<void> command;
  final CarpenterHotkeyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final activators = command.shortcutsFor(formatter.platform);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: face.color('border.subtle'))),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: face.space('0.5')),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarpenterText(command.title, role: .label, emphasis: .strong),
                  if (command.description != null) ...[
                    SizedBox(height: face.space('0.25')),
                    CarpenterText(
                      command.description!,
                      role: .caption,
                      colorRole: .secondary,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: face.space('1')),
            Wrap(
              spacing: face.space('0.375'),
              runSpacing: face.space('0.375'),
              alignment: WrapAlignment.end,
              children: [
                for (final activator in activators)
                  CarpenterTag(
                    label: formatter.formatActivator(activator),
                    tone: command.state.value.enabled
                        ? CarpenterTagTone.info
                        : CarpenterTagTone.neutral,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
