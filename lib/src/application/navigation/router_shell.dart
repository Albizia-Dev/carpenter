import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

import '../runtime/runtime.dart';
import '../shell/shell.dart';
import 'router.dart';

/// Connects yx_navigation state to the Carpenter typed runtime.
final class CarpenterRouterShell extends CarpenterShellBase {
  /// Creates a router shell bound to a caller-owned yx_navigation controller.
  const CarpenterRouterShell({required this.navigation});

  /// Caller-owned navigation controller whose state is published into Carpenter
  /// runtime.
  final NavigationController navigation;

  /// Stable shell identifier used for diagnostics and capability-composition
  /// errors.
  @override
  String get id => 'carpenter.router';

  /// Declares that successful configuration registers [CarpenterRouterRuntime].
  @override
  Set<Type> get provides => const {CarpenterRouterRuntime};

  /// Extends runtime with the controller and its current route-tree snapshot before
  /// the shell is wrapped.
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) =>
      context.runtime.extend(
        CarpenterRouterRuntime(navigation: navigation, root: navigation.state),
      );

  /// Subscribes to navigation updates and republishes [CarpenterRouterRuntime]
  /// through a nested runtime scope while preserving hosted content.
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
