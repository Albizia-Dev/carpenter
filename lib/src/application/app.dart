import 'package:flutter/widgets.dart';

import '../components/layout/app_frame.dart';
import '../foundation/application.dart';
import '../foundation/theme.dart';
import 'command.dart';
import 'frame_shell.dart';
import 'host.dart';
import 'hotkey.dart';
import 'hotkey_shell.dart';
import 'module/module.dart';
import 'navigation/route.dart';
import 'navigation/router.dart';
import 'shell/shell.dart';

/// High-level Carpenter application host using the current theme/runtime stack.
final class CarpenterApp extends StatelessWidget {
  const CarpenterApp({
    super.key,
    this.child,
    this.theme,
    this.routerConfig,
    this.shells = const [],
    this.modules = const [],
    this.routes = const [],
    this.missingRouteBuilder,
    this.commands = const [],
    this.onHotkeyCommand,
    this.hotkeyController,
    this.enableHotkeys = true,
    this.trackPressedKeys = true,
    this.autofocusHotkeys = true,
    this.useFrame = false,
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.useSafeArea = true,
    this.framePadding,
    this.backgroundColor,
    this.platform,
    this.locale,
    this.title,
    this.debugShowCheckedModeBanner = false,
  });

  final Widget? child;
  final CarpenterThemeData? theme;
  final RouterConfig<Object>? routerConfig;
  final List<CarpenterShell> shells;
  final List<CarpenterModule> modules;
  final List<CarpenterRoute> routes;
  final Widget Function(BuildContext context, Object? node)?
  missingRouteBuilder;
  final List<CarpenterCommand<void>> commands;
  final CarpenterHotkeyCommandCallback? onHotkeyCommand;
  final CarpenterHotkeyController? hotkeyController;
  final bool enableHotkeys;
  final bool trackPressedKeys;
  final bool autofocusHotkeys;
  final bool useFrame;
  final CarpenterTopPanelBuilder? topPanelBuilder;
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;
  final bool useSafeArea;
  final EdgeInsetsGeometry? framePadding;
  final Color? backgroundColor;
  final TargetPlatform? platform;
  final Locale? locale;
  final String? title;
  final bool debugShowCheckedModeBanner;

  List<CarpenterRoute> get _routes => [
    ...routes,
    for (final module in modules) ...module.routes,
  ];

  List<CarpenterShell> _effectiveShells() {
    final result = <CarpenterShell>[...shells];
    final provided = <Type>{
      for (final shell in shells) ...shell.provides,
      for (final module in modules)
        for (final shell in module.shells) ...shell.provides,
    };
    if (enableHotkeys &&
        !provided.contains(CarpenterHotkeyRuntime) &&
        (commands.isNotEmpty ||
            onHotkeyCommand != null ||
            hotkeyController != null)) {
      result.add(
        CarpenterHotkeyShell(
          commands: commands,
          onCommand: onHotkeyCommand,
          controller: hotkeyController,
          platform: platform,
          trackPressedKeys: trackPressedKeys,
          autofocus: autofocusHotkeys,
        ),
      );
    }
    if (useFrame && !provided.contains(CarpenterFrameRuntime)) {
      result.add(
        CarpenterFrameShell(
          topPanelBuilder: topPanelBuilder,
          desktopTopPanelBuilder: desktopTopPanelBuilder,
          targetPlatform: platform,
          useSafeArea: useSafeArea,
          padding: framePadding,
          backgroundColor: backgroundColor,
        ),
      );
    }
    return result;
  }

  Widget _host(BuildContext context, Widget? routedChild) => CarpenterHost(
    shells: _effectiveShells(),
    modules: modules,
    platform: platform,
    locale: locale,
    child:
        child ??
        routedChild ??
        CarpenterRouteRenderer(
          routes: _routes,
          missingRouteBuilder: (context, node) =>
              missingRouteBuilder?.call(context, node) ??
              const SizedBox.shrink(),
        ),
  );

  @override
  Widget build(BuildContext context) {
    final router = routerConfig;
    if (router != null) {
      return Application.router(
        theme: theme,
        routerConfig: router,
        title: title,
        locale: locale,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        builder: _host,
      );
    }
    return Application(
      theme: theme,
      home: child ?? const SizedBox.shrink(),
      title: title,
      locale: locale,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      builder: _host,
    );
  }
}
