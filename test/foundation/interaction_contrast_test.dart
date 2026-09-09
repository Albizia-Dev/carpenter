import 'dart:math' as math;
import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color foreground, Color background) {
  final visible = Color.alphaBlend(foreground, background);
  final a = visible.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + .05) / (math.min(a, b) + .05);
}

void main() {
  // Exhaustive powerset: simultaneous states must be tested too, e.g.
  // hover + focus + press and selected + disabled. Alpha is composited first.
  const states = [
    WidgetState.hovered,
    WidgetState.focused,
    WidgetState.pressed,
    WidgetState.selected,
    WidgetState.disabled,
    WidgetState.error,
  ];
  for (final brightness in Brightness.values) {
    for (final density in CarpenterDensity.values) {
      for (final mode in ContrastMode.values) {
        test(
          '${brightness.name}/${density.name}/${mode.name}: all interaction combinations',
          () {
            final theme = brightness == Brightness.light
                ? CarpenterThemeData.light(contrast: mode, density: density)
                : CarpenterThemeData.dark(contrast: mode, density: density);
            final failures = <String>[];
            void check(
              String label,
              Color foreground,
              Color background,
              double minimum,
            ) {
              final ratio = _contrast(foreground, background);
              if (ratio + .001 < minimum) {
                failures.add('$label: ${ratio.toStringAsFixed(2)} < $minimum');
              }
            }

            final surfaces = {
              'base': theme.surface.base,
              'subtle': theme.surface.subtle,
              'overlay': theme.overlay.background,
            };
            for (var mask = 0; mask < 1 << states.length; mask++) {
              final state = {
                for (var i = 0; i < states.length; i++)
                  if (mask & (1 << i) != 0) states[i],
              };
              for (final surface in surfaces.entries) {
                final suffix = '${surface.key}/$mask';
                for (final role in ActionColorRole.values) {
                  for (final prominence in ActionProminence.values) {
                    final style = theme.actions.resolve(
                      role,
                      prominence,
                      state,
                    );
                    final background = Color.alphaBlend(
                      style.background,
                      surface.value,
                    );
                    check(
                      'action/${role.name}/${prominence.name}/$suffix',
                      style.foreground,
                      background,
                      4.5,
                    );
                    check(
                      'running text/${role.name}/${prominence.name}/$suffix',
                      style.foreground,
                      Color.alphaBlend(style.loadingAccent, background),
                      4.5,
                    );
                    check(
                      'action icon/${role.name}/${prominence.name}/$suffix',
                      style.icon,
                      background,
                      3,
                    );
                  }
                }
                for (final role in SelectionColorRole.values) {
                  for (final selected in [false, true]) {
                    final style = theme.selection.resolve(
                      role: role,
                      selected: selected,
                      states: state,
                    );
                    final background = Color.alphaBlend(
                      style.background,
                      surface.value,
                    );
                    check(
                      'selection label/${role.name}/$selected/$suffix',
                      style.foreground,
                      surface.value,
                      4.5,
                    );
                    check(
                      'selection description/${role.name}/$selected/$suffix',
                      style.supporting,
                      surface.value,
                      4.5,
                    );
                    check(
                      'selection boundary/${role.name}/$selected/$suffix',
                      style.border,
                      surface.value,
                      3,
                    );
                    if (selected) {
                      check(
                        'selection mark/${role.name}/$suffix',
                        style.mark,
                        background,
                        3,
                      );
                    }
                  }
                }
                for (final availability in FieldAvailability.values) {
                  for (final error in [false, true]) {
                    final style = theme.fields.resolve(
                      availability: availability,
                      states: state,
                      hasError: error,
                    );
                    final background = Color.alphaBlend(
                      style.background,
                      surface.value,
                    );
                    for (final pair in {
                      'value': style.foreground,
                      'placeholder': style.placeholder,
                    }.entries) {
                      check(
                        'field/${availability.name}/${pair.key}/$error/$suffix',
                        pair.value,
                        background,
                        4.5,
                      );
                    }
                    check(
                      'field border/${availability.name}/$error/$suffix',
                      style.border,
                      background,
                      3,
                    );
                    for (final pair in {
                      'label': style.label,
                      'supporting': style.supporting,
                      'error': style.error,
                    }.entries) {
                      check(
                        'field/${availability.name}/${pair.key}/$error/$suffix',
                        pair.value,
                        surface.value,
                        4.5,
                      );
                    }
                  }
                }
                check('focus/$suffix', theme.focus.color, surface.value, 3);
              }
            }
            for (final role in FeedbackColorRole.values) {
              final feedback = theme.feedback.resolve(role);
              check(
                'feedback/${role.name}',
                feedback.foreground,
                feedback.background,
                4.5,
              );
              check(
                'notice/${role.name}',
                feedback.foreground,
                theme.overlay.background,
                4.5,
              );
            }
            final progress = theme.actions
                .resolve(ActionColorRole.primary, ActionProminence.filled, {})
                .background;
            check('progress/track', progress, theme.surface.subtle, 3);
            expect(
              failures.take(30).toList(),
              isEmpty,
              reason: '${failures.length} contrast failures',
            );
          },
        );
      }
    }
  }
}
