import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';
import 'route.dart';

final class CarpenterRouterRuntime {
  const CarpenterRouterRuntime({required this.navigation, required this.root});
  final NavigationController navigation;
  final RouteNode? root;

  void push(
    YxRoute route, {
    Map<String, String>? arguments,
    Map<String, Object?>? extra,
  }) => navigation.push(route, arguments: arguments, extra: extra);
  void maybePop() => navigation.maybePop();
}

extension CarpenterRouterRuntimeAccess on CarpenterRuntime {
  CarpenterRouterRuntime get router => read<CarpenterRouterRuntime>();
}

final class CarpenterRouteRenderer extends StatelessWidget {
  const CarpenterRouteRenderer({
    super.key,
    required this.routes,
    this.missingRouteBuilder,
  });
  final List<CarpenterRoute> routes;
  final Widget Function(BuildContext context, RouteNode? node)?
  missingRouteBuilder;

  @override
  Widget build(BuildContext context) {
    final runtime = context.runtime;
    final root = runtime.maybeRead<CarpenterRouterRuntime>()?.root;
    if (root == null) return _missing(context, null);
    final chain = _matchActiveChain(root, routes);
    if (chain.isEmpty) return _missing(context, root);
    final terminal = chain.last;
    Widget child =
        terminal.route.page?.call(
          CarpenterRouteContext(
            runtime: runtime,
            match: terminal,
            chain: chain,
          ),
        ) ??
        _missing(context, terminal.node);
    for (final match in chain.reversed) {
      final routeContext = CarpenterRouteContext(
        runtime: runtime,
        match: match,
        chain: chain,
      );
      final shell = match.route.shell;
      if (shell != null) child = shell(routeContext, child);
      final scope = match.route.scope;
      if (scope != null) child = scope(routeContext, child);
    }
    return child;
  }

  Widget _missing(BuildContext context, RouteNode? node) =>
      missingRouteBuilder?.call(context, node) ??
      Center(
        child: Text(
          node == null
              ? 'Carpenter route tree is empty'
              : 'Carpenter route is not declared: ${node.route.id}',
        ),
      );
}

List<CarpenterRouteMatch> _matchActiveChain(
  RouteNode root,
  List<CarpenterRoute> routes,
) {
  final matches = <CarpenterRouteMatch>[];
  var node = root;
  var declarations = routes;
  var depth = 0;
  while (true) {
    CarpenterRoute? declaration;
    for (final candidate in declarations) {
      if (candidate.route == node.route) {
        declaration = candidate;
        break;
      }
    }
    if (declaration == null) return matches;
    matches.add(
      CarpenterRouteMatch(node: node, route: declaration, depth: depth),
    );
    if (node.children.isEmpty) return matches;
    node = node.children.last;
    declarations = declaration.children;
    depth += 1;
  }
}
