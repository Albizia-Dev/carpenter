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
  /// Creates the high-level Carpenter root, composing optional routing, modules,
  /// shells, command execution, hotkeys, and frame capabilities around
  /// application content.
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
    this.commandExecutor,
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

  /// Optional direct application content. Internal declared routes are rendered
  /// when this is absent and no external router owns the routed child.
  final Widget? child;

  /// Carpenter theme passed to the underlying [Application]; defaults there to
  /// the light theme when omitted.
  final CarpenterThemeData? theme;

  /// Optional external Flutter router configuration. When present,
  /// [CarpenterApp] uses [Application.router] and treats its routed child as
  /// authoritative content.
  final RouterConfig<Object>? routerConfig;

  /// Application shells supplied directly by the caller before any automatically
  /// added hotkey or frame shell.
  final List<CarpenterShell> shells;

  /// Feature modules whose routes, shells, and runtime requirements participate
  /// in the hosted application.
  final List<CarpenterModule> modules;

  /// Routes declared directly by the application; module routes are appended
  /// when Carpenter builds the effective route list.
  final List<CarpenterRoute> routes;

  /// Optional fallback renderer for an empty or unmatched internal Carpenter
  /// route tree.
  final Widget Function(BuildContext context, Object? node)?
  missingRouteBuilder;

  /// Application-level commands exposed to an automatically installed hotkey
  /// shell when hotkeys are enabled.
  final List<CarpenterCommand<void>> commands;

  /// Optional application-wide execution policy for command surfaces.
  ///
  /// When provided, Carpenter command buttons, command-input buttons, and
  /// shortcut scopes below the app emit their executions through this executor.
  final CarpenterCommandExecutor? commandExecutor;

  /// Optional observer invoked before an application hotkey executes its command.
  final CarpenterHotkeyCommandCallback? onHotkeyCommand;

  /// Optional caller-owned hotkey controller forwarded to the automatically
  /// installed hotkey shell.
  final CarpenterHotkeyController? hotkeyController;

  /// Whether [CarpenterApp] may add a hotkey shell when commands or hotkey hooks
  /// are configured and no shell already provides hotkey runtime capability.
  final bool enableHotkeys;

  /// Whether an automatically installed hotkey scope records currently pressed
  /// hardware keys.
  final bool trackPressedKeys;

  /// Whether an automatically installed hotkey scope requests focus so
  /// application shortcuts work without an explicit focus request.
  final bool autofocusHotkeys;

  /// Whether [CarpenterApp] may add the standard frame shell when no existing
  /// shell or module already provides frame runtime capability.
  final bool useFrame;

  /// General top-panel builder forwarded to an automatically installed frame
  /// shell.
  final CarpenterTopPanelBuilder? topPanelBuilder;

  /// Desktop-specific top-panel builder forwarded to an automatically installed
  /// frame shell.
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;

  /// Whether an automatically installed application frame keeps its content
  /// inside the platform safe area.
  final bool useSafeArea;

  /// Optional content padding forwarded to an automatically installed application
  /// frame.
  final EdgeInsetsGeometry? framePadding;

  /// Optional frame background color; theme surface defaults remain authoritative
  /// when this is absent.
  final Color? backgroundColor;

  /// Optional effective target-platform override shared with the host and
  /// automatically installed frame/hotkey shells.
  final TargetPlatform? platform;

  /// Optional locale forwarded to the low-level application root and core runtime
  /// capability.
  final Locale? locale;

  /// Application title forwarded to the underlying Flutter application root.
  final String? title;

  /// Whether Flutter shows its checked-mode debug banner for this application
  /// root.
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

  Widget _host(BuildContext context, Widget? routedChild) {
    final declaredRoutes = _routes;
    Widget content;
    if (routerConfig != null) {
      content = routedChild ?? child ?? const SizedBox.shrink();
    } else if (child != null) {
      content = routedChild ?? child!;
    } else if (declaredRoutes.isNotEmpty) {
      content = CarpenterRouteRenderer(
        routes: declaredRoutes,
        missingRouteBuilder: (context, node) =>
            missingRouteBuilder?.call(context, node) ?? const SizedBox.shrink(),
      );
    } else {
      content = routedChild ?? const SizedBox.shrink();
    }
    Widget host = CarpenterHost(
      shells: _effectiveShells(),
      modules: modules,
      platform: platform,
      locale: locale,
      child: content,
    );
    final executor = commandExecutor;
    if (executor != null) {
      host = CarpenterCommandExecutionScope(executor: executor, child: host);
    }
    return host;
  }

  /// Builds either router or navigator application mode, then hosts effective
  /// routes, modules, shells, and optional command execution below the Carpenter
  /// theme/root services.
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
      home: Builder(builder: (context) => _host(context, null)),
      title: title,
      locale: locale,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }
}
