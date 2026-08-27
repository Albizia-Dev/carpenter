import 'package:carpenter/src/legacy/src/navigation/router.dart';
import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

/// Shell, который подключает yx_navigation к runtime Carpenter.
///
/// `yx_navigation` остается источником navigation state, а Carpenter только
/// слушает `RouteNode` и рендерит соответствующее дерево widgets.
class CarpenterRouterShell extends CarpenterShellBase {
  /// Создает router shell.
  const CarpenterRouterShell({required this.navigation});

  /// Navigation controller/state manager из yx_navigation.
  final NavigationController navigation;

  @override
  String get id => 'carpenter.router';

  @override
  Set<Type> get provides => const {CarpenterRouterRuntime};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime.extend(
      CarpenterRouterRuntime(navigation: navigation, root: navigation.state),
    );
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) {
    return StreamBuilder<RouteNode?>(
      stream: navigation.stream,
      initialData: navigation.state,
      builder: (buildContext, snapshot) {
        final runtime = context.runtime.extend(
          CarpenterRouterRuntime(
            navigation: navigation,
            root: snapshot.data ?? navigation.state,
          ),
        );

        return CarpenterRuntimeScope(runtime: runtime, child: child);
      },
    );
  }
}
