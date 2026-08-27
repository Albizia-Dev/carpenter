import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// The root of a Carpenter application.
///
/// [Application] provides Flutter's framework-level application services,
/// Carpenter theme data, and the root unit scale without depending on Material
/// or Cupertino. Use [Application.router] when routing is owned by a [Router].
final class Application extends StatelessWidget {
  /// Creates an application backed by a [Navigator].
  const Application({
    super.key,
    this.theme,
    this.rem = const Px(16),
    this.navigatorKey,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.onNavigationNotification,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.initialRoute,
    this.pageRouteBuilder,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.debugShowCheckedModeBanner = false,
    this.exitWidgetSelectionButtonBuilder,
    this.moveExitWidgetSelectionButtonBuilder,
    this.tapBehaviorButtonBuilder,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       routerConfig = null,
       backButtonDispatcher = null,
       _isRouter = false;

  /// Creates an application backed by a [Router].
  const Application.router({
    super.key,
    this.theme,
    this.rem = const Px(16),
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.debugShowCheckedModeBanner = false,
    this.exitWidgetSelectionButtonBuilder,
    this.moveExitWidgetSelectionButtonBuilder,
    this.tapBehaviorButtonBuilder,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
  }) : navigatorKey = null,
       onGenerateRoute = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       navigatorObservers = null,
       initialRoute = null,
       pageRouteBuilder = null,
       home = null,
       routes = null,
       _isRouter = true;

  /// The semantic theme exposed to the application subtree.
  ///
  /// Defaults to [CarpenterThemeData.light].
  final CarpenterThemeData? theme;

  /// The root size used to resolve [Rem] units.
  final Px rem;

  final GlobalKey<NavigatorState>? navigatorKey;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final NotificationListenerCallback<NavigationNotification>?
  onNavigationNotification;
  final List<NavigatorObserver>? navigatorObservers;
  final String? initialRoute;
  final PageRouteFactory? pageRouteBuilder;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final TransitionBuilder? builder;
  final String? title;
  final GenerateAppTitle? onGenerateTitle;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool debugShowWidgetInspector;
  final bool debugShowCheckedModeBanner;
  final ExitWidgetSelectionButtonBuilder? exitWidgetSelectionButtonBuilder;
  final MoveExitWidgetSelectionButtonBuilder?
  moveExitWidgetSelectionButtonBuilder;
  final TapBehaviorButtonBuilder? tapBehaviorButtonBuilder;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;

  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final RouterConfig<Object>? routerConfig;
  final BackButtonDispatcher? backButtonDispatcher;
  final bool _isRouter;

  static PageRoute<T> _defaultPageRouteBuilder<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? CarpenterThemeData.light();
    final applicationBuilder = _themedBuilder(effectiveTheme);

    return UnitsRoot(
      rem: rem,
      child: _isRouter
          ? WidgetsApp.router(
              routeInformationProvider: routeInformationProvider,
              routeInformationParser: routeInformationParser,
              routerDelegate: routerDelegate,
              routerConfig: routerConfig,
              backButtonDispatcher: backButtonDispatcher,
              builder: applicationBuilder,
              title: title,
              onGenerateTitle: onGenerateTitle,
              onNavigationNotification: onNavigationNotification,
              color: effectiveTheme.surface.base,
              locale: locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              showPerformanceOverlay: showPerformanceOverlay,
              showSemanticsDebugger: showSemanticsDebugger,
              debugShowWidgetInspector: debugShowWidgetInspector,
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              exitWidgetSelectionButtonBuilder:
                  exitWidgetSelectionButtonBuilder,
              moveExitWidgetSelectionButtonBuilder:
                  moveExitWidgetSelectionButtonBuilder,
              tapBehaviorButtonBuilder: tapBehaviorButtonBuilder,
              shortcuts: shortcuts,
              actions: actions,
              restorationScopeId: restorationScopeId,
            )
          : WidgetsApp(
              navigatorKey: navigatorKey,
              onGenerateRoute: onGenerateRoute,
              onGenerateInitialRoutes: onGenerateInitialRoutes,
              onUnknownRoute: onUnknownRoute,
              onNavigationNotification: onNavigationNotification,
              navigatorObservers: navigatorObservers!,
              initialRoute: initialRoute,
              pageRouteBuilder: pageRouteBuilder ?? _defaultPageRouteBuilder,
              home: home,
              routes: routes!,
              builder: applicationBuilder,
              title: title,
              onGenerateTitle: onGenerateTitle,
              color: effectiveTheme.surface.base,
              locale: locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              showPerformanceOverlay: showPerformanceOverlay,
              showSemanticsDebugger: showSemanticsDebugger,
              debugShowWidgetInspector: debugShowWidgetInspector,
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              exitWidgetSelectionButtonBuilder:
                  exitWidgetSelectionButtonBuilder,
              moveExitWidgetSelectionButtonBuilder:
                  moveExitWidgetSelectionButtonBuilder,
              tapBehaviorButtonBuilder: tapBehaviorButtonBuilder,
              shortcuts: shortcuts,
              actions: actions,
              restorationScopeId: restorationScopeId,
            ),
    );
  }

  TransitionBuilder _themedBuilder(CarpenterThemeData effectiveTheme) {
    return (context, child) => CarpenterTheme(
      data: effectiveTheme,
      child: Builder(
        builder: (themedContext) {
          final content =
              builder?.call(themedContext, child) ??
              child ??
              const SizedBox.shrink();
          return ColoredBox(color: effectiveTheme.surface.base, child: content);
        },
      ),
    );
  }
}
