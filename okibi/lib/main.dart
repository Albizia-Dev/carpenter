import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation_flutter/yx_navigation_flutter.dart';

import 'navigation/app_navigation.dart';

void main() => runApp(const App());

/// The Okibi application host.
final class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

final class _AppState extends State<App> {
  late final YxRouterConfig _routerConfig;

  @override
  void initState() {
    super.initState();
    _routerConfig = AppNavigationSchema().build();
  }

  @override
  Widget build(BuildContext context) =>
      Application.router(title: 'Okibi', routerConfig: _routerConfig);

  @override
  void dispose() {
    unawaited(_routerConfig.dispose());
    super.dispose();
  }
}
