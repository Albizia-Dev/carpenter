import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';
import 'route.dart';

/// Runtime capability exposing the active yx_navigation controller together with
/// the latest route-tree root snapshot.
final class CarpenterRouterRuntime {
  /// Creates router runtime state from a navigation controller and its current
  /// route-tree root.
  const CarpenterRouterRuntime({required this.navigation, required this.root});

  /// Controller used for application navigation mutations.
  final NavigationController navigation;

  /// Latest route-tree root snapshot exposed to Carpenter route rendering.
  final RouteNode? root;

  /// Pushes `route` through the underlying navigation controller with optional
  /// string arguments and typed extra payload.
  void push(
    YxRoute route, {
    Map<String, String>? arguments,
    Map<String, Object?>? extra,
  }) => navigation.push(route, arguments: arguments, extra: extra);

  /// Requests a pop from the underlying navigation controller when its current
  /// state permits one.
  void maybePop() => navigation.maybePop();
}

/// Typed access to router capability registered in a [CarpenterRuntime].
extension CarpenterRouterRuntimeAccess on CarpenterRuntime {
  /// Mandatory router runtime capability; throws when no router shell registered it.
  CarpenterRouterRuntime get router => read<CarpenterRouterRuntime>();
}

/// Renders the active route-tree chain against Carpenter route declarations,
/// applying terminal page, then route shells/scopes from leaf back toward root.
final class CarpenterRouteRenderer extends StatelessWidget {
  /// Creates a renderer for an internal Carpenter route declaration tree with an
  /// optional missing-route fallback.
  const CarpenterRouteRenderer({
    super.key,
    required this.routes,
    this.missingRouteBuilder,
  });

  /// Root Carpenter route declarations used to match the active runtime route
  /// tree.
  final List<CarpenterRoute> routes;

  /// Optional fallback for absent or undeclared route nodes; a diagnostic text
  /// fallback is used when omitted.
  final Widget Function(BuildContext context, RouteNode? node)?
  missingRouteBuilder;

  /// Reads router runtime, matches the active child chain, builds the terminal
  /// page, and applies each matched route shell and scope in reverse order.
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
