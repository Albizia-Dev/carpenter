import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import 'roles.dart';
import 'tokens/carpenter.mordant.g.dart' as tokens;

@immutable
final class CarpenterThemeData {
  const CarpenterThemeData._({
    required this.brightness,
    required this.contrast,
    required this.density,
    required this.typography,
    required this.content,
    required this.actions,
    required this.fields,
    required this.selection,
    required this.feedback,
    required this.sizes,
    required this.spacing,
    required this.shapes,
    required this.motion,
    required this.focus,
    required this.surface,
    required this.overlay,
  });

  factory CarpenterThemeData.light({
    ContrastMode contrast = ContrastMode.standard,
    CarpenterDensity density = CarpenterDensity.normal,
  }) => _fromTokens(
    brightness: Brightness.light,
    contrast: contrast,
    density: density,
  );

  factory CarpenterThemeData.dark({
    ContrastMode contrast = ContrastMode.standard,
    CarpenterDensity density = CarpenterDensity.normal,
  }) => _fromTokens(
    brightness: Brightness.dark,
    contrast: contrast,
    density: density,
  );

  final Brightness brightness;
  final ContrastMode contrast;
  final CarpenterDensity density;
  final CarpenterTypographyTheme typography;
  final CarpenterContentTheme content;
  final CarpenterActionTheme actions;
  final CarpenterFieldTheme fields;
  final CarpenterSelectionTheme selection;
  final CarpenterFeedbackTheme feedback;
  final CarpenterSizeTheme sizes;
  final CarpenterSpacingTheme spacing;
  final CarpenterShapeTheme shapes;
  final CarpenterMotionTheme motion;
  final CarpenterFocusTheme focus;
  final CarpenterSurfaceTheme surface;
  final CarpenterOverlayTheme overlay;
}

final class CarpenterTheme extends InheritedWidget {
  const CarpenterTheme({super.key, required this.data, required super.child});

  final CarpenterThemeData data;

  static CarpenterThemeData of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<CarpenterTheme>();
    assert(result != null, 'No CarpenterTheme found above this context.');
    return result!.data;
  }

  @override
  bool updateShouldNotify(CarpenterTheme oldWidget) => data != oldWidget.data;
}

@immutable
final class CarpenterTypographyTheme {
  const CarpenterTypographyTheme();

  TextStyle resolve(
    BuildContext context,
    TypographyRole role,
    TypographyEmphasis emphasis,
  ) {
    return _resolveUnits(context, _fontSize(role), _lineHeight(role), emphasis);
  }

  TextStyle action(
    BuildContext context,
    ControlSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _actionFontSize(size),
    _actionLineHeight(size),
    emphasis,
  );

  TextStyle fieldInput(
    BuildContext context,
    FieldSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _fieldInputFontSize(size),
    _fieldInputLineHeight(size),
    emphasis,
  );

  TextStyle fieldLabel(
    BuildContext context,
    FieldSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _fieldLabelFontSize(size),
    _fieldLabelLineHeight(size),
    emphasis,
  );

  TextStyle fieldSupporting(
    BuildContext context,
    FieldSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _fieldSupportingFontSize(size),
    _fieldSupportingLineHeight(size),
    emphasis,
  );

  TextStyle selectionLabel(
    BuildContext context,
    ControlSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _selectionLabelFontSize(size),
    _selectionLabelLineHeight(size),
    emphasis,
  );

  TextStyle selectionSupporting(
    BuildContext context,
    ControlSize size,
    TypographyEmphasis emphasis,
  ) => _resolveUnits(
    context,
    _selectionSupportingFontSize(size),
    _selectionSupportingLineHeight(size),
    emphasis,
  );

  TextStyle status(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.status.fontSize,
        tokens.component.status.lineHeight,
        emphasis,
      );

  TextStyle menuItem(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.menu.itemFontSize,
        tokens.component.menu.itemLineHeight,
        emphasis,
      );

  TextStyle tooltip(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.overlay.tooltipFontSize,
        tokens.component.overlay.tooltipLineHeight,
        emphasis,
      );

  TextStyle dialogTitle(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.overlay.dialogTitleFontSize,
        tokens.component.overlay.dialogTitleLineHeight,
        emphasis,
      );

  TextStyle toastTitle(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.overlay.toastTitleFontSize,
        tokens.component.overlay.toastTitleLineHeight,
        emphasis,
      );

  TextStyle toastMessage(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.overlay.toastMessageFontSize,
        tokens.component.overlay.toastMessageLineHeight,
        emphasis,
      );

  TextStyle tableHeader(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.table.headerFontSize,
        tokens.component.table.headerLineHeight,
        emphasis,
      );

  TextStyle tableCell(BuildContext context, TypographyEmphasis emphasis) =>
      _resolveUnits(
        context,
        tokens.component.table.cellFontSize,
        tokens.component.table.cellLineHeight,
        emphasis,
      );

  TextStyle _resolveUnits(
    BuildContext context,
    LengthUnit fontSizeUnit,
    LengthUnit lineHeightUnit,
    TypographyEmphasis emphasis,
  ) {
    final fontSize = context.units(fontSizeUnit);
    final lineHeight = context.units(lineHeightUnit);
    return TextStyle(
      fontSize: fontSize,
      height: lineHeight / fontSize,
      fontWeight: FontWeight.lerp(
        FontWeight.w100,
        FontWeight.w900,
        (_fontWeight(emphasis) - 100) / 800,
      ),
    );
  }

  LengthUnit _actionFontSize(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.action.font.size.xsmall,
    ControlSize.small => tokens.component.action.font.size.small,
    ControlSize.medium => tokens.component.action.font.size.medium,
    ControlSize.large => tokens.component.action.font.size.large,
    ControlSize.xlarge => tokens.component.action.font.size.xlarge,
  };

  LengthUnit _actionLineHeight(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.action.font.lineHeight.xsmall,
    ControlSize.small => tokens.component.action.font.lineHeight.small,
    ControlSize.medium => tokens.component.action.font.lineHeight.medium,
    ControlSize.large => tokens.component.action.font.lineHeight.large,
    ControlSize.xlarge => tokens.component.action.font.lineHeight.xlarge,
  };

  LengthUnit _fieldInputFontSize(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.inputFont.size.xsmall,
    FieldSize.small => tokens.component.field.inputFont.size.small,
    FieldSize.medium => tokens.component.field.inputFont.size.medium,
    FieldSize.large => tokens.component.field.inputFont.size.large,
    FieldSize.xlarge => tokens.component.field.inputFont.size.xlarge,
  };

  LengthUnit _fieldInputLineHeight(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.inputFont.lineHeight.xsmall,
    FieldSize.small => tokens.component.field.inputFont.lineHeight.small,
    FieldSize.medium => tokens.component.field.inputFont.lineHeight.medium,
    FieldSize.large => tokens.component.field.inputFont.lineHeight.large,
    FieldSize.xlarge => tokens.component.field.inputFont.lineHeight.xlarge,
  };

  LengthUnit _fieldLabelFontSize(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.labelFont.size.xsmall,
    FieldSize.small => tokens.component.field.labelFont.size.small,
    FieldSize.medium => tokens.component.field.labelFont.size.medium,
    FieldSize.large => tokens.component.field.labelFont.size.large,
    FieldSize.xlarge => tokens.component.field.labelFont.size.xlarge,
  };

  LengthUnit _fieldLabelLineHeight(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.labelFont.lineHeight.xsmall,
    FieldSize.small => tokens.component.field.labelFont.lineHeight.small,
    FieldSize.medium => tokens.component.field.labelFont.lineHeight.medium,
    FieldSize.large => tokens.component.field.labelFont.lineHeight.large,
    FieldSize.xlarge => tokens.component.field.labelFont.lineHeight.xlarge,
  };

  LengthUnit _fieldSupportingFontSize(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.supportingFont.size.xsmall,
    FieldSize.small => tokens.component.field.supportingFont.size.small,
    FieldSize.medium => tokens.component.field.supportingFont.size.medium,
    FieldSize.large => tokens.component.field.supportingFont.size.large,
    FieldSize.xlarge => tokens.component.field.supportingFont.size.xlarge,
  };

  LengthUnit _fieldSupportingLineHeight(FieldSize size) => switch (size) {
    FieldSize.xsmall => tokens.component.field.supportingFont.lineHeight.xsmall,
    FieldSize.small => tokens.component.field.supportingFont.lineHeight.small,
    FieldSize.medium => tokens.component.field.supportingFont.lineHeight.medium,
    FieldSize.large => tokens.component.field.supportingFont.lineHeight.large,
    FieldSize.xlarge => tokens.component.field.supportingFont.lineHeight.xlarge,
  };

  LengthUnit _selectionLabelFontSize(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.selection.labelFont.size.xsmall,
    ControlSize.small => tokens.component.selection.labelFont.size.small,
    ControlSize.medium => tokens.component.selection.labelFont.size.medium,
    ControlSize.large => tokens.component.selection.labelFont.size.large,
    ControlSize.xlarge => tokens.component.selection.labelFont.size.xlarge,
  };

  LengthUnit _selectionLabelLineHeight(ControlSize size) => switch (size) {
    ControlSize.xsmall =>
      tokens.component.selection.labelFont.lineHeight.xsmall,
    ControlSize.small => tokens.component.selection.labelFont.lineHeight.small,
    ControlSize.medium =>
      tokens.component.selection.labelFont.lineHeight.medium,
    ControlSize.large => tokens.component.selection.labelFont.lineHeight.large,
    ControlSize.xlarge =>
      tokens.component.selection.labelFont.lineHeight.xlarge,
  };

  LengthUnit _selectionSupportingFontSize(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.selection.supportingFont.size.xsmall,
    ControlSize.small => tokens.component.selection.supportingFont.size.small,
    ControlSize.medium => tokens.component.selection.supportingFont.size.medium,
    ControlSize.large => tokens.component.selection.supportingFont.size.large,
    ControlSize.xlarge => tokens.component.selection.supportingFont.size.xlarge,
  };

  LengthUnit _selectionSupportingLineHeight(ControlSize size) => switch (size) {
    ControlSize.xsmall =>
      tokens.component.selection.supportingFont.lineHeight.xsmall,
    ControlSize.small =>
      tokens.component.selection.supportingFont.lineHeight.small,
    ControlSize.medium =>
      tokens.component.selection.supportingFont.lineHeight.medium,
    ControlSize.large =>
      tokens.component.selection.supportingFont.lineHeight.large,
    ControlSize.xlarge =>
      tokens.component.selection.supportingFont.lineHeight.xlarge,
  };

  LengthUnit _fontSize(TypographyRole role) => switch (role) {
    TypographyRole.display => tokens.font.size.display,
    TypographyRole.title => tokens.font.size.title,
    TypographyRole.body => tokens.font.size.body,
    TypographyRole.label => tokens.font.size.label,
    TypographyRole.caption => tokens.font.size.caption,
  };

  LengthUnit _lineHeight(TypographyRole role) => switch (role) {
    TypographyRole.display => tokens.font.lineHeight.display,
    TypographyRole.title => tokens.font.lineHeight.title,
    TypographyRole.body => tokens.font.lineHeight.body,
    TypographyRole.label => tokens.font.lineHeight.label,
    TypographyRole.caption => tokens.font.lineHeight.caption,
  };

  double _fontWeight(TypographyEmphasis emphasis) => switch (emphasis) {
    TypographyEmphasis.regular => tokens.font.weight.regular.toDouble(),
    TypographyEmphasis.medium => tokens.font.weight.medium.toDouble(),
    TypographyEmphasis.strong => tokens.font.weight.strong.toDouble(),
  };
}

@immutable
final class CarpenterContentTheme {
  const CarpenterContentTheme({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.inverse,
    required this.disabled,
  });

  final Color primary;
  final Color secondary;
  final Color muted;
  final Color inverse;
  final Color disabled;

  Color resolve(ContentColorRole role) => switch (role) {
    ContentColorRole.primary => primary,
    ContentColorRole.secondary => secondary,
    ContentColorRole.muted => muted,
    ContentColorRole.inverse => inverse,
    ContentColorRole.disabled => disabled,
  };
}

@immutable
final class CarpenterActionPalette {
  const CarpenterActionPalette({
    required this.normal,
    required this.hovered,
    required this.pressed,
    required this.state,
    required this.strongState,
  });

  final Color normal;
  final Color hovered;
  final Color pressed;
  final Color state;
  final Color strongState;

  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.hovered)) return hovered;
    return normal;
  }
}

@immutable
final class CarpenterActionStyle {
  const CarpenterActionStyle({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.border,
    required this.loadingAccent,
  });

  final Color background;
  final Color foreground;
  final Color icon;
  final Color border;
  final Color loadingAccent;
}

@immutable
final class CarpenterActionTheme {
  const CarpenterActionTheme({
    required this.neutral,
    required this.primary,
    required this.utility,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
    required this.transparent,
    required this.inverse,
    required this.disabledBackground,
    required this.disabledForeground,
  });

  final CarpenterActionPalette neutral;
  final CarpenterActionPalette primary;
  final CarpenterActionPalette utility;
  final CarpenterActionPalette danger;
  final CarpenterActionPalette warning;
  final CarpenterActionPalette success;
  final CarpenterActionPalette info;
  final Color transparent;
  final Color inverse;
  final Color disabledBackground;
  final Color disabledForeground;

  CarpenterActionStyle resolve(
    ActionColorRole role,
    ActionProminence prominence,
    Set<WidgetState> states,
  ) {
    if (states.contains(WidgetState.disabled)) {
      return CarpenterActionStyle(
        background: switch (prominence) {
          ActionProminence.high => disabledBackground,
          ActionProminence.normal => disabledBackground,
          ActionProminence.ghost ||
          ActionProminence.outlined ||
          ActionProminence.low => transparent,
        },
        foreground: disabledForeground,
        icon: disabledForeground,
        border: prominence == ActionProminence.outlined
            ? disabledForeground
            : transparent,
        loadingAccent: disabledForeground,
      );
    }

    final palette = switch (role) {
      ActionColorRole.neutral => neutral,
      ActionColorRole.primary => primary,
      ActionColorRole.utility => utility,
      ActionColorRole.danger => danger,
      ActionColorRole.warning => warning,
      ActionColorRole.success => success,
      ActionColorRole.info => info,
    };
    final semantic = palette.resolve(states);
    final active =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);

    return switch (prominence) {
      ActionProminence.high => CarpenterActionStyle(
        background: semantic,
        foreground: inverse,
        icon: inverse,
        border: semantic,
        loadingAccent: palette.hovered,
      ),
      ActionProminence.normal => CarpenterActionStyle(
        background: active ? palette.strongState : palette.state,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.strongState,
      ),
      ActionProminence.outlined => CarpenterActionStyle(
        background: active ? palette.state : transparent,
        foreground: semantic,
        icon: semantic,
        border: semantic,
        loadingAccent: palette.state,
      ),
      ActionProminence.low => CarpenterActionStyle(
        background: active ? palette.strongState : transparent,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.state,
      ),
      ActionProminence.ghost => CarpenterActionStyle(
        background: active ? palette.state : transparent,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.state,
      ),
    };
  }
}

@immutable
final class CarpenterFieldStyle {
  const CarpenterFieldStyle({
    required this.background,
    required this.foreground,
    required this.placeholder,
    required this.border,
    required this.label,
    required this.supporting,
    required this.error,
    required this.icon,
    required this.selection,
  });

  final Color background;
  final Color foreground;
  final Color placeholder;
  final Color border;
  final Color label;
  final Color supporting;
  final Color error;
  final Color icon;
  final Color selection;
}

@immutable
final class CarpenterFieldTheme {
  const CarpenterFieldTheme({
    required this.background,
    required this.backgroundHovered,
    required this.backgroundDisabled,
    required this.foreground,
    required this.placeholder,
    required this.border,
    required this.borderHovered,
    required this.borderFocused,
    required this.borderError,
    required this.label,
    required this.supporting,
    required this.error,
    required this.icon,
    required this.selection,
    required this.disabledForeground,
  });

  final Color background;
  final Color backgroundHovered;
  final Color backgroundDisabled;
  final Color foreground;
  final Color placeholder;
  final Color border;
  final Color borderHovered;
  final Color borderFocused;
  final Color borderError;
  final Color label;
  final Color supporting;
  final Color error;
  final Color icon;
  final Color selection;
  final Color disabledForeground;

  CarpenterFieldStyle resolve({
    required FieldAvailability availability,
    required Set<WidgetState> states,
    required bool hasError,
  }) {
    final disabled = availability == FieldAvailability.disabled;
    final focused = states.contains(WidgetState.focused);
    final hovered = states.contains(WidgetState.hovered);
    return CarpenterFieldStyle(
      background: disabled
          ? backgroundDisabled
          : hovered
          ? backgroundHovered
          : background,
      foreground: disabled ? disabledForeground : foreground,
      placeholder: disabled ? disabledForeground : placeholder,
      border: disabled
          ? disabledForeground
          : hasError
          ? borderError
          : focused
          ? borderFocused
          : hovered
          ? borderHovered
          : border,
      label: disabled ? disabledForeground : label,
      supporting: disabled ? disabledForeground : supporting,
      error: disabled ? disabledForeground : error,
      icon: disabled ? disabledForeground : icon,
      selection: selection,
    );
  }
}

@immutable
final class CarpenterSelectionStyle {
  const CarpenterSelectionStyle({
    required this.background,
    required this.border,
    required this.mark,
    required this.foreground,
    required this.supporting,
  });

  final Color background;
  final Color border;
  final Color mark;
  final Color foreground;
  final Color supporting;
}

@immutable
final class CarpenterSelectionPalette {
  const CarpenterSelectionPalette({
    required this.selected,
    required this.selectedHovered,
    required this.mark,
  });

  final Color selected;
  final Color selectedHovered;
  final Color mark;
}

@immutable
final class CarpenterSelectionTheme {
  const CarpenterSelectionTheme(
    this._palettes, {
    required this.foreground,
    required this.supporting,
    required this.disabledForeground,
    required this.background,
    required this.backgroundHovered,
    required this.border,
    required this.borderHovered,
    required this.disabledBackground,
    required this.disabledBorder,
    required this.disabledSelected,
    required this.disabledMark,
  });

  final Color foreground;
  final Color supporting;
  final Color disabledForeground;
  final Color background;
  final Color backgroundHovered;
  final Color border;
  final Color borderHovered;
  final Map<SelectionColorRole, CarpenterSelectionPalette> _palettes;
  final Color disabledBackground;
  final Color disabledBorder;
  final Color disabledSelected;
  final Color disabledMark;

  CarpenterSelectionStyle resolve({
    required SelectionColorRole role,
    required bool selected,
    required Set<WidgetState> states,
  }) {
    final disabled = states.contains(WidgetState.disabled);
    final hovered = states.contains(WidgetState.hovered);
    final palette = _palettes[role]!;
    return CarpenterSelectionStyle(
      background: disabled
          ? selected
                ? disabledSelected
                : disabledBackground
          : selected
          ? hovered
                ? palette.selectedHovered
                : palette.selected
          : hovered
          ? backgroundHovered
          : background,
      border: disabled
          ? disabledBorder
          : selected
          ? hovered
                ? palette.selectedHovered
                : palette.selected
          : hovered
          ? borderHovered
          : border,
      mark: disabled ? disabledMark : palette.mark,
      foreground: disabled ? disabledForeground : foreground,
      supporting: disabled ? disabledForeground : supporting,
    );
  }
}

@immutable
final class CarpenterFeedbackStyle {
  const CarpenterFeedbackStyle({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

@immutable
final class CarpenterFeedbackTheme {
  const CarpenterFeedbackTheme(this._styles);

  final Map<FeedbackColorRole, CarpenterFeedbackStyle> _styles;

  CarpenterFeedbackStyle resolve(FeedbackColorRole role) => _styles[role]!;
}

@immutable
final class CarpenterSizeTheme {
  const CarpenterSizeTheme({required this.minimumTarget});

  final LengthUnit minimumTarget;

  LengthUnit get zero => tokens.size.zero;
  LengthUnit get overlayMenuMinWidth => tokens.component.menu.minWidth;
  LengthUnit get overlayMenuMaxHeight => tokens.component.menu.maxHeight;
  LengthUnit get overlayTooltipMaxWidth =>
      tokens.component.overlay.tooltipMaxWidth;
  LengthUnit get overlayDialogMaxWidth =>
      tokens.component.overlay.dialogMaxWidth;
  LengthUnit get overlayToastMaxWidth => tokens.component.overlay.toastMaxWidth;
  LengthUnit get menuItemIcon => tokens.component.menu.itemIcon;
  LengthUnit get tableColumn => tokens.component.table.columnWidth;
  LengthUnit get tableColumnMin => tokens.component.table.columnMinWidth;
  LengthUnit get tableColumnMax => tokens.component.table.columnMaxWidth;
  LengthUnit get tableSelectionColumn =>
      tokens.component.table.selectionColumnWidth;
  LengthUnit get tableHeaderHeight => tokens.component.table.headerHeight;
  LengthUnit get tableRowHeight => tokens.component.table.rowHeight;
  LengthUnit get tableStateHeight => tokens.component.table.stateHeight;
  LengthUnit get tableBodyMaxHeight => tokens.component.table.bodyMaxHeight;
  LengthUnit get tableResizeHandle => tokens.component.table.resizeHandleWidth;
  LengthUnit get layoutNarrowEnd => tokens.size.layout.narrowEnd;
  LengthUnit get layoutMediumEnd => tokens.size.layout.mediumEnd;
  LengthUnit get layoutNavigationSide => tokens.size.layout.navigationSide;
  LengthUnit get layoutNavigationCompact =>
      tokens.size.layout.navigationCompact;
  LengthUnit get layoutSecondary => tokens.size.layout.secondary;
  LengthUnit get layoutAdaptiveOverlay => tokens.size.layout.adaptiveOverlay;
  LengthUnit get layoutSplitDivider => tokens.size.layout.splitDivider;
  LengthUnit get layoutPageMaxWidth => tokens.size.layout.pageMaxWidth;
  LengthUnit get layoutFilterSearch => tokens.size.layout.filterSearch;

  LengthUnit control(ControlSize value) => actionHeight(value);

  LengthUnit actionHeight(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.action.height.xsmall,
    ControlSize.small => tokens.component.action.height.small,
    ControlSize.medium => tokens.component.action.height.medium,
    ControlSize.large => tokens.component.action.height.large,
    ControlSize.xlarge => tokens.component.action.height.xlarge,
  };

  double actionExtent(BuildContext context, ControlSize value) =>
      MediaQuery.textScalerOf(
        context,
      ).scale(context.units(actionHeight(value)));

  IconSize iconForControl(ControlSize value) => switch (value) {
    ControlSize.xsmall => IconSize.xsmall,
    ControlSize.small => IconSize.small,
    ControlSize.medium => IconSize.medium,
    ControlSize.large => IconSize.large,
    ControlSize.xlarge => IconSize.xlarge,
  };

  IconSize iconForField(FieldSize value) => switch (value) {
    FieldSize.xsmall => IconSize.xsmall,
    FieldSize.small => IconSize.small,
    FieldSize.medium => IconSize.medium,
    FieldSize.large => IconSize.large,
    FieldSize.xlarge => IconSize.xlarge,
  };

  ControlSize controlForField(FieldSize value) => switch (value) {
    FieldSize.xsmall => ControlSize.xsmall,
    FieldSize.small => ControlSize.small,
    FieldSize.medium => ControlSize.medium,
    FieldSize.large => ControlSize.large,
    FieldSize.xlarge => ControlSize.xlarge,
  };

  LengthUnit icon(IconSize value) => switch (value) {
    IconSize.xsmall => tokens.size.icon.xsmall,
    IconSize.small => tokens.size.icon.small,
    IconSize.medium => tokens.size.icon.medium,
    IconSize.large => tokens.size.icon.large,
    IconSize.xlarge => tokens.size.icon.xlarge,
  };

  LengthUnit actionIcon(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.action.icon.xsmall,
    ControlSize.small => tokens.component.action.icon.small,
    ControlSize.medium => tokens.component.action.icon.medium,
    ControlSize.large => tokens.component.action.icon.large,
    ControlSize.xlarge => tokens.component.action.icon.xlarge,
  };

  LengthUnit field(FieldSize value) => fieldHeight(value);

  LengthUnit fieldHeight(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.height.xsmall,
    FieldSize.small => tokens.component.field.height.small,
    FieldSize.medium => tokens.component.field.height.medium,
    FieldSize.large => tokens.component.field.height.large,
    FieldSize.xlarge => tokens.component.field.height.xlarge,
  };

  double fieldExtent(BuildContext context, FieldSize value) =>
      MediaQuery.textScalerOf(context).scale(context.units(fieldHeight(value)));

  LengthUnit fieldIcon(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.icon.xsmall,
    FieldSize.small => tokens.component.field.icon.small,
    FieldSize.medium => tokens.component.field.icon.medium,
    FieldSize.large => tokens.component.field.icon.large,
    FieldSize.xlarge => tokens.component.field.icon.xlarge,
  };

  LengthUnit selectionIndicator(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.checkbox.size.xsmall,
    ControlSize.small => tokens.component.selection.checkbox.size.small,
    ControlSize.medium => tokens.component.selection.checkbox.size.medium,
    ControlSize.large => tokens.component.selection.checkbox.size.large,
    ControlSize.xlarge => tokens.component.selection.checkbox.size.xlarge,
  };

  LengthUnit checkboxSize(ControlSize value) => selectionIndicator(value);

  LengthUnit radioSize(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.radio.size.xsmall,
    ControlSize.small => tokens.component.selection.radio.size.small,
    ControlSize.medium => tokens.component.selection.radio.size.medium,
    ControlSize.large => tokens.component.selection.radio.size.large,
    ControlSize.xlarge => tokens.component.selection.radio.size.xlarge,
  };

  LengthUnit switchWidth(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.switchToken.width.xsmall,
    ControlSize.small => tokens.component.selection.switchToken.width.small,
    ControlSize.medium => tokens.component.selection.switchToken.width.medium,
    ControlSize.large => tokens.component.selection.switchToken.width.large,
    ControlSize.xlarge => tokens.component.selection.switchToken.width.xlarge,
  };

  LengthUnit switchHeight(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.switchToken.height.xsmall,
    ControlSize.small => tokens.component.selection.switchToken.height.small,
    ControlSize.medium => tokens.component.selection.switchToken.height.medium,
    ControlSize.large => tokens.component.selection.switchToken.height.large,
    ControlSize.xlarge => tokens.component.selection.switchToken.height.xlarge,
  };
}

@immutable
final class CarpenterSpacingTheme {
  const CarpenterSpacingTheme(this.density);

  final CarpenterDensity density;

  LengthUnit controlHorizontal(ControlSize value) =>
      actionHorizontalPadding(value);

  LengthUnit actionHorizontalPadding(ControlSize value) =>
      switch ((density, value)) {
        (CarpenterDensity.normal, ControlSize.xsmall) =>
          tokens.component.action.horizontalPadding.xsmall,
        (CarpenterDensity.normal, ControlSize.small) =>
          tokens.component.action.horizontalPadding.small,
        (CarpenterDensity.normal, ControlSize.medium) =>
          tokens.component.action.horizontalPadding.medium,
        (CarpenterDensity.normal, ControlSize.large) =>
          tokens.component.action.horizontalPadding.large,
        (CarpenterDensity.normal, ControlSize.xlarge) =>
          tokens.component.action.horizontalPadding.xlarge,
        (CarpenterDensity.compact, ControlSize.xsmall) =>
          tokens.component.action.compactHorizontalPadding.xsmall,
        (CarpenterDensity.compact, ControlSize.small) =>
          tokens.component.action.compactHorizontalPadding.small,
        (CarpenterDensity.compact, ControlSize.medium) =>
          tokens.component.action.compactHorizontalPadding.medium,
        (CarpenterDensity.compact, ControlSize.large) =>
          tokens.component.action.compactHorizontalPadding.large,
        (CarpenterDensity.compact, ControlSize.xlarge) =>
          tokens.component.action.compactHorizontalPadding.xlarge,
      };

  LengthUnit actionVerticalPadding(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.action.verticalPadding.xsmall,
    ControlSize.small => tokens.component.action.verticalPadding.small,
    ControlSize.medium => tokens.component.action.verticalPadding.medium,
    ControlSize.large => tokens.component.action.verticalPadding.large,
    ControlSize.xlarge => tokens.component.action.verticalPadding.xlarge,
  };

  LengthUnit get controlGap => actionGap(ControlSize.medium);
  LengthUnit actionGap(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.action.gap.xsmall,
    ControlSize.small => tokens.component.action.gap.small,
    ControlSize.medium => tokens.component.action.gap.medium,
    ControlSize.large => tokens.component.action.gap.large,
    ControlSize.xlarge => tokens.component.action.gap.xlarge,
  };
  LengthUnit get statusHorizontal => tokens.component.status.horizontalPadding;
  LengthUnit get statusVertical => tokens.component.status.verticalPadding;
  LengthUnit get small => tokens.spacing.small;
  LengthUnit get medium => tokens.spacing.medium;
  LengthUnit get large => tokens.spacing.large;
  LengthUnit get fieldLabelGap => fieldLabelGapFor(FieldSize.medium);
  LengthUnit get fieldSupportingGap => fieldSupportingGapFor(FieldSize.medium);
  LengthUnit get fieldContentGap => fieldContentGapFor(FieldSize.medium);
  LengthUnit get fieldScrollPadding => fieldScrollPaddingFor(FieldSize.medium);
  LengthUnit get selectionLabelGap => selectionLabelGapFor(ControlSize.medium);
  LengthUnit get selectionSupportingGap =>
      selectionSupportingGapFor(ControlSize.medium);
  LengthUnit get selectionGroupGap => tokens.spacing.selection.groupGap;
  LengthUnit get selectionMarkInset => checkboxMarkInset(ControlSize.medium);
  LengthUnit get switchInset => switchInsetFor(ControlSize.medium);
  LengthUnit get overlayViewportInset => tokens.component.overlay.viewportInset;
  LengthUnit get overlayAnchorGap => tokens.component.overlay.anchorGap;
  LengthUnit get overlaySurfacePadding =>
      tokens.component.overlay.surfacePadding;
  LengthUnit get overlayMenuItemHorizontal =>
      tokens.component.menu.itemHorizontalPadding;
  LengthUnit get overlayMenuItemVertical =>
      tokens.component.menu.itemVerticalPadding;
  LengthUnit get overlayMenuItemGap => tokens.component.menu.itemGap;
  LengthUnit get overlayTooltipHorizontal =>
      tokens.component.overlay.tooltipHorizontalPadding;
  LengthUnit get overlayTooltipVertical =>
      tokens.component.overlay.tooltipVerticalPadding;
  LengthUnit get overlayDialogViewportInset =>
      tokens.component.overlay.dialogViewportInset;
  LengthUnit get overlayDialogContentGap =>
      tokens.component.overlay.dialogContentGap;
  LengthUnit get overlayDialogActionGap =>
      tokens.component.overlay.dialogActionGap;
  LengthUnit get overlayToastRegionInset =>
      tokens.component.overlay.toastRegionInset;
  LengthUnit get overlayToastGap => tokens.component.overlay.toastGap;
  LengthUnit get overlayToastContentGap =>
      tokens.component.overlay.toastContentGap;
  LengthUnit get tableHorizontal => tokens.component.table.horizontalPadding;
  LengthUnit get tableVertical => tokens.component.table.verticalPadding;
  LengthUnit get tableCellGap => tokens.component.table.cellGap;
  LengthUnit get tableStateGap => tokens.component.table.stateGap;
  LengthUnit get layoutShell => tokens.spacing.layout.shell;
  LengthUnit get layoutRegion => tokens.spacing.layout.region;
  LengthUnit get layoutPage => tokens.spacing.layout.page;
  LengthUnit get layoutPageCompact => tokens.spacing.layout.pageCompact;
  LengthUnit get layoutHeader => tokens.spacing.layout.header;
  LengthUnit get layoutSection => tokens.spacing.layout.section;
  LengthUnit get layoutToolbar => tokens.spacing.layout.toolbar;

  LengthUnit fieldHorizontal(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.horizontalPadding.xsmall,
    FieldSize.small => tokens.component.field.horizontalPadding.small,
    FieldSize.medium => tokens.component.field.horizontalPadding.medium,
    FieldSize.large => tokens.component.field.horizontalPadding.large,
    FieldSize.xlarge => tokens.component.field.horizontalPadding.xlarge,
  };

  LengthUnit fieldVertical(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.verticalPadding.xsmall,
    FieldSize.small => tokens.component.field.verticalPadding.small,
    FieldSize.medium => tokens.component.field.verticalPadding.medium,
    FieldSize.large => tokens.component.field.verticalPadding.large,
    FieldSize.xlarge => tokens.component.field.verticalPadding.xlarge,
  };

  LengthUnit fieldContentGapFor(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.contentGap.xsmall,
    FieldSize.small => tokens.component.field.contentGap.small,
    FieldSize.medium => tokens.component.field.contentGap.medium,
    FieldSize.large => tokens.component.field.contentGap.large,
    FieldSize.xlarge => tokens.component.field.contentGap.xlarge,
  };

  LengthUnit fieldLabelGapFor(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.labelGap.xsmall,
    FieldSize.small => tokens.component.field.labelGap.small,
    FieldSize.medium => tokens.component.field.labelGap.medium,
    FieldSize.large => tokens.component.field.labelGap.large,
    FieldSize.xlarge => tokens.component.field.labelGap.xlarge,
  };

  LengthUnit fieldSupportingGapFor(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.supportingGap.xsmall,
    FieldSize.small => tokens.component.field.supportingGap.small,
    FieldSize.medium => tokens.component.field.supportingGap.medium,
    FieldSize.large => tokens.component.field.supportingGap.large,
    FieldSize.xlarge => tokens.component.field.supportingGap.xlarge,
  };

  LengthUnit fieldScrollPaddingFor(FieldSize value) => switch (value) {
    FieldSize.xsmall => tokens.component.field.scrollPadding.xsmall,
    FieldSize.small => tokens.component.field.scrollPadding.small,
    FieldSize.medium => tokens.component.field.scrollPadding.medium,
    FieldSize.large => tokens.component.field.scrollPadding.large,
    FieldSize.xlarge => tokens.component.field.scrollPadding.xlarge,
  };

  LengthUnit selectionLabelGapFor(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.labelGap.xsmall,
    ControlSize.small => tokens.component.selection.labelGap.small,
    ControlSize.medium => tokens.component.selection.labelGap.medium,
    ControlSize.large => tokens.component.selection.labelGap.large,
    ControlSize.xlarge => tokens.component.selection.labelGap.xlarge,
  };

  LengthUnit selectionSupportingGapFor(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.supportingGap.xsmall,
    ControlSize.small => tokens.component.selection.supportingGap.small,
    ControlSize.medium => tokens.component.selection.supportingGap.medium,
    ControlSize.large => tokens.component.selection.supportingGap.large,
    ControlSize.xlarge => tokens.component.selection.supportingGap.xlarge,
  };

  LengthUnit checkboxMarkInset(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.checkbox.markInset.xsmall,
    ControlSize.small => tokens.component.selection.checkbox.markInset.small,
    ControlSize.medium => tokens.component.selection.checkbox.markInset.medium,
    ControlSize.large => tokens.component.selection.checkbox.markInset.large,
    ControlSize.xlarge => tokens.component.selection.checkbox.markInset.xlarge,
  };

  LengthUnit radioMarkInset(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.radio.markInset.xsmall,
    ControlSize.small => tokens.component.selection.radio.markInset.small,
    ControlSize.medium => tokens.component.selection.radio.markInset.medium,
    ControlSize.large => tokens.component.selection.radio.markInset.large,
    ControlSize.xlarge => tokens.component.selection.radio.markInset.xlarge,
  };

  LengthUnit switchInsetFor(ControlSize value) => switch (value) {
    ControlSize.xsmall => tokens.component.selection.switchToken.inset.xsmall,
    ControlSize.small => tokens.component.selection.switchToken.inset.small,
    ControlSize.medium => tokens.component.selection.switchToken.inset.medium,
    ControlSize.large => tokens.component.selection.switchToken.inset.large,
    ControlSize.xlarge => tokens.component.selection.switchToken.inset.xlarge,
  };
}

@immutable
final class CarpenterShapeTheme {
  const CarpenterShapeTheme();

  LengthUnit radius(ShapeRole role) => switch (role) {
    ShapeRole.none => tokens.shape.none,
    ShapeRole.rounded => tokens.shape.rounded,
    ShapeRole.circular => tokens.shape.circular,
  };

  LengthUnit radiusForControl(ShapeRole role, ControlSize size) =>
      switch (role) {
        ShapeRole.none => tokens.shape.none,
        ShapeRole.rounded => switch (size) {
          ControlSize.xsmall => tokens.shape.roundedXsmall,
          ControlSize.small => tokens.shape.roundedSmall,
          ControlSize.medium => tokens.shape.rounded,
          ControlSize.large => tokens.shape.roundedLarge,
          ControlSize.xlarge => tokens.shape.roundedXlarge,
        },
        ShapeRole.circular => tokens.shape.circular,
      };

  LengthUnit radiusForAction(ShapeRole role, ControlSize size) =>
      switch (role) {
        ShapeRole.none => tokens.shape.none,
        ShapeRole.rounded => switch (size) {
          ControlSize.xsmall => tokens.component.action.radius.xsmall,
          ControlSize.small => tokens.component.action.radius.small,
          ControlSize.medium => tokens.component.action.radius.medium,
          ControlSize.large => tokens.component.action.radius.large,
          ControlSize.xlarge => tokens.component.action.radius.xlarge,
        },
        ShapeRole.circular => tokens.shape.circular,
      };

  LengthUnit radiusForField(ShapeRole role, FieldSize size) => switch (role) {
    ShapeRole.none => tokens.shape.none,
    ShapeRole.rounded => switch (size) {
      FieldSize.xsmall => tokens.component.field.radius.xsmall,
      FieldSize.small => tokens.component.field.radius.small,
      FieldSize.medium => tokens.component.field.radius.medium,
      FieldSize.large => tokens.component.field.radius.large,
      FieldSize.xlarge => tokens.component.field.radius.xlarge,
    },
    ShapeRole.circular => tokens.shape.circular,
  };

  LengthUnit checkboxRadius(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.selection.checkbox.radius.xsmall,
    ControlSize.small => tokens.component.selection.checkbox.radius.small,
    ControlSize.medium => tokens.component.selection.checkbox.radius.medium,
    ControlSize.large => tokens.component.selection.checkbox.radius.large,
    ControlSize.xlarge => tokens.component.selection.checkbox.radius.xlarge,
  };

  LengthUnit switchRadius(ControlSize size) => switch (size) {
    ControlSize.xsmall => tokens.component.selection.switchToken.radius.xsmall,
    ControlSize.small => tokens.component.selection.switchToken.radius.small,
    ControlSize.medium => tokens.component.selection.switchToken.radius.medium,
    ControlSize.large => tokens.component.selection.switchToken.radius.large,
    ControlSize.xlarge => tokens.component.selection.switchToken.radius.xlarge,
  };

  LengthUnit radiusForStatus(ShapeRole role) => switch (role) {
    ShapeRole.none => tokens.shape.none,
    ShapeRole.rounded => tokens.component.status.roundedRadius,
    ShapeRole.circular => tokens.component.status.circularRadius,
  };

  LengthUnit get controlRadius => radius(ShapeRole.rounded);
  LengthUnit get borderWidth => tokens.border.standard;
  LengthUnit get strongBorderWidth => tokens.border.strong;
  LengthUnit get actionBorderWidth => tokens.component.action.borderWidth;
  LengthUnit get fieldBorderWidth => tokens.component.field.borderWidth;
  LengthUnit get fieldCursorWidth => tokens.component.field.cursorWidth;
  LengthUnit get checkboxBorderWidth =>
      tokens.component.selection.checkbox.borderWidth;
  LengthUnit get checkboxMarkStrokeWidth =>
      tokens.component.selection.checkbox.markStrokeWidth;
  LengthUnit get radioBorderWidth =>
      tokens.component.selection.radio.borderWidth;
  LengthUnit get switchBorderWidth =>
      tokens.component.selection.switchToken.borderWidth;
  LengthUnit get statusRadius => tokens.component.status.radius;
  LengthUnit get menuItemRadius => tokens.component.menu.itemRadius;
  LengthUnit get overlaySurfaceRadius => tokens.component.overlay.surfaceRadius;
  LengthUnit get overlayBorderWidth => tokens.component.overlay.borderWidth;
  LengthUnit get toastRadius => tokens.component.overlay.toastRadius;
  LengthUnit get tableSurfaceRadius => tokens.component.table.surfaceRadius;
  LengthUnit get tableBorderWidth => tokens.component.table.borderWidth;
  LengthUnit get popoverAnchorFocusRadius =>
      tokens.component.popover.anchorFocusRadius;
  LengthUnit get adaptiveRegionBorderWidth =>
      tokens.component.adaptiveRegion.borderWidth;
}

@immutable
final class CarpenterMotionTheme {
  const CarpenterMotionTheme();

  TimeUnit get stateTransition => tokens.motion.state;
  TimeUnit get busyCycle => tokens.motion.busy;
  TimeUnit get loadingCycle => tokens.motion.loading;
  AngleUnit get loadingAngle => tokens.motion.loadingAngle;
  LengthUnit get loadingStripe => tokens.spacing.loading.stripe;
  TimeUnit tooltipDelay(TooltipDelay delay) => switch (delay) {
    TooltipDelay.immediate => tokens.motion.tooltip.immediate,
    TooltipDelay.short => tokens.motion.tooltip.short,
    TooltipDelay.long => tokens.motion.tooltip.long,
  };
  TimeUnit get menuTypeaheadReset => tokens.motion.menu.typeaheadReset;
  TimeUnit toastDuration(ToastDuration duration) => switch (duration) {
    ToastDuration.persistent => tokens.motion.reduced,
    ToastDuration.short => tokens.motion.toast.short,
    ToastDuration.long => tokens.motion.toast.long,
  };
  Curve get stateCurve => switch (tokens.motion.curve) {
    'easeOut' => Curves.easeOut,
    final value => throw StateError('Unsupported motion curve token: $value'),
  };

  Duration transitionDuration(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false
      ? tokens.motion.reduced.toDuration()
      : stateTransition.toDuration();
}

@immutable
final class CarpenterFocusTheme {
  const CarpenterFocusTheme({required this.color});

  final Color color;
  LengthUnit get width => tokens.focus.width;
  LengthUnit get gap => tokens.focus.gap;
}

@immutable
final class CarpenterSurfaceTheme {
  const CarpenterSurfaceTheme({required this.base, required this.subtle});

  final Color base;
  final Color subtle;
}

@immutable
final class CarpenterOverlayTheme {
  const CarpenterOverlayTheme({
    required this.background,
    required this.foreground,
    required this.supporting,
    required this.border,
    required this.hovered,
    required this.selected,
    required this.scrim,
    required this.tooltipBackground,
    required this.tooltipForeground,
  });

  final Color background;
  final Color foreground;
  final Color supporting;
  final Color border;
  final Color hovered;
  final Color selected;
  final Color scrim;
  final Color tooltipBackground;
  final Color tooltipForeground;
}

CarpenterThemeData _fromTokens({
  required Brightness brightness,
  required ContrastMode contrast,
  required CarpenterDensity density,
}) {
  final isDark = brightness == Brightness.dark;

  Color contentColor(ContentColorRole role) => switch ((isDark, role)) {
    (false, ContentColorRole.primary) => tokens.light.content.primary,
    (false, ContentColorRole.secondary) => tokens.light.content.secondary,
    (false, ContentColorRole.muted) => tokens.light.content.muted,
    (false, ContentColorRole.inverse) => tokens.light.content.inverse,
    (false, ContentColorRole.disabled) => tokens.light.content.disabled,
    (true, ContentColorRole.primary) => tokens.dark.content.primary,
    (true, ContentColorRole.secondary) => tokens.dark.content.secondary,
    (true, ContentColorRole.muted) => tokens.dark.content.muted,
    (true, ContentColorRole.inverse) => tokens.dark.content.inverse,
    (true, ContentColorRole.disabled) => tokens.dark.content.disabled,
  };

  CarpenterActionPalette actionPalette(ActionColorRole role) =>
      switch ((isDark, role)) {
        (false, ActionColorRole.neutral) => CarpenterActionPalette(
          normal: tokens.light.action.neutral,
          hovered: tokens.light.action.neutralHover,
          pressed: tokens.light.action.neutralPressed,
          state: tokens.light.action.neutralState,
          strongState: tokens.light.action.neutralStateStrong,
        ),
        (false, ActionColorRole.primary) => CarpenterActionPalette(
          normal: tokens.light.action.primary,
          hovered: tokens.light.action.primaryHover,
          pressed: tokens.light.action.primaryPressed,
          state: tokens.light.action.primaryState,
          strongState: tokens.light.action.primaryStateStrong,
        ),
        (false, ActionColorRole.utility) => CarpenterActionPalette(
          normal: tokens.light.action.utility,
          hovered: tokens.light.action.utilityHover,
          pressed: tokens.light.action.utilityPressed,
          state: tokens.light.action.utilityState,
          strongState: tokens.light.action.utilityStateStrong,
        ),
        (false, ActionColorRole.danger) => CarpenterActionPalette(
          normal: tokens.light.action.danger,
          hovered: tokens.light.action.dangerHover,
          pressed: tokens.light.action.dangerPressed,
          state: tokens.light.action.dangerState,
          strongState: tokens.light.action.dangerStateStrong,
        ),
        (false, ActionColorRole.warning) => CarpenterActionPalette(
          normal: tokens.light.action.warning,
          hovered: tokens.light.action.warningHover,
          pressed: tokens.light.action.warningPressed,
          state: tokens.light.action.warningState,
          strongState: tokens.light.action.warningStateStrong,
        ),
        (false, ActionColorRole.success) => CarpenterActionPalette(
          normal: tokens.light.action.success,
          hovered: tokens.light.action.successHover,
          pressed: tokens.light.action.successPressed,
          state: tokens.light.action.successState,
          strongState: tokens.light.action.successStateStrong,
        ),
        (false, ActionColorRole.info) => CarpenterActionPalette(
          normal: tokens.light.action.info,
          hovered: tokens.light.action.infoHover,
          pressed: tokens.light.action.infoPressed,
          state: tokens.light.action.infoState,
          strongState: tokens.light.action.infoStateStrong,
        ),
        (true, ActionColorRole.neutral) => CarpenterActionPalette(
          normal: tokens.dark.action.neutral,
          hovered: tokens.dark.action.neutralHover,
          pressed: tokens.dark.action.neutralPressed,
          state: tokens.dark.action.neutralState,
          strongState: tokens.dark.action.neutralStateStrong,
        ),
        (true, ActionColorRole.primary) => CarpenterActionPalette(
          normal: tokens.dark.action.primary,
          hovered: tokens.dark.action.primaryHover,
          pressed: tokens.dark.action.primaryPressed,
          state: tokens.dark.action.primaryState,
          strongState: tokens.dark.action.primaryStateStrong,
        ),
        (true, ActionColorRole.utility) => CarpenterActionPalette(
          normal: tokens.dark.action.utility,
          hovered: tokens.dark.action.utilityHover,
          pressed: tokens.dark.action.utilityPressed,
          state: tokens.dark.action.utilityState,
          strongState: tokens.dark.action.utilityStateStrong,
        ),
        (true, ActionColorRole.danger) => CarpenterActionPalette(
          normal: tokens.dark.action.danger,
          hovered: tokens.dark.action.dangerHover,
          pressed: tokens.dark.action.dangerPressed,
          state: tokens.dark.action.dangerState,
          strongState: tokens.dark.action.dangerStateStrong,
        ),
        (true, ActionColorRole.warning) => CarpenterActionPalette(
          normal: tokens.dark.action.warning,
          hovered: tokens.dark.action.warningHover,
          pressed: tokens.dark.action.warningPressed,
          state: tokens.dark.action.warningState,
          strongState: tokens.dark.action.warningStateStrong,
        ),
        (true, ActionColorRole.success) => CarpenterActionPalette(
          normal: tokens.dark.action.success,
          hovered: tokens.dark.action.successHover,
          pressed: tokens.dark.action.successPressed,
          state: tokens.dark.action.successState,
          strongState: tokens.dark.action.successStateStrong,
        ),
        (true, ActionColorRole.info) => CarpenterActionPalette(
          normal: tokens.dark.action.info,
          hovered: tokens.dark.action.infoHover,
          pressed: tokens.dark.action.infoPressed,
          state: tokens.dark.action.infoState,
          strongState: tokens.dark.action.infoStateStrong,
        ),
      };

  CarpenterFeedbackStyle feedbackStyle(FeedbackColorRole role) {
    return switch ((isDark, role)) {
      (false, FeedbackColorRole.neutral) => CarpenterFeedbackStyle(
        background: tokens.light.feedback.neutralBackground,
        foreground: tokens.light.feedback.neutralForeground,
      ),
      (false, FeedbackColorRole.success) => CarpenterFeedbackStyle(
        background: tokens.light.feedback.successBackground,
        foreground: tokens.light.feedback.successForeground,
      ),
      (false, FeedbackColorRole.warning) => CarpenterFeedbackStyle(
        background: tokens.light.feedback.warningBackground,
        foreground: tokens.light.feedback.warningForeground,
      ),
      (false, FeedbackColorRole.danger) => CarpenterFeedbackStyle(
        background: tokens.light.feedback.dangerBackground,
        foreground: tokens.light.feedback.dangerForeground,
      ),
      (false, FeedbackColorRole.info) => CarpenterFeedbackStyle(
        background: tokens.light.feedback.infoBackground,
        foreground: tokens.light.feedback.infoForeground,
      ),
      (true, FeedbackColorRole.neutral) => CarpenterFeedbackStyle(
        background: tokens.dark.feedback.neutralBackground,
        foreground: tokens.dark.feedback.neutralForeground,
      ),
      (true, FeedbackColorRole.success) => CarpenterFeedbackStyle(
        background: tokens.dark.feedback.successBackground,
        foreground: tokens.dark.feedback.successForeground,
      ),
      (true, FeedbackColorRole.warning) => CarpenterFeedbackStyle(
        background: tokens.dark.feedback.warningBackground,
        foreground: tokens.dark.feedback.warningForeground,
      ),
      (true, FeedbackColorRole.danger) => CarpenterFeedbackStyle(
        background: tokens.dark.feedback.dangerBackground,
        foreground: tokens.dark.feedback.dangerForeground,
      ),
      (true, FeedbackColorRole.info) => CarpenterFeedbackStyle(
        background: tokens.dark.feedback.infoBackground,
        foreground: tokens.dark.feedback.infoForeground,
      ),
    };
  }

  CarpenterSelectionPalette selectionPalette(SelectionColorRole role) =>
      switch ((isDark, role)) {
        (false, SelectionColorRole.neutral) => CarpenterSelectionPalette(
          selected: tokens.light.selection.neutralSelected,
          selectedHovered: tokens.light.selection.neutralSelectedHovered,
          mark: tokens.light.selection.neutralMark,
        ),
        (false, SelectionColorRole.primary) => CarpenterSelectionPalette(
          selected: tokens.light.selection.primarySelected,
          selectedHovered: tokens.light.selection.primarySelectedHovered,
          mark: tokens.light.selection.primaryMark,
        ),
        (false, SelectionColorRole.utility) => CarpenterSelectionPalette(
          selected: tokens.light.selection.utilitySelected,
          selectedHovered: tokens.light.selection.utilitySelectedHovered,
          mark: tokens.light.selection.utilityMark,
        ),
        (false, SelectionColorRole.danger) => CarpenterSelectionPalette(
          selected: tokens.light.selection.dangerSelected,
          selectedHovered: tokens.light.selection.dangerSelectedHovered,
          mark: tokens.light.selection.dangerMark,
        ),
        (false, SelectionColorRole.warning) => CarpenterSelectionPalette(
          selected: tokens.light.selection.warningSelected,
          selectedHovered: tokens.light.selection.warningSelectedHovered,
          mark: tokens.light.selection.warningMark,
        ),
        (false, SelectionColorRole.success) => CarpenterSelectionPalette(
          selected: tokens.light.selection.successSelected,
          selectedHovered: tokens.light.selection.successSelectedHovered,
          mark: tokens.light.selection.successMark,
        ),
        (false, SelectionColorRole.info) => CarpenterSelectionPalette(
          selected: tokens.light.selection.infoSelected,
          selectedHovered: tokens.light.selection.infoSelectedHovered,
          mark: tokens.light.selection.infoMark,
        ),
        (true, SelectionColorRole.neutral) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.neutralSelected,
          selectedHovered: tokens.dark.selection.neutralSelectedHovered,
          mark: tokens.dark.selection.neutralMark,
        ),
        (true, SelectionColorRole.primary) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.primarySelected,
          selectedHovered: tokens.dark.selection.primarySelectedHovered,
          mark: tokens.dark.selection.primaryMark,
        ),
        (true, SelectionColorRole.utility) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.utilitySelected,
          selectedHovered: tokens.dark.selection.utilitySelectedHovered,
          mark: tokens.dark.selection.utilityMark,
        ),
        (true, SelectionColorRole.danger) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.dangerSelected,
          selectedHovered: tokens.dark.selection.dangerSelectedHovered,
          mark: tokens.dark.selection.dangerMark,
        ),
        (true, SelectionColorRole.warning) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.warningSelected,
          selectedHovered: tokens.dark.selection.warningSelectedHovered,
          mark: tokens.dark.selection.warningMark,
        ),
        (true, SelectionColorRole.success) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.successSelected,
          selectedHovered: tokens.dark.selection.successSelectedHovered,
          mark: tokens.dark.selection.successMark,
        ),
        (true, SelectionColorRole.info) => CarpenterSelectionPalette(
          selected: tokens.dark.selection.infoSelected,
          selectedHovered: tokens.dark.selection.infoSelectedHovered,
          mark: tokens.dark.selection.infoMark,
        ),
      };

  final focusColor = contrast == ContrastMode.high
      ? (isDark
            ? tokens.dark.focus.highContrast
            : tokens.light.focus.highContrast)
      : (isDark ? tokens.dark.focus.standard : tokens.light.focus.standard);

  return CarpenterThemeData._(
    brightness: brightness,
    contrast: contrast,
    density: density,
    typography: const CarpenterTypographyTheme(),
    content: CarpenterContentTheme(
      primary: contentColor(ContentColorRole.primary),
      secondary: contentColor(ContentColorRole.secondary),
      muted: contentColor(ContentColorRole.muted),
      inverse: contentColor(ContentColorRole.inverse),
      disabled: contentColor(ContentColorRole.disabled),
    ),
    actions: CarpenterActionTheme(
      neutral: actionPalette(ActionColorRole.neutral),
      primary: actionPalette(ActionColorRole.primary),
      utility: actionPalette(ActionColorRole.utility),
      danger: actionPalette(ActionColorRole.danger),
      warning: actionPalette(ActionColorRole.warning),
      success: actionPalette(ActionColorRole.success),
      info: actionPalette(ActionColorRole.info),
      transparent: tokens.palette.transparent,
      inverse: contentColor(ContentColorRole.inverse),
      disabledBackground: isDark
          ? tokens.dark.action.disabledBackground
          : tokens.light.action.disabledBackground,
      disabledForeground: isDark
          ? tokens.dark.action.disabledForeground
          : tokens.light.action.disabledForeground,
    ),
    fields: CarpenterFieldTheme(
      background: isDark
          ? tokens.dark.field.background
          : tokens.light.field.background,
      backgroundHovered: isDark
          ? tokens.dark.field.backgroundHovered
          : tokens.light.field.backgroundHovered,
      backgroundDisabled: isDark
          ? tokens.dark.field.backgroundDisabled
          : tokens.light.field.backgroundDisabled,
      foreground: isDark
          ? tokens.dark.field.foreground
          : tokens.light.field.foreground,
      placeholder: isDark
          ? tokens.dark.field.placeholder
          : tokens.light.field.placeholder,
      border: isDark ? tokens.dark.field.border : tokens.light.field.border,
      borderHovered: isDark
          ? tokens.dark.field.borderHovered
          : tokens.light.field.borderHovered,
      borderFocused: contrast == ContrastMode.high
          ? focusColor
          : isDark
          ? tokens.dark.field.borderFocused
          : tokens.light.field.borderFocused,
      borderError: isDark
          ? tokens.dark.field.borderError
          : tokens.light.field.borderError,
      label: isDark ? tokens.dark.field.label : tokens.light.field.label,
      supporting: isDark
          ? tokens.dark.field.supporting
          : tokens.light.field.supporting,
      error: isDark ? tokens.dark.field.error : tokens.light.field.error,
      icon: isDark ? tokens.dark.field.icon : tokens.light.field.icon,
      selection: isDark
          ? tokens.dark.field.selection
          : tokens.light.field.selection,
      disabledForeground: contentColor(ContentColorRole.disabled),
    ),
    selection: CarpenterSelectionTheme(
      {
        for (final role in SelectionColorRole.values)
          role: selectionPalette(role),
      },
      foreground: isDark
          ? tokens.dark.selection.foreground
          : tokens.light.selection.foreground,
      supporting: isDark
          ? tokens.dark.selection.supporting
          : tokens.light.selection.supporting,
      disabledForeground: isDark
          ? tokens.dark.selection.disabledForeground
          : tokens.light.selection.disabledForeground,
      background: isDark
          ? tokens.dark.selection.background
          : tokens.light.selection.background,
      backgroundHovered: isDark
          ? tokens.dark.selection.backgroundHovered
          : tokens.light.selection.backgroundHovered,
      border: isDark
          ? tokens.dark.selection.border
          : tokens.light.selection.border,
      borderHovered: isDark
          ? tokens.dark.selection.borderHovered
          : tokens.light.selection.borderHovered,
      disabledBackground: isDark
          ? tokens.dark.selection.disabledBackground
          : tokens.light.selection.disabledBackground,
      disabledBorder: isDark
          ? tokens.dark.selection.disabledBorder
          : tokens.light.selection.disabledBorder,
      disabledSelected: isDark
          ? tokens.dark.selection.disabledSelected
          : tokens.light.selection.disabledSelected,
      disabledMark: isDark
          ? tokens.dark.selection.disabledMark
          : tokens.light.selection.disabledMark,
    ),
    feedback: CarpenterFeedbackTheme({
      for (final role in FeedbackColorRole.values) role: feedbackStyle(role),
    }),
    sizes: CarpenterSizeTheme(minimumTarget: tokens.size.target.minimum),
    spacing: CarpenterSpacingTheme(density),
    shapes: const CarpenterShapeTheme(),
    motion: const CarpenterMotionTheme(),
    focus: CarpenterFocusTheme(color: focusColor),
    surface: CarpenterSurfaceTheme(
      base: isDark
          ? tokens.dark.surface.baseToken
          : tokens.light.surface.baseToken,
      subtle: isDark ? tokens.dark.surface.subtle : tokens.light.surface.subtle,
    ),
    overlay: CarpenterOverlayTheme(
      background: isDark
          ? tokens.dark.overlay.background
          : tokens.light.overlay.background,
      foreground: isDark
          ? tokens.dark.overlay.foreground
          : tokens.light.overlay.foreground,
      supporting: isDark
          ? tokens.dark.overlay.supporting
          : tokens.light.overlay.supporting,
      border: isDark ? tokens.dark.overlay.border : tokens.light.overlay.border,
      hovered: isDark
          ? tokens.dark.overlay.hovered
          : tokens.light.overlay.hovered,
      selected: isDark
          ? tokens.dark.overlay.selected
          : tokens.light.overlay.selected,
      scrim: isDark ? tokens.dark.overlay.scrim : tokens.light.overlay.scrim,
      tooltipBackground: isDark
          ? tokens.dark.overlay.tooltipBackground
          : tokens.light.overlay.tooltipBackground,
      tooltipForeground: isDark
          ? tokens.dark.overlay.tooltipForeground
          : tokens.light.overlay.tooltipForeground,
    ),
  );
}
