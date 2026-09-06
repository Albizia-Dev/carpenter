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

  /// Navigator key used by the non-router application mode. It is ignored by
  /// [Application.router].
  final GlobalKey<NavigatorState>? navigatorKey;
  /// Route factory forwarded to [WidgetsApp] in navigator mode when a named route is
  /// requested.
  final RouteFactory? onGenerateRoute;
  /// Factory used by navigator mode to expand [initialRoute] into the initial route
  /// stack.
  final InitialRouteListFactory? onGenerateInitialRoutes;
  /// Fallback route factory used by navigator mode when [onGenerateRoute] and [routes]
  /// cannot resolve a name.
  final RouteFactory? onUnknownRoute;
  /// Optional listener for framework [NavigationNotification] events emitted by
  /// either navigator or router application mode.
  final NotificationListenerCallback<NavigationNotification>?
  onNavigationNotification;
  /// Observers attached to the [Navigator] in non-router mode. Defaults to an empty
  /// list.
  final List<NavigatorObserver>? navigatorObservers;
  /// Initial named route for navigator mode. Router mode obtains its initial location
  /// from router configuration instead.
  final String? initialRoute;
  /// Factory used to turn a route builder into a [PageRoute] in navigator mode.
  /// Carpenter supplies a simple [PageRouteBuilder] when omitted.
  final PageRouteFactory? pageRouteBuilder;
  /// Default navigator-mode content when no named initial route replaces it.
  final Widget? home;
  /// Named route table forwarded to [WidgetsApp] in navigator mode. Defaults to an
  /// empty map.
  final Map<String, WidgetBuilder>? routes;
  /// Optional application-level transition builder invoked inside [CarpenterTheme]. Use
  /// it to wrap the routed child without replacing Carpenter theme or unit scopes.
  final TransitionBuilder? builder;
  /// Static application title forwarded to the underlying [WidgetsApp].
  final String? title;
  /// Locale-aware title generator forwarded to the underlying [WidgetsApp]; when
  /// present it takes precedence over a static title where Flutter applies it.
  final GenerateAppTitle? onGenerateTitle;
  /// Requested application locale. Flutter resolves it against [supportedLocales] and
  /// the configured resolution callbacks.
  final Locale? locale;
  /// Localization delegates forwarded to the underlying [WidgetsApp].
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  /// Optional locale-list resolver forwarded to [WidgetsApp].
  final LocaleListResolutionCallback? localeListResolutionCallback;
  /// Optional single-locale resolver forwarded to [WidgetsApp].
  final LocaleResolutionCallback? localeResolutionCallback;
  /// Locales supported by the application. Defaults to US English.
  final Iterable<Locale> supportedLocales;
  /// Whether Flutter draws its performance overlay above the application.
  final bool showPerformanceOverlay;
  /// Whether Flutter draws the semantics debugger overlay.
  final bool showSemanticsDebugger;
  /// Whether Flutter exposes the widget-inspector selection affordance in debug mode.
  final bool debugShowWidgetInspector;
  /// Whether Flutter shows the checked-mode debug banner.
  final bool debugShowCheckedModeBanner;
  /// Optional builder for Flutter inspector UI used to exit widget-selection mode.
  final ExitWidgetSelectionButtonBuilder? exitWidgetSelectionButtonBuilder;
  /// Optional builder for the control that repositions Flutter inspector exit UI.
  final MoveExitWidgetSelectionButtonBuilder?
  moveExitWidgetSelectionButtonBuilder;
  /// Optional builder for Flutter inspector tap-behavior UI.
  final TapBehaviorButtonBuilder? tapBehaviorButtonBuilder;
  /// Application-wide Flutter shortcut mapping forwarded to the underlying
  /// [WidgetsApp]. Carpenter command shortcuts can be layered below this root.
  final Map<ShortcutActivator, Intent>? shortcuts;
  /// Application-wide Flutter action mapping forwarded to the underlying [WidgetsApp].
  final Map<Type, Action<Intent>>? actions;
  /// Restoration scope identifier forwarded to the underlying [WidgetsApp].
  final String? restorationScopeId;

  /// Route-information provider used only by [Application.router].
  final RouteInformationProvider? routeInformationProvider;
  /// Route-information parser used only by [Application.router] when a complete
  /// [routerConfig] is not supplied.
  final RouteInformationParser<Object>? routeInformationParser;
  /// Router delegate used only by [Application.router] when a complete [routerConfig]
  /// is not supplied.
  final RouterDelegate<Object>? routerDelegate;
  /// Complete Flutter router configuration for [Application.router]. Do not combine it
  /// with separate provider/parser/delegate pieces unless Flutter explicitly supports
  /// that combination.
  final RouterConfig<Object>? routerConfig;
  /// Back-button dispatcher forwarded to [WidgetsApp.router].
  final BackButtonDispatcher? backButtonDispatcher;
  final bool _isRouter;

  static PageRoute<T> _defaultPageRouteBuilder<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );

  /// Builds either [WidgetsApp] or [WidgetsApp.router], then installs the root
  /// [UnitsRoot] and [CarpenterTheme] around the framework-provided routed child.
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
