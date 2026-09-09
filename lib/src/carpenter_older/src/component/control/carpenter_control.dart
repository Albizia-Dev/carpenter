import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Состояние интерактивного primitive `CarpenterControl`.
///
/// Компоненты используют это состояние в builder, чтобы визуально реагировать
/// на доступность, hover, focus и pressed без дублирования pointer/keyboard
/// логики.
class CarpenterControlState {
  /// Создает снимок интерактивного состояния.
  const CarpenterControlState({
    required this.enabled,
    required this.hovered,
    required this.focused,
    required this.pressed,
  });

  /// Элемент доступен пользователю и может быть активирован.
  final bool enabled;

  /// Указатель находится над элементом.
  final bool hovered;

  /// Элемент находится в focus-highlight состоянии.
  final bool focused;

  /// Элемент сейчас нажат.
  final bool pressed;
}

/// Builder интерактивного primitive.
///
/// Получает `BuildContext` и текущее состояние control, а возвращает визуальное
/// представление компонента.
typedef CarpenterControlBuilder =
    Widget Function(BuildContext context, CarpenterControlState state);

/// Поведенческий primitive для интерактивных компонентов Carpenter.
///
/// `CarpenterControl` собирает semantics, focus, hover, pressed, pointer
/// gestures, keyboard activation и enabled state. Он не задает внешний вид:
/// визуальная часть приходит через `builder` и обычно читает `context.face`.
class CarpenterControl extends StatefulWidget {
  /// Создает интерактивную оболочку.
  const CarpenterControl({
    super.key,
    required this.builder,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.semanticButton = true,
    this.semanticChecked,
    this.semanticToggled,
    this.semanticSelected,
    this.semanticLink = false,
    this.cursor,
    this.focusNode,
    this.autofocus = false,
  });

  /// Builder визуальной части компонента.
  final CarpenterControlBuilder builder;

  /// Действие при активации pointer или keyboard.
  final VoidCallback? onTap;

  /// Явно включает или выключает control.
  final bool enabled;

  /// Семантическая подпись для accessibility.
  final String? semanticLabel;

  /// Помечает control как button в semantics-дереве.
  final bool semanticButton;

  /// Checked-состояние для checkbox/radio-like controls.
  final bool? semanticChecked;

  /// Toggled-состояние для switch-like controls.
  final bool? semanticToggled;

  /// Selected-состояние для selectable controls.
  final bool? semanticSelected;

  /// Помечает control как ссылку в semantics-дереве.
  final bool semanticLink;

  /// Курсор мыши. Если не задан, выбирается из enabled-состояния.
  final MouseCursor? cursor;

  /// Внешний focus node для программного управления фокусом.
  final FocusNode? focusNode;

  /// Запрашивать фокус при первом построении.
  final bool autofocus;

  @override
  State<CarpenterControl> createState() => _CarpenterControlState();
}

class _CarpenterControlState extends State<CarpenterControl> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.enabled && widget.onTap != null;

  void _activate() {
    if (_enabled) {
      widget.onTap?.call();
    }
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant CarpenterControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _hovered = false;
      _focused = false;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = CarpenterControlState(
      enabled: _enabled,
      hovered: _hovered,
      focused: _focused,
      pressed: _pressed,
    );

    return Semantics(
      button: widget.semanticButton,
      checked: widget.semanticChecked,
      toggled: widget.semanticToggled,
      selected: widget.semanticSelected,
      link: widget.semanticLink,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            widget.cursor ??
            (_enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
        onShowFocusHighlight: _setFocused,
        onShowHoverHighlight: _setHovered,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _activate : null,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          child: widget.builder(context, state),
        ),
      ),
    );
  }
}
