import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';

/// Wraps a matched route subtree with route-local state or dependency scope while
/// preserving the already rendered child.
typedef CarpenterRouteScopeBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);

/// Wraps a matched route subtree with route-local visual or navigation shell
/// chrome.
typedef CarpenterRouteShellBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);

/// Builds terminal route content from the matched route node and compiled
/// Carpenter runtime.
typedef CarpenterRoutePageBuilder =
    Widget Function(CarpenterRouteContext context);

/// Carpenter declaration layered over yx_navigation route identity.
final class CarpenterRoute {
  /// Declares one Carpenter route identity plus optional scope, shell, terminal
  /// page, and nested child declarations.
  const CarpenterRoute({
    required this.route,
    this.scope,
    this.shell,
    this.page,
    this.children = const [],
  });

  /// yx_navigation route identity matched against route-tree nodes.
  final YxRoute route;

  /// Optional route-local scope wrapper applied while rendering the active
  /// matched chain.
  final CarpenterRouteScopeBuilder? scope;

  /// Optional route-local shell wrapper applied inside [scope] for the same
  /// matched declaration.
  final CarpenterRouteShellBuilder? shell;

  /// Optional page builder used when this declaration is the terminal active
  /// match.
  final CarpenterRoutePageBuilder? page;

  /// Nested route declarations eligible to match children of this route-tree
  /// node.
  final List<CarpenterRoute> children;
}

/// One declaration/node pair in the currently matched active route chain.
final class CarpenterRouteMatch {
  /// Creates a matched route entry at its zero-based depth in the active
  /// declaration chain.
  const CarpenterRouteMatch({
    required this.node,
    required this.route,
    required this.depth,
  });

  /// Concrete yx_navigation route-tree node that matched the declaration.
  final RouteNode node;

  /// Carpenter declaration matched to [node].
  final CarpenterRoute route;

  /// Zero-based depth of this match within the active chain.
  final int depth;
}

/// Immutable rendering context passed to Carpenter route page, shell, and scope
/// builders.
final class CarpenterRouteContext {
  /// Creates route rendering context for one [match] and its complete active
  /// [chain].
  const CarpenterRouteContext({
    required this.runtime,
    required this.match,
    required this.chain,
  });

  /// Compiled application runtime available while rendering the route.
  final CarpenterRuntime runtime;

  /// Current declaration/node match being rendered.
  final CarpenterRouteMatch match;

  /// Full active matched chain from root declaration through the terminal node.
  final List<CarpenterRouteMatch> chain;

  /// Convenience access to the current Carpenter route declaration.
  CarpenterRoute get route => match.route;

  /// Convenience access to the current yx_navigation node.
  RouteNode get node => match.node;

  /// String route arguments carried by the current navigation node.
  Map<String, String> get arguments => node.arguments;

  /// Typed extra payload carried by the current navigation node.
  Map<String, Object?> get extra => node.extra;
}
