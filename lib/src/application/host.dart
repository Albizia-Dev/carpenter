import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'module/module.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

/// Optionally transforms hosted content after the runtime is compiled and before shells
/// wrap the result.
typedef CarpenterHostBuilder =
    Widget Function(BuildContext context, Widget child);

/// Hosts Carpenter application capabilities independently from app/routing setup.
final class CarpenterHost extends StatelessWidget {
  /// Creates a capability host for `child`; direct shells/modules default to empty and
  /// platform/locale default to the active environment.
  const CarpenterHost({
    super.key,
    required this.child,
    this.builder,
    this.shells = const [],
    this.modules = const [],
    this.platform,
    this.locale,
  });

  /// Content hosted or wrapped by this Carpenter application primitive.
  final Widget child;
  /// Optional host-content transformer invoked after runtime compilation and before
  /// shell wrapping.
  final CarpenterHostBuilder? builder;
  /// Application shells contributed directly or by a module.
  final List<CarpenterShell> shells;
  /// Feature modules whose shells, routes, and capability requirements participate in
  /// this application host.
  final List<CarpenterModule> modules;
  /// Target platform used for platform-sensitive Carpenter behavior.
  final TargetPlatform? platform;
  /// Optional locale propagated as part of the core Carpenter runtime or application
  /// root.
  final Locale? locale;

  /// Compiles core runtime plus effective shells, validates module requirements,
  /// exposes the runtime, then wraps content through shells in reverse order.
  @override
  Widget build(BuildContext context) {
    final targetPlatform = platform ?? defaultTargetPlatform;
    final effectiveShells = <CarpenterShell>[
      ...shells,
      for (final module in modules) ...module.shells,
    ];
    final base = CarpenterRuntime().extend(
      CarpenterCoreRuntime(platform: targetPlatform, locale: locale),
    );
    final runtime = _compile(base, effectiveShells);
    _validateModules(runtime);
    return CarpenterRuntimeScope(
      runtime: runtime,
      child: Builder(
        builder: (context) {
          var content = builder?.call(context, child) ?? child;
          for (final shell in effectiveShells.reversed) {
            content = shell.wrap(
              CarpenterShellBuildContext(
                runtime: runtime,
                buildContext: context,
              ),
              content,
            );
          }
          return content;
        },
      ),
    );
  }

  CarpenterRuntime _compile(
    CarpenterRuntime base,
    List<CarpenterShell> shells,
  ) {
    var runtime = base;
    for (final shell in shells) {
      final missing = shell.requires
          .where((type) => !runtime.contains(type))
          .toList();
      if (missing.isNotEmpty)
        throw StateError(
          'Carpenter shell "${shell.id}" requires missing capabilities: ${missing.join(', ')}.',
        );
      runtime = shell.configure(
        CarpenterShellConfigureContext(runtime: runtime),
      );
      final absent = shell.provides
          .where((type) => !runtime.contains(type))
          .toList();
      if (absent.isNotEmpty)
        throw StateError(
          'Carpenter shell "${shell.id}" declared but did not provide: ${absent.join(', ')}.',
        );
    }
    return runtime;
  }

  void _validateModules(CarpenterRuntime runtime) {
    for (final module in modules) {
      final missing = module.requires
          .where((type) => !runtime.contains(type))
          .toList();
      if (missing.isNotEmpty)
        throw StateError(
          'Carpenter module "${module.id}" requires missing capabilities: ${missing.join(', ')}.',
        );
    }
  }
}
