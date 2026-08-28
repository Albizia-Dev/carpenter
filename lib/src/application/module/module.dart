import '../navigation/route.dart';
import '../shell/shell.dart';

/// Feature module contributing routes, shells and typed application capabilities.
abstract interface class CarpenterModule {
  String get id;
  Set<Type> get requires;
  Set<Type> get provides;
  List<CarpenterShell> get shells;
  List<CarpenterRoute> get routes;
}

abstract class CarpenterModuleBase implements CarpenterModule {
  const CarpenterModuleBase();

  @override
  Set<Type> get requires => const {};
  @override
  Set<Type> get provides => const {};
  @override
  List<CarpenterShell> get shells => const [];
  @override
  List<CarpenterRoute> get routes => const [];
}
