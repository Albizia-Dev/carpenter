import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

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
  BuilderAddon(
    name: 'Carpenter preview',
    builder: (context, child) => UnitsRoot(
      rem: const Px(16),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
  TextScaleAddon(min: 1, max: 2, divisions: 4),
  // Widgetbook 3.25 exposes its requested semantics debugger as experimental.
  // ignore: experimental_member_use
  SemanticsAddon(),
];
