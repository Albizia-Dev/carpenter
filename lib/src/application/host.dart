import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'module/module.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

typedef CarpenterHostBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// Hosts Carpenter application capabilities independently from app/routing setup.
final class CarpenterHost extends StatelessWidget {
  const CarpenterHost({
    super.key,
    required this.child,
    this.builder,
    this.shells = const [],
    this.modules = const [],
    this.platform,
    this.locale,
  });

  final Widget child;
  final CarpenterHostBuilder? builder;
  final List<CarpenterShell> shells;
  final List<CarpenterModule> modules;
  final TargetPlatform? platform;
  final Locale? locale;

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
