import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' as widgets;

/// Визуальный тип кнопки.
enum CarpenterButtonType {
  /// Залитая кнопка.
  filled,

  /// Кнопка на surface с рамкой.
  outlined,

  /// Кнопка без постоянной поверхности и рамки.
  ghost,
}

/// Размер кнопки.
///
/// Размер определяет высоту, типографику и размер иконок.
///
/// Горизонтальная компактность настраивается отдельно через
/// [Button.compact].
enum CarpenterButtonSize { small, medium, large }

/// Semantic color family кнопки.
enum CarpenterButtonColor {
  /// Нейтральное действие.
  neutral,

  /// Основное действие.
  primary,

  /// Вторичное действие.
  secondary,

  /// Акцентное действие.
  accent,

  /// Опасное или разрушительное действие.
  danger,
}

/// Универсальная кнопка Carpenter.
///
/// [Button] использует [material.ButtonStyleButton] как механизм
/// интерактивности: pointer, keyboard, focus, hover, pressed, disabled,
/// semantics и widget states.
///
/// Визуальная модель полностью определяется Carpenter через `context.face`.
/// Material button theme намеренно не используется.
///
/// Внешний вид задается независимыми параметрами:
///
/// - [type] — вид поверхности;
/// - [color] — semantic color family;
/// - [size] — размер;
/// - [compact] — горизонтальная компактность;
/// - [selected] — выбранное состояние.
///
/// Кнопка поддерживает обычный label:
///
/// ```dart
/// Button(
///   label: 'Сохранить',
///   onPressed: save,
/// )
/// ```
///
/// label с иконкой:
///
/// ```dart
/// Button(
///   label: 'Сохранить',
///   icon: Icon(...),
///   onPressed: save,
/// )
/// ```
///
/// icon-only:
///
/// ```dart
/// Button(
///   icon: Icon(...),
///   semanticLabel: 'Удалить',
///   compact: true,
///   onPressed: delete,
/// )
/// ```
///
/// произвольное содержимое:
///
/// ```dart
/// Button(
///   child: CustomContent(),
///   onPressed: action,
/// )
/// ```
///
/// и selectable-состояние:
///
/// ```dart
/// Button(
///   label: 'Закрепить',
///   selected: pinned,
///   color: CarpenterButtonColor.neutral,
///   selectedColor: CarpenterButtonColor.accent,
///   onPressed: togglePinned,
/// )
/// ```
class CarpenterButton extends material.ButtonStyleButton {
  /// Создает кнопку Carpenter.
  CarpenterButton({
    super.key,
    this.label,
    this.semanticLabel,
    this.icon,
    this.selectedIcon,
    this.selectedChild,
    this.selected,
    this.type = CarpenterButtonType.filled,
    this.size = CarpenterButtonSize.medium,
    this.color = CarpenterButtonColor.primary,
    this.selectedColor,
    this.compact = false,
    this.iconPosition = material.IconAlignment.start,
    super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.focusNode,
    super.autofocus = false,
    widgets.Clip super.clipBehavior = widgets.Clip.none,
    super.statesController,
    bool super.isSemanticButton,
    super.tooltip,
    widgets.Widget? child,
  }) : assert(
         label != null || child != null || icon != null,
         'Button requires label, child or icon.',
       ),
       assert(
         selectedChild == null || selected != null,
         'selectedChild requires selected to be non-null.',
       ),
       assert(
         selectedIcon == null || selected != null,
         'selectedIcon requires selected to be non-null.',
       ),
       assert(
         selectedColor == null || selected != null,
         'selectedColor requires selected to be non-null.',
       ),
       assert(
         selectedIcon == null || icon != null,
         'selectedIcon requires icon.',
       ),
       assert(
         selectedChild == null || selectedIcon == null,
         'selectedChild and selectedIcon cannot be used together.',
       ),
       assert(
         icon == null ||
             label != null ||
             child != null ||
             semanticLabel != null ||
             tooltip != null,
         'Icon-only Button requires semanticLabel or tooltip.',
       ),
       super(
         style: null,
         child: _ButtonContent(
           label: label,
           semanticLabel: semanticLabel,
           icon: icon,
           selectedIcon: selectedIcon,
           selectedChild: selectedChild,
           selected: selected,
           iconPosition: iconPosition,
           size: size,
           child: child,
         ),
       );

  /// Видимый текст кнопки.
  ///
  /// Если [child] не задан, [label] используется как основное содержимое.
  ///
  /// Если [child] задан, [label] не отображается и может использоваться
  /// как semantic label.
  final String? label;

  /// Явное accessibility-описание кнопки.
  ///
  /// Особенно важно для icon-only кнопок.
  ///
  /// Если не задано, для стандартного текстового содержимого semantics
  /// берется из самого текста.
  final String? semanticLabel;

  /// Иконка кнопки.
  ///
  /// Может использоваться самостоятельно, вместе с [label]
  /// или вместе с произвольным `child`.
  final widgets.Widget? icon;

  /// Иконка выбранного состояния.
  ///
  /// Используется вместо [icon], когда [selected] равно `true`.
  final widgets.Widget? selectedIcon;

  /// Полностью альтернативное содержимое выбранного состояния.
  ///
  /// Если [selected] равно `true`, [selectedChild] имеет приоритет
  /// над [icon], [selectedIcon], [label] и обычным `child`.
  final widgets.Widget? selectedChild;

  /// Состояние выбора.
  ///
  /// `null` означает обычную push-кнопку.
  ///
  /// `false` означает selectable-кнопку в обычном состоянии.
  ///
  /// `true` означает выбранное состояние.
  ///
  /// [Button] является controlled widget и не изменяет [selected]
  /// самостоятельно.
  final bool? selected;

  /// Визуальный тип кнопки.
  final CarpenterButtonType type;

  /// Размер кнопки.
  final CarpenterButtonSize size;

  /// Основная semantic color family.
  final CarpenterButtonColor color;

  /// Semantic color family выбранного состояния.
  ///
  /// Если не задана, выбранное состояние использует [color].
  ///
  /// Например:
  ///
  /// ```dart
  /// Button(
  ///   selected: selected,
  ///   color: CarpenterButtonColor.neutral,
  ///   selectedColor: CarpenterButtonColor.accent,
  /// )
  /// ```
  final CarpenterButtonColor? selectedColor;

  /// Уменьшает горизонтальные отступы.
  ///
  /// Высота кнопки не меняется.
  final bool compact;

  /// Логическое положение иконки относительно содержимого.
  ///
  /// [material.IconAlignment.start] означает начало строки с учетом
  /// направления текста.
  ///
  /// [material.IconAlignment.end] означает конец строки.
  final material.IconAlignment iconPosition;

  @override
  material.ButtonStyle defaultStyleOf(widgets.BuildContext context) {
    final face = context.face;

    final metrics = _ButtonMetrics.fromSize(size, compact: compact);

    final foreground = widgets.WidgetStateProperty.resolveWith<widgets.Color?>(
      (states) => _resolveColors(context, states).foreground,
    );

    return material.ButtonStyle(
      textStyle: widgets.WidgetStatePropertyAll(face.type(metrics.typeToken)),

      backgroundColor: widgets.WidgetStateProperty.resolveWith<widgets.Color?>(
        (states) => _resolveColors(context, states).background,
      ),

      foregroundColor: foreground,

      iconColor: foreground,

      overlayColor: const widgets.WidgetStatePropertyAll(
        widgets.Color(0x00000000),
      ),

      shadowColor: const widgets.WidgetStatePropertyAll(
        widgets.Color(0x00000000),
      ),

      surfaceTintColor: const widgets.WidgetStatePropertyAll(
        widgets.Color(0x00000000),
      ),

      elevation: const widgets.WidgetStatePropertyAll(0),

      padding: widgets.WidgetStatePropertyAll(
        widgets.EdgeInsets.symmetric(
          horizontal: face.space(metrics.horizontalSpace),
          vertical: face.space(metrics.verticalSpace),
        ),
      ),

      minimumSize: widgets.WidgetStatePropertyAll(
        widgets.Size(0, face.rem(metrics.minHeight)),
      ),

      maximumSize: const widgets.WidgetStatePropertyAll(widgets.Size.infinite),

      iconSize: widgets.WidgetStatePropertyAll(face.rem(metrics.iconSize)),

      // Актуальное место для настройки icon alignment.
      //
      // ButtonStyleButton.iconAlignment уже deprecated.
      iconAlignment: iconPosition,

      side: widgets.WidgetStateProperty.resolveWith<widgets.BorderSide?>((
        states,
      ) {
        final border = _resolveColors(context, states).border;

        if (border == null) {
          return widgets.BorderSide.none;
        }

        return widgets.BorderSide(color: border);
      }),

      shape: widgets.WidgetStatePropertyAll(
        material.RoundedRectangleBorder(
          borderRadius: widgets.BorderRadius.circular(face.radius('lg')),
        ),
      ),

      mouseCursor: widgets.WidgetStateMouseCursor.adaptiveClickable,

      // Carpenter сам управляет metrics.
      visualDensity: material.VisualDensity.standard,

      // Не добавляем Material minimum tap target поверх
      // Carpenter размеров.
      tapTargetSize: material.MaterialTapTargetSize.shrinkWrap,

      animationDuration: face.motion.fast,

      enableFeedback: true,

      alignment: widgets.Alignment.center,

      // Hover / focus / pressed уже выражаются Carpenter-цветами.
      splashFactory: material.NoSplash.splashFactory,
    );
  }

  @override
  material.ButtonStyle? themeStyleOf(widgets.BuildContext context) {
    // Material component themes намеренно не участвуют
    // в визуальном языке Carpenter.
    return null;
  }

  _ButtonColors _resolveColors(
    widgets.BuildContext context,
    Set<widgets.WidgetState> states,
  ) {
    final isSelected = selected == true;

    final effectiveColor = isSelected && selectedColor != null
        ? selectedColor!
        : color;

    return _ButtonColors.resolve(
      context,
      type: type,
      color: effectiveColor,
      selected: isSelected,
      enabled: !states.contains(widgets.WidgetState.disabled),
      hovered: states.contains(widgets.WidgetState.hovered),
      focused: states.contains(widgets.WidgetState.focused),
      pressed: states.contains(widgets.WidgetState.pressed),
    );
  }
}

/// Внутреннее содержимое кнопки.
///
/// Отдельный widget нужен, чтобы [Button] сохранял `const` constructor
/// при динамической сборке icon / label / selected representation.
class _ButtonContent extends widgets.StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.selectedIcon,
    required this.selectedChild,
    required this.selected,
    required this.iconPosition,
    required this.size,
    required this.child,
  });

  final String? label;

  final String? semanticLabel;

  final widgets.Widget? icon;

  final widgets.Widget? selectedIcon;

  final widgets.Widget? selectedChild;

  final bool? selected;

  final material.IconAlignment iconPosition;

  final CarpenterButtonSize size;

  final widgets.Widget? child;

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final usingSelectedChild = selected == true && selectedChild != null;

    widgets.Widget content;

    if (usingSelectedChild) {
      content = selectedChild!;
    } else {
      content = _buildContent(context);
    }

    // Если отображается обычный label, Text сам предоставляет semantics.
    //
    // Если же наружный label отличается от реально отображаемого child
    // либо задан explicit semanticLabel, задаем semantics вручную.
    final effectiveSemanticLabel =
        semanticLabel ?? ((child != null || usingSelectedChild) ? label : null);

    if (effectiveSemanticLabel != null) {
      content = widgets.Semantics(
        label: effectiveSemanticLabel,
        excludeSemantics: true,
        child: content,
      );
    }

    if (selected != null) {
      content = widgets.Semantics(selected: selected, child: content);
    }

    return content;
  }

  widgets.Widget _buildContent(widgets.BuildContext context) {
    final effectiveIcon = selected == true && selectedIcon != null
        ? selectedIcon
        : icon;

    final effectiveChild =
        child ?? (label != null ? widgets.Text(label!) : null);

    if (effectiveIcon == null) {
      return effectiveChild!;
    }

    if (effectiveChild == null) {
      return effectiveIcon;
    }

    final metrics = _ButtonMetrics.fromSize(size, compact: false);

    final gap = widgets.SizedBox(width: context.face.space(metrics.iconSpace));

    return switch (iconPosition) {
      material.IconAlignment.start => widgets.Row(
        mainAxisSize: widgets.MainAxisSize.min,
        children: [effectiveIcon, gap, effectiveChild],
      ),

      material.IconAlignment.end => widgets.Row(
        mainAxisSize: widgets.MainAxisSize.min,
        children: [effectiveChild, gap, effectiveIcon],
      ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final widgets.Color background;

  final widgets.Color foreground;

  final widgets.Color? border;

  static _ButtonColors resolve(
    widgets.BuildContext context, {
    required CarpenterButtonType type,
    required CarpenterButtonColor color,
    required bool selected,
    required bool enabled,
    required bool hovered,
    required bool focused,
    required bool pressed,
  }) {
    final face = context.face;

    final action = color.token;

    final actionColor = face.color('action.$action');

    final hoverColor = face.color('action.$action.hover');

    final pressedColor = face.color('action.$action.pressed');

    final textColor = face.color('action.$action.text');

    if (!enabled) {
      return _resolveDisabled(
        context,
        type: type,
        actionColor: actionColor,
        selected: selected,
      );
    }

    return switch (type) {
      CarpenterButtonType.filled => _resolveFilled(
        context,
        actionColor: actionColor,
        hoverColor: hoverColor,
        pressedColor: pressedColor,
        textColor: textColor,
        selected: selected,
        hovered: hovered,
        focused: focused,
        pressed: pressed,
      ),

      CarpenterButtonType.outlined => _resolveOutlined(
        context,
        actionColor: actionColor,
        hoverColor: hoverColor,
        pressedColor: pressedColor,
        selected: selected,
        hovered: hovered,
        focused: focused,
        pressed: pressed,
      ),

      CarpenterButtonType.ghost => _resolveGhost(
        context,
        actionColor: actionColor,
        hoverColor: hoverColor,
        pressedColor: pressedColor,
        selected: selected,
        hovered: hovered,
        focused: focused,
        pressed: pressed,
      ),
    };
  }

  static _ButtonColors _resolveDisabled(
    widgets.BuildContext context, {
    required CarpenterButtonType type,
    required widgets.Color actionColor,
    required bool selected,
  }) {
    final face = context.face;

    final disabledBackground = face.color('action.disabled');

    final disabledForeground = face.color('action.disabled.text');

    return switch (type) {
      CarpenterButtonType.filled => _ButtonColors(
        background: selected
            ? widgets.Color.lerp(disabledBackground, actionColor, 0.20)!
            : disabledBackground,
        foreground: disabledForeground,
      ),

      CarpenterButtonType.outlined => _ButtonColors(
        background: selected
            ? widgets.Color.lerp(
                face.color('surface.raised'),
                actionColor,
                0.08,
              )!
            : face.color('surface.raised'),
        foreground: disabledForeground,
        border: face.color('border.subtle'),
      ),

      CarpenterButtonType.ghost => _ButtonColors(
        background: selected
            ? widgets.Color.lerp(
                const widgets.Color(0x00000000),
                actionColor,
                0.08,
              )!
            : const widgets.Color(0x00000000),
        foreground: disabledForeground,
      ),
    };
  }

  static _ButtonColors _resolveFilled(
    widgets.BuildContext context, {
    required widgets.Color actionColor,
    required widgets.Color hoverColor,
    required widgets.Color pressedColor,
    required widgets.Color textColor,
    required bool selected,
    required bool hovered,
    required bool focused,
    required bool pressed,
  }) {
    final face = context.face;

    final background = pressed
        ? pressedColor
        : hovered || focused
        ? hoverColor
        : selected
        ? widgets.Color.lerp(actionColor, pressedColor, 0.18)!
        : actionColor;

    return _ButtonColors(
      background: background,
      foreground: textColor,
      border: focused ? face.color('border.focus') : null,
    );
  }

  static _ButtonColors _resolveOutlined(
    widgets.BuildContext context, {
    required widgets.Color actionColor,
    required widgets.Color hoverColor,
    required widgets.Color pressedColor,
    required bool selected,
    required bool hovered,
    required bool focused,
    required bool pressed,
  }) {
    final face = context.face;

    final base = face.color('surface.raised');

    final background = pressed
        ? widgets.Color.lerp(base, actionColor, 0.16)!
        : hovered || focused
        ? widgets.Color.lerp(base, actionColor, selected ? 0.16 : 0.07)!
        : selected
        ? widgets.Color.lerp(base, actionColor, 0.12)!
        : base;

    final foreground = pressed
        ? pressedColor
        : hovered
        ? hoverColor
        : actionColor;

    final border = focused
        ? face.color('border.focus')
        : selected
        ? actionColor
        : face.color('border.normal');

    return _ButtonColors(
      background: background,
      foreground: foreground,
      border: border,
    );
  }

  static _ButtonColors _resolveGhost(
    widgets.BuildContext context, {
    required widgets.Color actionColor,
    required widgets.Color hoverColor,
    required widgets.Color pressedColor,
    required bool selected,
    required bool hovered,
    required bool focused,
    required bool pressed,
  }) {
    final face = context.face;

    final background = pressed
        ? widgets.Color.lerp(
            const widgets.Color(0x00000000),
            pressedColor,
            0.18,
          )!
        : hovered || focused
        ? widgets.Color.lerp(
            const widgets.Color(0x00000000),
            hoverColor,
            selected ? 0.16 : 0.09,
          )!
        : selected
        ? widgets.Color.lerp(
            const widgets.Color(0x00000000),
            actionColor,
            0.12,
          )!
        : const widgets.Color(0x00000000);

    final foreground = pressed
        ? pressedColor
        : hovered
        ? hoverColor
        : actionColor;

    return _ButtonColors(
      background: background,
      foreground: foreground,
      border: focused ? face.color('border.focus') : null,
    );
  }
}

class _ButtonMetrics {
  const _ButtonMetrics({
    required this.minHeight,
    required this.horizontalSpace,
    required this.verticalSpace,
    required this.iconSpace,
    required this.iconSize,
    required this.typeToken,
  });

  final double minHeight;

  final String horizontalSpace;

  final String verticalSpace;

  final String iconSpace;

  final double iconSize;

  final String typeToken;

  factory _ButtonMetrics.fromSize(
    CarpenterButtonSize size, {
    required bool compact,
  }) {
    return switch (size) {
      CarpenterButtonSize.small => _ButtonMetrics(
        minHeight: 1.75,
        horizontalSpace: compact ? '0.5' : '0.75',
        verticalSpace: '0.25',
        iconSpace: '0.5',
        iconSize: 0.875,
        typeToken: 'caption',
      ),

      CarpenterButtonSize.medium => _ButtonMetrics(
        minHeight: 2,
        horizontalSpace: compact ? '0.75' : '1.25',
        verticalSpace: '0.5',
        iconSpace: '0.5',
        iconSize: 1,
        typeToken: 'label.strong',
      ),

      CarpenterButtonSize.large => _ButtonMetrics(
        minHeight: 2.5,
        horizontalSpace: compact ? '1' : '1.5',
        verticalSpace: '0.625',
        iconSpace: '0.75',
        iconSize: 1.125,
        typeToken: 'label.strong',
      ),
    };
  }
}

extension on CarpenterButtonColor {
  String get token => switch (this) {
    CarpenterButtonColor.neutral => 'neutral',
    CarpenterButtonColor.primary => 'primary',
    CarpenterButtonColor.secondary => 'secondary',
    CarpenterButtonColor.accent => 'accent',
    CarpenterButtonColor.danger => 'danger',
  };
}
