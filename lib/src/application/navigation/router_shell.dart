import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';
import '../shell/shell.dart';
import 'router.dart';

/// Connects yx_navigation state to the Carpenter typed runtime.
final class CarpenterRouterShell extends CarpenterShellBase {
  const CarpenterRouterShell({required this.navigation});
  final NavigationController navigation;

  @override
  String get id => 'carpenter.router';
  @override
  Set<Type> get provides => const {CarpenterRouterRuntime};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) =>
      context.runtime.extend(
        CarpenterRouterRuntime(navigation: navigation, root: navigation.state),
      );

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) =>
      StreamBuilder<RouteNode?>(
        stream: navigation.stream,
        initialData: navigation.state,
        builder: (buildContext, snapshot) => CarpenterRuntimeScope(
          runtime: context.runtime.extend(
            CarpenterRouterRuntime(
              navigation: navigation,
              root: snapshot.data ?? navigation.state,
            ),
          ),
          child: child,
        ),
      );
}
