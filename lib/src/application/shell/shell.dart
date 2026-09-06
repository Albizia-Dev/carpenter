import 'package:flutter/widgets.dart';

import '../runtime/runtime.dart';

/// Immutable context supplied while a host compiles shell-provided runtime
/// capabilities.
final class CarpenterShellConfigureContext {
  /// Creates configuration context from the runtime produced by earlier shells.
  const CarpenterShellConfigureContext({required this.runtime});

  /// Runtime compiled by shells that precede the current shell.
  final CarpenterRuntime runtime;
}

/// Immutable context supplied when an already configured shell wraps hosted
/// content.
final class CarpenterShellBuildContext {
  /// Creates build context from the final compiled runtime and current Flutter
  /// build context.
  const CarpenterShellBuildContext({
    required this.runtime,
    required this.buildContext,
  });

  /// Final compiled runtime available while the shell wraps content.
  final CarpenterRuntime runtime;

  /// Flutter build context at the host boundary where shell wrapping occurs.
  final BuildContext buildContext;
}

/// Middleware-like application shell with typed capability dependencies.
abstract interface class CarpenterShell {
  /// Stable shell identifier used in dependency/provision validation diagnostics.
  String get id;

  /// Capability types that must already exist before this shell is configured.
  Set<Type> get requires;

  /// Capability types this shell promises to register during [configure].
  /// The host validates the promise after configuration.
  Set<Type> get provides;

  /// Returns the runtime passed to subsequent shells, usually by extending
  /// [CarpenterShellConfigureContext.runtime] with declared capabilities.
  CarpenterRuntime configure(CarpenterShellConfigureContext context);

  /// Wraps already composed hosted content after runtime configuration is complete.
  Widget wrap(CarpenterShellBuildContext context, Widget child);
}

/// Convenience base for pass-through shells with no requirements or provided
/// capabilities by default.
abstract class CarpenterShellBase implements CarpenterShell {
  /// Creates a pass-through shell base.
  const CarpenterShellBase();

  /// Default empty capability requirement set.
  @override
  Set<Type> get requires => const {};

  /// Default empty capability provision set.
  @override
  Set<Type> get provides => const {};

  /// Default configuration returns the incoming runtime unchanged.
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) =>
      context.runtime;

  /// Default wrapping returns the child unchanged.
  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) => child;
}
