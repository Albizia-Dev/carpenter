import '../navigation/route.dart';
import '../shell/shell.dart';

/// Feature module contributing routes, shells and typed application capabilities.
abstract interface class CarpenterModule {
  /// Stable module identifier used in validation and diagnostic messages.
  String get id;

  /// Runtime capability types that must exist after all effective shells are
  /// configured.
  Set<Type> get requires;

  /// Capability types conceptually contributed by this module and its integration.
  /// Concrete values are still read from the compiled runtime.
  Set<Type> get provides;

  /// Shells contributed by this module to host capability configuration and
  /// wrapping.
  List<CarpenterShell> get shells;

  /// Internal Carpenter route declarations contributed by this module.
  List<CarpenterRoute> get routes;
}

/// Convenience base for modules with no capability requirements, provided
/// capability metadata, shells, or routes by default.
abstract class CarpenterModuleBase implements CarpenterModule {
  /// Creates a module base with empty default contributions.
  const CarpenterModuleBase();

  /// Default empty runtime requirement set. Override when module behavior depends
  /// on typed capabilities.
  @override
  Set<Type> get requires => const {};

  /// Default empty provided-capability set. Override when the module exposes
  /// application runtime capabilities.
  @override
  Set<Type> get provides => const {};

  /// Default empty shell contribution list.
  @override
  List<CarpenterShell> get shells => const [];

  /// Default empty internal route contribution list.
  @override
  List<CarpenterRoute> get routes => const [];
}
