import 'package:carpenter/src/legacy/src/module/module.dart';
import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:carpenter/src/legacy/src/root/scope.dart';
import 'package:carpenter/src/legacy/src/root/system.dart';
import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builder содержимого, уже помещенного в Carpenter scope/runtime.
typedef CarpenterHostBuilder =
    Widget Function(BuildContext context, Widget child);

/// Независимый от app/router host визуального runtime и shell pipeline.
///
/// Его можно размещать внутри `WidgetsApp`, `WidgetsApp.router`, legacy app
/// host или тестового окружения. В отличие от [CarpenterApp], host не создает
/// приложение и не владеет навигацией.
class CarpenterHost extends StatelessWidget {
  const CarpenterHost({
    super.key,
    required this.child,
    this.config = const CarpenterConfig(),
    this.carpenter,
    this.builder,
    this.shells = const [],
    this.modules = const [],
    this.platform,
    this.locale,
  });

  final Widget child;
  final CarpenterConfig config;
  final Carpenter? carpenter;
  final CarpenterHostBuilder? builder;
  final List<CarpenterShell> shells;
  final List<CarpenterModule> modules;
  final TargetPlatform? platform;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final visualRuntime = carpenter ?? Carpenter.fromConfig(config);
    final targetPlatform =
        platform ?? visualRuntime.config.platform ?? defaultTargetPlatform;
    final appLocale = locale ?? visualRuntime.config.locale;
    final effectiveShells = <CarpenterShell>[
      ...shells,
      for (final module in modules) ...module.shells,
    ];
    final baseRuntime = CarpenterRuntime().extend(
      CarpenterCoreRuntime(
        carpenter: visualRuntime,
        platform: targetPlatform,
        locale: appLocale,
      ),
    );
    final compiledRuntime = _compileRuntime(baseRuntime, effectiveShells);
    _validateModules(compiledRuntime);

    return CarpenterScope(
      carpenter: visualRuntime,
      child: CarpenterRuntimeScope(
        runtime: compiledRuntime,
        child: Builder(
          builder: (context) {
            var content = child;
            if (builder != null) {
              content = builder!(context, content);
            }

            for (final shell in effectiveShells.reversed) {
              content = shell.wrap(
                CarpenterShellBuildContext(
                  runtime: compiledRuntime,
                  buildContext: context,
                ),
                content,
              );
            }

            return DefaultTextStyle(
              style: visualRuntime.face
                  .type('body')
                  .copyWith(color: visualRuntime.face.color('text.primary')),
              child: content,
            );
          },
        ),
      ),
    );
  }

  CarpenterRuntime _compileRuntime(
    CarpenterRuntime baseRuntime,
    List<CarpenterShell> effectiveShells,
  ) {
    var runtime = baseRuntime;

    for (final shell in effectiveShells) {
      final missing = shell.requires
          .where((type) => !runtime.contains(type))
          .map((type) => type.toString())
          .toList();
      if (missing.isNotEmpty) {
        throw StateError(
          'Carpenter shell "${shell.id}" requires missing capabilities: '
          '${missing.join(', ')}.',
        );
      }

      runtime = shell.configure(
        CarpenterShellConfigureContext(runtime: runtime),
      );

      final notProvided = shell.provides
          .where((type) => !runtime.contains(type))
          .map((type) => type.toString())
          .toList();
      if (notProvided.isNotEmpty) {
        throw StateError(
          'Carpenter shell "${shell.id}" declared provides but did not add: '
          '${notProvided.join(', ')}.',
        );
      }
    }

    return runtime;
  }

  void _validateModules(CarpenterRuntime runtime) {
    for (final module in modules) {
      final missing = module.requires
          .where((type) => !runtime.contains(type))
          .map((type) => type.toString())
          .toList();
      if (missing.isNotEmpty) {
        throw StateError(
          'Carpenter module "${module.id}" requires missing capabilities: '
          '${missing.join(', ')}.',
        );
      }
    }
  }
}
