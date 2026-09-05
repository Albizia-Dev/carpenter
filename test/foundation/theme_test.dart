import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  double contrast(Color first, Color second) {
    final firstLuminance = first.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter = firstLuminance > secondLuminance
        ? firstLuminance
        : secondLuminance;
    final darker = firstLuminance > secondLuminance
        ? secondLuminance
        : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  for (final theme in [
    CarpenterThemeData.light(),
    CarpenterThemeData.light(contrast: ContrastMode.high),
    CarpenterThemeData.dark(),
    CarpenterThemeData.dark(contrast: ContrastMode.high),
  ]) {
    test('${theme.brightness.name}/${theme.contrast.name} semantic pairs', () {
      for (final role in ActionColorRole.values) {
        final style = theme.actions.resolve(
          role,
          ActionProminence.filled,
          const <WidgetState>{},
        );
        expect(
          contrast(style.background, style.foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'filled-prominence ${role.name}',
        );
      }
      for (final role in FeedbackColorRole.values) {
        final style = theme.feedback.resolve(role);
        expect(
          contrast(style.background, style.foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'feedback ${role.name}',
        );
      }
      expect(
        contrast(theme.overlay.background, theme.overlay.foreground),
        greaterThanOrEqualTo(4.5),
        reason: 'overlay surface',
      );
      expect(
        contrast(
          theme.overlay.tooltipBackground,
          theme.overlay.tooltipForeground,
        ),
        greaterThanOrEqualTo(4.5),
        reason: 'tooltip surface',
      );
    });
  }

  test('compact density reduces spacing across component families', () {
    final normal = CarpenterThemeData.light();
    final compact = CarpenterThemeData.light(density: CarpenterDensity.compact);

    expect(
      compact.spacing.controlHorizontal(ControlSize.medium).value,
      lessThan(normal.spacing.controlHorizontal(ControlSize.medium).value),
    );
    expect(
      compact.spacing.actionGap(ControlSize.medium).value,
      lessThan(normal.spacing.actionGap(ControlSize.medium).value),
    );
    expect(
      compact.spacing.fieldHorizontal(FieldSize.medium).value,
      lessThan(normal.spacing.fieldHorizontal(FieldSize.medium).value),
    );
    expect(
      compact.spacing.fieldVertical(FieldSize.medium).value,
      lessThan(normal.spacing.fieldVertical(FieldSize.medium).value),
    );
    expect(
      compact.spacing.fieldContentGapFor(FieldSize.medium).value,
      lessThan(normal.spacing.fieldContentGapFor(FieldSize.medium).value),
    );
    expect(
      compact.spacing.selectionLabelGapFor(ControlSize.medium).value,
      lessThan(normal.spacing.selectionLabelGapFor(ControlSize.medium).value),
    );
    expect(
      compact.spacing.selectionGroupGap.value,
      lessThan(normal.spacing.selectionGroupGap.value),
    );
    expect(
      compact.spacing.statusHorizontal.value,
      lessThan(normal.spacing.statusHorizontal.value),
    );
    expect(
      compact.spacing.overlayMenuItemHorizontal.value,
      lessThan(normal.spacing.overlayMenuItemHorizontal.value),
    );
    expect(
      compact.spacing.overlayMenuItemVertical.value,
      lessThan(normal.spacing.overlayMenuItemVertical.value),
    );
    expect(
      compact.spacing.tableHorizontal.value,
      lessThan(normal.spacing.tableHorizontal.value),
    );
    expect(
      compact.spacing.tableVertical.value,
      lessThan(normal.spacing.tableVertical.value),
    );
    expect(
      compact.spacing.layoutToolbar.value,
      lessThan(normal.spacing.layoutToolbar.value),
    );

    expect(
      compact.sizes.control(ControlSize.medium),
      normal.sizes.control(ControlSize.medium),
    );
    expect(compact.sizes.minimumTarget, normal.sizes.minimumTarget);
  });

  test('extra size roles extend control and icon scales', () {
    final theme = CarpenterThemeData.light();
    expect(
      theme.sizes.control(ControlSize.xsmall).value,
      lessThan(theme.sizes.control(ControlSize.small).value),
    );
    expect(
      theme.sizes.control(ControlSize.xlarge).value,
      greaterThan(theme.sizes.control(ControlSize.large).value),
    );
    expect(
      theme.sizes.icon(IconSize.xsmall).value,
      lessThan(theme.sizes.icon(IconSize.small).value),
    );
    expect(
      theme.sizes.icon(IconSize.xlarge).value,
      greaterThan(theme.sizes.icon(IconSize.large).value),
    );
  });

  test('field and selection size roles are monotonic and token backed', () {
    final theme = CarpenterThemeData.light();
    expect(
      theme.sizes.field(FieldSize.xsmall).value,
      lessThan(theme.sizes.field(FieldSize.small).value),
    );
    expect(
      theme.sizes.field(FieldSize.xlarge).value,
      greaterThan(theme.sizes.field(FieldSize.large).value),
    );
    expect(
      theme.sizes.selectionIndicator(ControlSize.xsmall).value,
      lessThan(theme.sizes.selectionIndicator(ControlSize.xlarge).value),
    );
  });

  test('same-role control dimensions remain composition compatible', () {
    final theme = CarpenterThemeData.light();
    for (var index = 0; index < ControlSize.values.length; index++) {
      final controlSize = ControlSize.values[index];
      final fieldSize = FieldSize.values[index];
      expect(
        theme.sizes.fieldHeight(fieldSize),
        theme.sizes.actionHeight(controlSize),
        reason: '${controlSize.name} field and action height tokens',
      );
      expect(
        theme.sizes.checkboxSize(controlSize).value,
        lessThanOrEqualTo(theme.sizes.actionHeight(controlSize).value),
      );
      expect(
        theme.sizes.radioSize(controlSize).value,
        lessThanOrEqualTo(theme.sizes.actionHeight(controlSize).value),
      );
      expect(
        theme.sizes.switchHeight(controlSize).value,
        lessThanOrEqualTo(theme.sizes.actionHeight(controlSize).value),
      );
    }
  });

  testWidgets('component dimensions and child typography are token backed', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    for (final size in ControlSize.values) {
      expect(theme.sizes.actionHeight(size).value, greaterThan(0));
      expect(theme.sizes.actionIcon(size).value, greaterThan(0));
      expect(theme.spacing.actionHorizontalPadding(size).value, greaterThan(0));
      expect(theme.spacing.actionGap(size).value, greaterThan(0));
      expect(
        theme.shapes.radiusForAction(ShapeRole.rounded, size).value,
        greaterThanOrEqualTo(0),
      );
      expect(theme.sizes.checkboxSize(size).value, greaterThan(0));
      expect(theme.sizes.radioSize(size).value, greaterThan(0));
      expect(theme.sizes.switchWidth(size).value, greaterThan(0));
      expect(theme.sizes.switchHeight(size).value, greaterThan(0));
      expect(theme.spacing.checkboxMarkInset(size).value, greaterThan(0));
      expect(theme.spacing.radioMarkInset(size).value, greaterThan(0));
      expect(theme.spacing.switchInsetFor(size).value, greaterThan(0));
    }
    for (final size in FieldSize.values) {
      expect(theme.sizes.fieldHeight(size).value, greaterThan(0));
      expect(theme.sizes.fieldIcon(size).value, greaterThan(0));
      expect(theme.spacing.fieldHorizontal(size).value, greaterThan(0));
      expect(theme.spacing.fieldVertical(size).value, greaterThan(0));
      expect(theme.spacing.fieldContentGapFor(size).value, greaterThan(0));
      expect(theme.spacing.fieldLabelGapFor(size).value, greaterThan(0));
      expect(theme.spacing.fieldSupportingGapFor(size).value, greaterThan(0));
      expect(theme.spacing.fieldScrollPaddingFor(size).value, greaterThan(0));
    }

    await tester.pumpWidget(
      carpenterHarness(
        Builder(
          builder: (context) {
            for (final size in ControlSize.values) {
              expect(
                theme.typography
                    .action(context, size, TypographyEmphasis.medium)
                    .fontSize,
                greaterThan(0),
              );
              expect(
                theme.typography
                    .selectionLabel(context, size, TypographyEmphasis.medium)
                    .fontSize,
                greaterThan(0),
              );
            }
            for (final size in FieldSize.values) {
              expect(
                theme.typography
                    .fieldInput(context, size, TypographyEmphasis.regular)
                    .fontSize,
                greaterThan(0),
              );
              expect(
                theme.typography
                    .fieldLabel(context, size, TypographyEmphasis.medium)
                    .fontSize,
                greaterThan(0),
              );
              expect(
                theme.typography
                    .fieldSupporting(context, size, TypographyEmphasis.regular)
                    .fontSize,
                greaterThan(0),
              );
            }
            expect(
              theme.typography
                  .tableHeader(context, TypographyEmphasis.strong)
                  .fontSize,
              greaterThan(0),
            );
            expect(
              theme.typography
                  .tableCell(context, TypographyEmphasis.regular)
                  .fontSize,
              greaterThan(0),
            );
            return const SizedBox.shrink();
          },
        ),
        theme: theme,
      ),
    );
  });

  test('field and selection state resolution remains semantic', () {
    final theme = CarpenterThemeData.light();
    final focused = theme.fields.resolve(
      availability: FieldAvailability.enabled,
      states: const {WidgetState.focused},
      hasError: false,
    );
    final error = theme.fields.resolve(
      availability: FieldAvailability.enabled,
      states: const {WidgetState.error},
      hasError: true,
    );
    final selected = theme.selection.resolve(
      role: SelectionColorRole.primary,
      selected: true,
      states: const {},
    );
    expect(focused.border, theme.fields.borderFocused);
    expect(error.border, theme.fields.borderError);
    expect(selected.mark, isNot(theme.actions.transparent));
  });

  test('selection color roles resolve to distinct selected colors', () {
    for (final theme in [
      CarpenterThemeData.light(),
      CarpenterThemeData.dark(),
    ]) {
      final selectedColors = {
        for (final role in SelectionColorRole.values)
          theme.selection
              .resolve(role: role, selected: true, states: const {})
              .background,
      };
      expect(selectedColors, hasLength(SelectionColorRole.values.length));
    }
  });

  test('rounded radii scale with field and control size roles', () {
    final shapes = CarpenterThemeData.light().shapes;
    expect(
      shapes.radiusForControl(ShapeRole.rounded, ControlSize.xsmall).value,
      lessThan(
        shapes.radiusForControl(ShapeRole.rounded, ControlSize.xlarge).value,
      ),
    );
    expect(
      shapes.radiusForField(ShapeRole.rounded, FieldSize.xsmall).value,
      lessThan(
        shapes.radiusForField(ShapeRole.rounded, FieldSize.xlarge).value,
      ),
    );
  });

  test('loading rotation is a typed angle token', () {
    expect(CarpenterThemeData.light().motion.loadingAngle, const Degrees(45));
  });

  test('S3B overlay and transient motion remain token backed', () {
    final light = CarpenterThemeData.light();
    final dark = CarpenterThemeData.dark();
    expect(light.overlay.selected, isNot(light.overlay.hovered));
    expect(dark.overlay.scrim, isNot(light.overlay.scrim));
    expect(
      light.motion.toastDuration(ToastDuration.long).value,
      greaterThan(light.motion.toastDuration(ToastDuration.short).value),
    );
  });

  test('action prominence preserves distinct background contracts', () {
    final actions = CarpenterThemeData.light().actions;
    const rest = <WidgetState>{};
    const hovered = <WidgetState>{WidgetState.hovered};

    final low = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.low,
      rest,
    );
    final normal = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.normal,
      rest,
    );
    final high = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.high,
      rest,
    );
    final filled = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.filled,
      rest,
    );
    final ghost = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.ghost,
      rest,
    );
    final hoveredGhost = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.ghost,
      hovered,
    );
    final outlined = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.outlined,
      rest,
    );

    expect(low.background, isNot(actions.transparent));
    expect(normal.background, isNot(low.background));
    expect(high.background, isNot(normal.background));
    expect(filled.background, isNot(high.background));
    expect(ghost.background, actions.transparent);
    expect(hoveredGhost.background, isNot(actions.transparent));
    expect(outlined.background, actions.transparent);
    expect(outlined.border, isNot(actions.transparent));
  });

  test('utility is a complete action color role', () {
    for (final theme in [
      CarpenterThemeData.light(),
      CarpenterThemeData.dark(),
    ]) {
      for (final prominence in ActionProminence.values) {
        final style = theme.actions.resolve(
          ActionColorRole.utility,
          prominence,
          const <WidgetState>{WidgetState.hovered},
        );
        expect(style.foreground, isNot(theme.actions.transparent));
        expect(style.loadingAccent, isNot(theme.actions.transparent));
      }
    }
  });

  test('normal and interactive backgrounds retain each action tone', () {
    for (final theme in [
      CarpenterThemeData.light(),
      CarpenterThemeData.dark(),
    ]) {
      final restBackgrounds = <Color>{};
      final hoverBackgrounds = <Color>{};
      for (final role in ActionColorRole.values) {
        restBackgrounds.add(
          theme.actions
              .resolve(role, ActionProminence.normal, const <WidgetState>{})
              .background,
        );
        hoverBackgrounds.add(
          theme.actions.resolve(
            role,
            ActionProminence.ghost,
            const <WidgetState>{WidgetState.hovered},
          ).background,
        );
      }
      expect(restBackgrounds, hasLength(ActionColorRole.values.length));
      expect(hoverBackgrounds, hasLength(ActionColorRole.values.length));
    }
  });
}
