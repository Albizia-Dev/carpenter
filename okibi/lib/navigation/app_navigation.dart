import 'package:yx_navigation/yx_navigation.dart';
import 'package:yx_navigation_flutter/yx_navigation_flutter.dart';

import '../pages/test_pages.dart';

/// Route identities owned by the Okibi application.
abstract final class AppRoutes {
  static const root = YxRoute(id: 'first');
  static const first = YxRoute(id: 'first');
  static const second = YxRoute(id: 'second');

  /// Compatibility aliases used to exercise route redirects.
  static const legacyFirst = YxRoute(id: 'legacy-first');
  static const legacySecond = YxRoute(id: 'legacy-second');
}

/// The root YX Navigation schema for Okibi.
final class AppNavigationSchema extends RouterSchema {
  @override
  Iterable<RouteNodeGuard> get guards => const [_LegacyRouteRedirectGuard()];

  @override
  List<RouteDeclaration> get declarations => [
    RouteDeclaration.routeBuilder(
      route: AppRoutes.first,
      routeBuilder: RouteBuilder.widget(
        builder: (context, state) => const FirstTestPage(),
      ),
    ),
    RouteDeclaration.routeBuilder(
      route: AppRoutes.second,
      routeBuilder: RouteBuilder.widget(
        builder: (context, state) => const SecondTestPage(),
      ),
    ),
  ];

  @override
  RouteNode initialNodeBuilder(MutableRouteNode root) =>
      root..setChildren([AppRoutes.first.toNode()]);
}

final class _LegacyRouteRedirectGuard implements RouteNodeGuard {
  const _LegacyRouteRedirectGuard();

  @override
  GuardResult call(RouteNode origin, RouteNode target, GuardContext context) {
    final stack = target.children.toList();
    if (stack.isEmpty) {
      return const GuardResult.next();
    }

    final current = stack.last;
    final destination = switch (current.route) {
      AppRoutes.legacyFirst => AppRoutes.first,
      AppRoutes.legacySecond => AppRoutes.second,
      _ => null,
    };
    if (destination == null) {
      return const GuardResult.next();
    }

    final redirectedPage = current.copyWith(route: destination);
    return GuardResult.redirect(
      target: target.copyWith(children: [redirectedPage]),
    );
  }
}
