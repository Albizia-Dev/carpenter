import 'package:flutter/widgets.dart';

import '../foundation/application.dart';
import '../foundation/theme.dart';
import 'host.dart';
import 'module/module.dart';
import 'navigation/route.dart';
import 'navigation/router.dart';
import 'shell/shell.dart';

/// High-level Carpenter application host using the current theme/runtime stack.
final class CarpenterApp extends StatelessWidget {
  const CarpenterApp({
    super.key,
    this.child,
    this.theme,
    this.routerConfig,
    this.shells = const [],
    this.modules = const [],
    this.routes = const [],
    this.missingRouteBuilder,
    this.platform,
    this.locale,
    this.title,
    this.debugShowCheckedModeBanner = false,
  });

  final Widget? child;
  final CarpenterThemeData? theme;
  final RouterConfig<Object>? routerConfig;
  final List<CarpenterShell> shells;
  final List<CarpenterModule> modules;
  final List<CarpenterRoute> routes;
  final Widget Function(BuildContext context, Object? node)? missingRouteBuilder;
  final TargetPlatform? platform;
  final Locale? locale;
  final String? title;
  final bool debugShowCheckedModeBanner;

  List<CarpenterRoute> get _routes => [...routes, for (final module in modules) ...module.routes];

  Widget _host(BuildContext context, Widget? routedChild) => CarpenterHost(
    shells: shells,
    modules: modules,
    platform: platform,
    locale: locale,
    child: child ?? routedChild ?? CarpenterRouteRenderer(
      routes: _routes,
      missingRouteBuilder: (context, node) => missingRouteBuilder?.call(context, node) ?? const SizedBox.shrink(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final router = routerConfig;
    if (router != null) {
      return Application.router(
        theme: theme,
        routerConfig: router,
        title: title,
        locale: locale,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        builder: _host,
      );
    }
    return Application(
      theme: theme,
      home: child ?? (_routes.isEmpty ? const SizedBox.shrink() : CarpenterRouteRenderer(routes: _routes)),
      title: title,
      locale: locale,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      builder: _host,
    );
  }
}
