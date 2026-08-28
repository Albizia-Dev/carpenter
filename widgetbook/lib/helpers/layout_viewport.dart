import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

enum LayoutViewportPreset {
  off,
  mobilePortrait,
  mobileLandscape,
  tabletPortrait,
  tabletLandscape,
  desktopSmall,
  desktopLarge,
}

extension LayoutViewportPresetData on LayoutViewportPreset {
  String get label => switch (this) {
    LayoutViewportPreset.off => 'Off',
    LayoutViewportPreset.mobilePortrait => 'Mobile · Portrait · 390 × 844',
    LayoutViewportPreset.mobileLandscape => 'Mobile · Landscape · 844 × 390',
    LayoutViewportPreset.tabletPortrait => 'Tablet · Portrait · 768 × 1024',
    LayoutViewportPreset.tabletLandscape => 'Tablet · Landscape · 1024 × 768',
    LayoutViewportPreset.desktopSmall => 'Desktop · Small · 1280 × 800',
    LayoutViewportPreset.desktopLarge => 'Desktop · Large · 1920 × 1080',
  };

  (LengthUnit, LengthUnit)? get dimensions => switch (this) {
    LayoutViewportPreset.off => null,
    LayoutViewportPreset.mobilePortrait => (
      const Rem(24.375),
      const Rem(52.75),
    ),
    LayoutViewportPreset.mobileLandscape => (
      const Rem(52.75),
      const Rem(24.375),
    ),
    LayoutViewportPreset.tabletPortrait => (const Rem(48), const Rem(64)),
    LayoutViewportPreset.tabletLandscape => (const Rem(64), const Rem(48)),
    LayoutViewportPreset.desktopSmall => (const Rem(80), const Rem(50)),
    LayoutViewportPreset.desktopLarge => (const Rem(120), const Rem(67.5)),
  };
}

Widget layoutViewportPreview(
  BuildContext context, {
  required Widget child,
  LengthUnit offHeight = const Rem(45),
}) {
  final preset = context.knobs.object.dropdown(
    label: 'Environment · Viewport',
    options: LayoutViewportPreset.values,
    initialOption: LayoutViewportPreset.off,
    labelBuilder: (value) => value.label,
  );
  return layoutViewportFrame(
    context,
    preset: preset,
    offHeight: offHeight,
    child: child,
  );
}

Widget layoutViewportFrame(
  BuildContext context, {
  required LayoutViewportPreset preset,
  required Widget child,
  LengthUnit offHeight = const Rem(45),
}) {
  final dimensions = preset.dimensions;
  if (dimensions == null) {
    return SizedBox(
      width: double.infinity,
      height: context.units(offHeight),
      child: child,
    );
  }
  final content = SizedBox(
    width: context.units(dimensions.$1),
    height: context.units(dimensions.$2),
    child: child,
  );
  return Align(
    alignment: Alignment.topLeft,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: content),
    ),
  );
}
