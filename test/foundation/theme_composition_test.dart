import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for semantic role composition at application level.
void main() {
  test(
    'semantic theme composition preserves mode and replaces selected roles',
    () {
      final base = CarpenterThemeData.light(density: CarpenterDensity.compact);
      const brand = Color(0xFF2688D9);
      const surface = Color(0xFFF3F3F3);

      final composed = base.copyWith(
        content: base.content.copyWith(primary: brand),
        actions: base.actions.copyWith(
          primary: base.actions.primary.copyWith(normal: brand),
        ),
        fields: base.fields.copyWith(borderFocused: brand),
        selection: base.selection.copyWith(
          palettes: {
            SelectionColorRole.primary: base.selection
                .palette(SelectionColorRole.primary)
                .copyWith(selected: brand),
          },
        ),
        feedback: base.feedback.copyWith(
          styles: {
            FeedbackColorRole.info: base.feedback
                .resolve(FeedbackColorRole.info)
                .copyWith(foreground: brand),
          },
        ),
        focus: base.focus.copyWith(color: brand),
        surface: base.surface.copyWith(base: surface),
        overlay: base.overlay.copyWith(border: brand),
      );

      expect(composed.brightness, base.brightness);
      expect(composed.contrast, base.contrast);
      expect(composed.density, base.density);
      expect(composed.content.primary, brand);
      expect(composed.actions.primary.normal, brand);
      expect(composed.fields.borderFocused, brand);
      expect(
        composed.selection.palette(SelectionColorRole.primary).selected,
        brand,
      );
      expect(
        composed.feedback.resolve(FeedbackColorRole.info).foreground,
        brand,
      );
      expect(composed.focus.color, brand);
      expect(composed.surface.base, surface);
      expect(composed.overlay.border, brand);
      expect(identical(composed.spacing, base.spacing), isTrue);
      expect(identical(composed.motion, base.motion), isTrue);
    },
  );

  test('partial palette maps preserve untouched semantic roles', () {
    final base = CarpenterThemeData.dark();
    const replacement = Color(0xFF33CC82);

    final selection = base.selection.copyWith(
      palettes: {
        SelectionColorRole.success: base.selection
            .palette(SelectionColorRole.success)
            .copyWith(mark: replacement),
      },
    );
    final feedback = base.feedback.copyWith(
      styles: {
        FeedbackColorRole.success: base.feedback
            .resolve(FeedbackColorRole.success)
            .copyWith(background: replacement),
      },
    );

    expect(selection.palette(SelectionColorRole.success).mark, replacement);
    expect(
      selection.palette(SelectionColorRole.danger).selected,
      base.selection.palette(SelectionColorRole.danger).selected,
    );
    expect(feedback.resolve(FeedbackColorRole.success).background, replacement);
    expect(
      feedback.resolve(FeedbackColorRole.danger).background,
      base.feedback.resolve(FeedbackColorRole.danger).background,
    );
  });
}
