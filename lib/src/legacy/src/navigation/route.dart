import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

/// Scope builder route-уровня.
typedef CarpenterRouteScopeBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);

/// Shell builder route-уровня.
typedef CarpenterRouteShellBuilder =
    Widget Function(CarpenterRouteContext context, Widget child);

/// Page builder terminal route.
typedef CarpenterRoutePageBuilder =
    Widget Function(CarpenterRouteContext context);

/// Декларация маршрута Carpenter.
///
/// [YxRoute] остается stable identity из `yx_navigation`, а Carpenter добавляет
/// runtime-слои: scope, shell и page.
class CarpenterRoute {
  /// Создает route declaration.
  const CarpenterRoute({
    required this.route,
    this.scope,
    this.shell,
    this.page,
    this.children = const [],
  });

  /// Stable route id из yx_navigation.
  final YxRoute route;

  /// Route-level DI/state/context wrapper.
  final CarpenterRouteScopeBuilder? scope;

  /// Route-level layout/chrome wrapper.
  final CarpenterRouteShellBuilder? shell;

  /// Terminal screen.
  final CarpenterRoutePageBuilder? page;

  /// Вложенные route declarations.
  final List<CarpenterRoute> children;
}

/// Match одного yx node с Carpenter route declaration.
class CarpenterRouteMatch {
  /// Создает route match.
  const CarpenterRouteMatch({
    required this.node,
    required this.route,
    required this.depth,
  });

  /// Текущий node из yx_navigation.
  final RouteNode node;

  /// Declaration Carpenter для node.
  final CarpenterRoute route;

  /// Глубина в active chain.
  final int depth;
}

/// Контекст route builder-ов Carpenter.
class CarpenterRouteContext {
  /// Создает route context.
  const CarpenterRouteContext({
    required this.runtime,
    required this.match,
    required this.chain,
  });

  /// Typed runtime registry текущего приложения.
  final CarpenterRuntime runtime;

  /// Текущий match.
  final CarpenterRouteMatch match;

  /// Вся active chain от root до terminal page.
  final List<CarpenterRouteMatch> chain;

  /// Route declaration.
  CarpenterRoute get route => match.route;

  /// Route node из yx_navigation.
  RouteNode get node => match.node;

  /// Serializable arguments route node.
  Map<String, String> get arguments => node.arguments;

  /// Runtime-only payload route node.
  Map<String, Object?> get extra => node.extra;
}
