import 'package:flutter/material.dart' show Text, ThemeData, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import 'addons/carpenter_addons.dart';
import 'catalog.dart';

Widget createCarpenterWidgetbook() => Widgetbook.material(
  directories: carpenterCatalog,
  addons: carpenterAddons,
  header: const Text('Carpenter'),
  lightTheme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
);
