import 'package:carpenter/src/legacy/src/component/app_frame/carpenter_app_frame.dart';
import 'package:carpenter/src/legacy/src/component/hotkey/carpenter_hotkey.dart';
import 'package:carpenter/src/legacy/src/module/module.dart';
import 'package:carpenter/src/legacy/src/navigation/route.dart';
import 'package:carpenter/src/legacy/src/navigation/router.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:carpenter/src/legacy/src/root/host.dart';
import 'package:carpenter/src/legacy/src/root/system.dart';
import 'package:carpenter/src/legacy/src/shell/frame_shell.dart';
import 'package:carpenter/src/legacy/src/shell/hotkey_shell.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builder содержимого `CarpenterApp`.
///
/// Вызывается внутри `CarpenterScope`, поэтому в нем уже доступен
/// `context.face`. Возвращенный widget затем, если включено, попадет в
/// `CarpenterAppFrame` и `CarpenterHotkeyScope`.
typedef CarpenterAppBuilder =
    Widget Function(BuildContext context, Widget child);

/// Корневой виджет приложения Carpenter.
///
/// `CarpenterApp` собирает стандартный верхний слой без повторяющегося
/// бойлерплейта: `WidgetsApp`, `CarpenterScope`, typed runtime registry,
/// shell pipeline и route renderer. Низкоуровневые компоненты остаются
/// публичными, но обычному приложению достаточно этого одного входа.
class CarpenterApp extends StatelessWidget {
  /// Создает корневое приложение Carpenter.
  const CarpenterApp({
    super.key,
    this.child,
    this.config = const CarpenterConfig(),
    this.carpenter,
    this.builder,
    this.title = 'Carpenter',
    this.onGenerateTitle,
    this.textStyle,
    this.debugShowCheckedModeBanner = false,
    this.useFrame = true,
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.useSafeArea = true,
    this.framePadding,
    this.backgroundColor,
    this.commands = const [],
    this.onHotkeyCommand,
    this.hotkeyController,
    this.enableHotkeys = true,
    this.trackPressedKeys = true,
    this.autofocusHotkeys = true,
    this.platform,
    this.locale,
    this.routerConfig,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const [Locale('en', 'US')],
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.shells = const [],
    this.modules = const [],
    this.routes = const [],
    this.missingRouteBuilder,
  });

  /// Основное содержимое приложения.
  ///
  /// Если `null`, Carpenter рендерит текущий route tree через
  /// `CarpenterRouteRenderer`.
  final Widget? child;

  /// Декларация visual runtime. Игнорируется, если передан готовый `carpenter`.
  final CarpenterConfig config;

  /// Готовый runtime, если приложение хочет управлять его жизненным циклом само.
  final Carpenter? carpenter;

  /// Дополнительная сборка содержимого внутри `CarpenterScope`.
  final CarpenterAppBuilder? builder;

  /// Заголовок `WidgetsApp`.
  final String title;

  /// Динамический заголовок `WidgetsApp`.
  final GenerateAppTitle? onGenerateTitle;

  /// Базовый text style для `WidgetsApp`.
  final TextStyle? textStyle;

  /// Показывать debug banner Flutter.
  final bool debugShowCheckedModeBanner;

  /// Оборачивать содержимое в `CarpenterAppFrame`.
  final bool useFrame;

  /// Верхняя панель по умолчанию.
  final CarpenterTopPanelBuilder? topPanelBuilder;

  /// Desktop-override верхней панели.
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;

  /// Использовать ли `SafeArea` внутри app frame.
  final bool useSafeArea;

  /// Отступ вокруг app frame.
  final EdgeInsetsGeometry? framePadding;

  /// Цвет фона app frame и `WidgetsApp`.
  final Color? backgroundColor;

  /// Глобальные hotkey-команды приложения.
  final List<CarpenterCommand<void>> commands;

  /// Callback выполнения глобальной hotkey-команды.
  final CarpenterHotkeyCommandCallback? onHotkeyCommand;

  /// Внешний контроллер hotkey-состояния.
  final CarpenterHotkeyController? hotkeyController;

  /// Включить глобальный `CarpenterHotkeyScope`.
  final bool enableHotkeys;

  /// Отслеживать текущие зажатые клавиши.
  final bool trackPressedKeys;

  /// Автофокус hotkey-ветки.
  final bool autofocusHotkeys;

  /// Platform override для frame и hotkeys.
  final TargetPlatform? platform;

  /// Локаль `WidgetsApp`.
  final Locale? locale;

  /// Внешняя Router API конфигурация. Например, `GoRouter`.
  ///
  /// Если задана, Carpenter поднимает `WidgetsApp.router`, но не вмешивается
  /// в устройство внешнего router-а.
  final RouterConfig<Object>? routerConfig;

  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;

  /// App-level middleware shell-и.
  final List<CarpenterShell> shells;

  /// Feature modules, подключенные к приложению.
  final List<CarpenterModule> modules;

  /// Root routes, если приложение хочет объявить их без модуля.
  final List<CarpenterRoute> routes;

  /// UI для отсутствующего route declaration.
  final Widget Function(BuildContext context, Object? node)?
  missingRouteBuilder;

  @override
  Widget build(BuildContext context) {
    final runtime = carpenter ?? Carpenter.fromConfig(config);
    final targetPlatform =
        platform ?? runtime.config.platform ?? defaultTargetPlatform;
    final appLocale = locale ?? runtime.config.locale;
    final appBackground = backgroundColor ?? runtime.face.color('surface.base');
    final appTextStyle =
        textStyle ??
        runtime.face
            .type('body')
            .copyWith(color: runtime.face.color('text.primary'));
    final appShells = _effectiveShells(targetPlatform, appBackground);
    final appRoutes = [
      ...routes,
      for (final module in modules) ...module.routes,
    ];

    Widget buildHost(BuildContext context, Widget? routedChild) {
      final content =
          child ??
          routedChild ??
          CarpenterRouteRenderer(
            routes: appRoutes,
            missingRouteBuilder: missingRouteBuilder,
          );

      return CarpenterHost(
        carpenter: runtime,
        platform: targetPlatform,
        locale: appLocale,
        shells: appShells,
        modules: modules,
        builder: builder,
        child: content,
      );
    }

    final externalRouter = routerConfig;
    if (externalRouter != null) {
      return WidgetsApp.router(
        routerConfig: externalRouter,
        title: title,
        onGenerateTitle: onGenerateTitle,
        textStyle: appTextStyle,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        color: appBackground,
        locale: appLocale,
        builder: buildHost,
        localizationsDelegates: localizationsDelegates,
        localeListResolutionCallback: localeListResolutionCallback,
        localeResolutionCallback: localeResolutionCallback,
        supportedLocales: supportedLocales,
        shortcuts: shortcuts,
        actions: actions,
        restorationScopeId: restorationScopeId,
      );
    }

    return WidgetsApp(
      title: title,
      onGenerateTitle: onGenerateTitle,
      textStyle: appTextStyle,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      color: appBackground,
      locale: appLocale,
      builder: buildHost,
      localizationsDelegates: localizationsDelegates,
      localeListResolutionCallback: localeListResolutionCallback,
      localeResolutionCallback: localeResolutionCallback,
      supportedLocales: supportedLocales,
      shortcuts: shortcuts,
      actions: actions,
      restorationScopeId: restorationScopeId,
    );
  }

  List<CarpenterShell> _effectiveShells(
    TargetPlatform targetPlatform,
    Color appBackground,
  ) {
    final moduleShells = [for (final module in modules) ...module.shells];
    final provided = <Type>{
      for (final shell in shells) ...shell.provides,
      for (final shell in moduleShells) ...shell.provides,
    };
    final result = <CarpenterShell>[...shells];

    if (enableHotkeys &&
        !provided.contains(CarpenterHotkeyRuntime) &&
        (commands.isNotEmpty ||
            onHotkeyCommand != null ||
            hotkeyController != null)) {
      result.add(
        CarpenterHotkeyShell(
          commands: commands,
          onCommand: (runtime, command) => onHotkeyCommand?.call(command),
          controller: hotkeyController,
          platform: targetPlatform,
          trackPressedKeys: trackPressedKeys,
          autofocus: autofocusHotkeys,
        ),
      );
      provided.add(CarpenterHotkeyRuntime);
    }

    if (useFrame && !provided.contains(CarpenterFrameRuntime)) {
      result.add(
        CarpenterFrameShell(
          topPanelBuilder: topPanelBuilder,
          desktopTopPanelBuilder: desktopTopPanelBuilder,
          targetPlatform: targetPlatform,
          useSafeArea: useSafeArea,
          padding: framePadding,
          backgroundColor: appBackground,
        ),
      );
    }

    return result;
  }
}
