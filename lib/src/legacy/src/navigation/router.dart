import 'package:carpenter/src/legacy/src/navigation/route.dart';
import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

/// Runtime capability router-а Carpenter.
class CarpenterRouterRuntime {
  /// Создает router runtime.
  const CarpenterRouterRuntime({required this.navigation, required this.root});

  /// Navigation controller из yx_navigation. Его можно использовать без
  /// `BuildContext` из commands/interactors/services.
  final NavigationController navigation;

  /// Текущий root route node.
  final RouteNode? root;

  /// Пушит route через yx_navigation.
  void push(
    YxRoute route, {
    Map<String, String>? arguments,
    Map<String, Object?>? extra,
  }) {
    navigation.push(route, arguments: arguments, extra: extra);
  }

  /// Возврат назад, если возможно.
  void maybePop() => navigation.maybePop();
}

/// Typed access к router capability.
extension CarpenterRouterRuntimeAccess on CarpenterRuntime {
  /// Router runtime.
  CarpenterRouterRuntime get router => read<CarpenterRouterRuntime>();
}

/// Renderer, который превращает active route tree в Scope/Shell/Page widgets.
class CarpenterRouteRenderer extends StatelessWidget {
  /// Создает route renderer.
  const CarpenterRouteRenderer({
    super.key,
    required this.routes,
    this.missingRouteBuilder,
  });

  /// Root route declarations.
  final List<CarpenterRoute> routes;

  /// UI для ситуации, когда yx node не описан в Carpenter routes.
  final Widget Function(BuildContext context, RouteNode? node)?
  missingRouteBuilder;

  @override
  Widget build(BuildContext context) {
    final runtime = context.runtime;
    final root = runtime.router.root;
    if (root == null) {
      return _missing(context, null);
    }

    final chain = _matchActiveChain(root, routes);
    if (chain.isEmpty) {
      return _missing(context, root);
    }

    final terminal = chain.last;
    Widget child;
    final page = terminal.route.page;
    if (page == null) {
      child = _missing(context, terminal.node);
    } else {
      child = page(
        CarpenterRouteContext(runtime: runtime, match: terminal, chain: chain),
      );
    }

    for (final match in chain.reversed) {
      final routeContext = CarpenterRouteContext(
        runtime: runtime,
        match: match,
        chain: chain,
      );

      final shell = match.route.shell;
      if (shell != null) {
        child = shell(routeContext, child);
      }

      final scope = match.route.scope;
      if (scope != null) {
        child = scope(routeContext, child);
      }
    }

    return child;
  }

  Widget _missing(BuildContext context, RouteNode? node) {
    final builder = missingRouteBuilder;
    if (builder != null) {
      return builder(context, node);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Text(
          node == null
              ? 'Carpenter route tree is empty'
              : 'Carpenter route is not declared: ${node.route.id}',
        ),
      ),
    );
  }
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
    final declaration = _findDeclaration(declarations, node.route);
    if (declaration == null) {
      return matches;
    }

    matches.add(
      CarpenterRouteMatch(node: node, route: declaration, depth: depth),
    );

    if (node.children.isEmpty) {
      return matches;
    }

    node = node.children.last;
    declarations = declaration.children;
    depth += 1;
  }
}

CarpenterRoute? _findDeclaration(List<CarpenterRoute> routes, YxRoute route) {
  for (final declaration in routes) {
    if (declaration.route == route) {
      return declaration;
    }
  }
  return null;
}
