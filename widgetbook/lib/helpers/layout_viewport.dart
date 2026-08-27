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
    LayoutViewportPreset.mobilePortrait => (const Px(390), const Px(844)),
    LayoutViewportPreset.mobileLandscape => (const Px(844), const Px(390)),
    LayoutViewportPreset.tabletPortrait => (const Px(768), const Px(1024)),
    LayoutViewportPreset.tabletLandscape => (const Px(1024), const Px(768)),
    LayoutViewportPreset.desktopSmall => (const Px(1280), const Px(800)),
    LayoutViewportPreset.desktopLarge => (const Px(1920), const Px(1080)),
  };
}

Widget layoutViewportPreview(
  BuildContext context, {
  required Widget child,
  LengthUnit offHeight = const Px(720),
}) {
  final preset = context.knobs.object.dropdown(
    label: 'Environment · Viewport',
    options: LayoutViewportPreset.values,
    initialOption: LayoutViewportPreset.off,
    labelBuilder: (value) => value.label,
  );
  return layoutViewportFrame(
    preset: preset,
    offHeight: offHeight,
    child: child,
  );
}

Widget layoutViewportFrame({
  required LayoutViewportPreset preset,
  required Widget child,
  LengthUnit offHeight = const Px(720),
}) {
  final dimensions = preset.dimensions;
  if (dimensions == null) {
    return SizedBox(
      width: double.infinity,
      height: offHeight.value,
      child: child,
    );
  }
  final content = SizedBox(
    width: dimensions.$1.value,
    height: dimensions.$2.value,
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
