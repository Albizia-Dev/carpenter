import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';

typedef CarpenterRouteScopeBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);
typedef CarpenterRouteShellBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);
typedef CarpenterRoutePageBuilder =
    Widget Function(CarpenterRouteContext context);

/// Carpenter declaration layered over yx_navigation route identity.
final class CarpenterRoute {
  const CarpenterRoute({
    required this.route,
    this.scope,
    this.shell,
    this.page,
    this.children = const [],
  });
  final YxRoute route;
  final CarpenterRouteScopeBuilder? scope;
  final CarpenterRouteShellBuilder? shell;
  final CarpenterRoutePageBuilder? page;
  final List<CarpenterRoute> children;
}

final class CarpenterRouteMatch {
  const CarpenterRouteMatch({
    required this.node,
    required this.route,
    required this.depth,
  });
  final RouteNode node;
  final CarpenterRoute route;
  final int depth;
}

final class CarpenterRouteContext {
  const CarpenterRouteContext({
    required this.runtime,
    required this.match,
    required this.chain,
  });
  final CarpenterRuntime runtime;
  final CarpenterRouteMatch match;
  final List<CarpenterRouteMatch> chain;
  CarpenterRoute get route => match.route;
  RouteNode get node => match.node;
  Map<String, String> get arguments => node.arguments;
  Map<String, Object?> get extra => node.extra;
}
