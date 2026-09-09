import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../helpers/layout_viewport.dart';
import 'text_direction_addon.dart';

final carpenterViewports = <ViewportData>[
  for (final preset in LayoutViewportPreset.values)
    if (preset.dimensions case final dimensions?)
      ViewportData(
        name: preset.label,
        width: dimensions.$1.value * 16,
        height: dimensions.$2.value * 16,
        pixelRatio: 1,
        platform: switch (preset) {
          LayoutViewportPreset.mobilePortrait ||
          LayoutViewportPreset.mobileLandscape => TargetPlatform.android,
          LayoutViewportPreset.tabletPortrait ||
          LayoutViewportPreset.tabletLandscape => TargetPlatform.iOS,
          _ => TargetPlatform.windows,
        },
      ),
];

final List<WidgetbookTheme<CarpenterThemeData>> carpenterThemes = [
  WidgetbookTheme(name: 'Light', data: CarpenterThemeData.light()),
  WidgetbookTheme(
    name: 'Light · compact',
    data: CarpenterThemeData.light(density: CarpenterDensity.compact),
  ),
  WidgetbookTheme(name: 'Dark', data: CarpenterThemeData.dark()),
  WidgetbookTheme(
    name: 'Dark · compact',
    data: CarpenterThemeData.dark(density: CarpenterDensity.compact),
  ),
  WidgetbookTheme(
    name: 'High contrast',
    data: CarpenterThemeData.light(contrast: ContrastMode.high),
  ),
  WidgetbookTheme(
    name: 'High contrast · compact',
    data: CarpenterThemeData.light(
      contrast: ContrastMode.high,
      density: CarpenterDensity.compact,
    ),
  ),
  WidgetbookTheme(
    name: 'High contrast dark',
    data: CarpenterThemeData.dark(contrast: ContrastMode.high),
  ),
  WidgetbookTheme(
    name: 'High contrast dark · compact',
    data: CarpenterThemeData.dark(
      contrast: ContrastMode.high,
      density: CarpenterDensity.compact,
    ),
  ),
];

final List<WidgetbookAddon> carpenterAddons = [
  ViewportAddon(carpenterViewports),
  ThemeAddon<CarpenterThemeData>(
    themes: carpenterThemes,
    themeBuilder: (context, theme, child) => CarpenterTheme(
      data: theme,
      child: ColoredBox(
        color: theme.surface.base,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: theme.content.primary),
          child: child,
        ),
      ),
    ),
  ),
  ZoomAddon(),
  // Widgetbook 3.25 exposes animation timing as experimental.
  // ignore: experimental_member_use
  TimeDilationAddon(),
  BuilderAddon(
    name: 'Carpenter preview',
    builder: (context, child) => UnitsRoot(rem: const Px(16), child: child),
  ),
  TextDirectionAddon(),
  TextScaleAddon(min: 1, max: 2, divisions: 4),
  // Widgetbook 3.25 exposes its requested semantics debugger as experimental.
  // ignore: experimental_member_use
  SemanticsAddon(),
];
