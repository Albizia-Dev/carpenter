import 'package:flutter/widgets.dart';

import '../runtime/runtime.dart';

final class CarpenterShellConfigureContext {
  const CarpenterShellConfigureContext({required this.runtime});
  final CarpenterRuntime runtime;
}

final class CarpenterShellBuildContext {
  const CarpenterShellBuildContext({required this.runtime, required this.buildContext});
  final CarpenterRuntime runtime;
  final BuildContext buildContext;
}

/// Middleware-like application shell with typed capability dependencies.
abstract interface class CarpenterShell {
  String get id;
  Set<Type> get requires;
  Set<Type> get provides;
  CarpenterRuntime configure(CarpenterShellConfigureContext context);
  Widget wrap(CarpenterShellBuildContext context, Widget child);
}

abstract class CarpenterShellBase implements CarpenterShell {
  const CarpenterShellBase();

  @override
  Set<Type> get requires => const {};
  @override
  Set<Type> get provides => const {};
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) => context.runtime;
  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) => child;
}
