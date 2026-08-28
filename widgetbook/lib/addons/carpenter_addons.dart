import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

const _carpenterViewports = <ViewportData>[
  ViewportData(
    name: 'Phone 360 × 800',
    width: 360,
    height: 800,
    pixelRatio: 1,
    platform: TargetPlatform.android,
  ),
  ViewportData(
    name: 'Phone 430 × 932',
    width: 430,
    height: 932,
    pixelRatio: 1,
    platform: TargetPlatform.iOS,
  ),
  ViewportData(
    name: 'Tablet 834 × 1194',
    width: 834,
    height: 1194,
    pixelRatio: 1,
    platform: TargetPlatform.iOS,
  ),
  ViewportData(
    name: 'Desktop 1280 × 800',
    width: 1280,
    height: 800,
    pixelRatio: 1,
    platform: TargetPlatform.windows,
  ),
  ViewportData(
    name: 'Desktop 1440 × 900',
    width: 1440,
    height: 900,
    pixelRatio: 1,
    platform: TargetPlatform.macOS,
  ),
];

final List<WidgetbookAddon> carpenterAddons = [
  ThemeAddon<CarpenterThemeData>(
    themes: [
      WidgetbookTheme(name: 'Light', data: CarpenterThemeData.light()),
      WidgetbookTheme(name: 'Dark', data: CarpenterThemeData.dark()),
      WidgetbookTheme(
        name: 'High contrast',
        data: CarpenterThemeData.light(contrast: ContrastMode.high),
      ),
    ],
    themeBuilder: (context, theme, child) => CarpenterTheme(
      data: theme,
      child: ColoredBox(color: theme.surface.base, child: child),
    ),
  ),
  ViewportAddon(_carpenterViewports),
  ZoomAddon(),
  // Widgetbook 3.25 exposes animation timing as experimental.
  // ignore: experimental_member_use
  TimeDilationAddon(),
  BuilderAddon(
    name: 'Carpenter preview',
    builder: (context, child) => UnitsRoot(
      rem: const Px(16),
      child: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.all(context.units(1.5.rem)),
          child: child,
        ),
      ),
    ),
  ),
  TextScaleAddon(min: 1, max: 2, divisions: 4),
  // Widgetbook 3.25 exposes its requested semantics debugger as experimental.
  // ignore: experimental_member_use
  SemanticsAddon(),
];
