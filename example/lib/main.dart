import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

import 'demo_commands.dart';
import 'demo_routes.dart';
import 'demo_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/operations_page.dart';
import 'pages/project_page.dart';
import 'pages/projects_page.dart';
import 'pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarpenterExampleApp());
}

final class CarpenterExampleApp extends StatefulWidget {
  const CarpenterExampleApp({
    super.key,
    this.syncRouteInformation = true,
    this.initialUri,
  });

  final bool syncRouteInformation;
  final Uri? initialUri;

  @override
  State<CarpenterExampleApp> createState() => _CarpenterExampleAppState();
}

final class _CarpenterExampleAppState extends State<CarpenterExampleApp> {
  late final RouteNodeStateManager _navigation;
  late final DemoNavigator _navigator;
  late final CarpenterToasterController _toaster;
  late final DemoCommands _commands;
  late final CarpenterModule _module;
  CarpenterRouteInformationSync? _routeInformationSync;

  @override
  void initState() {
    super.initState();
    final initialUri =
        widget.initialUri ??
        (widget.syncRouteInformation
            ? CarpenterRouteInformationSync.initialUri
            : Uri(path: '/'));
    _navigation = RouteNodeStateManager(
      routeNode: DemoRoutes.parse(initialUri),
    );
    _navigator = DemoNavigator(_navigation);
    _toaster = CarpenterToasterController();
    _commands = DemoCommands(navigator: _navigator, toaster: _toaster);
    _module = _ExampleModule(_buildRoutes());

    if (widget.syncRouteInformation) {
      _routeInformationSync = CarpenterRouteInformationSync(
        navigation: _navigation,
        parse: DemoRoutes.parse,
        convert: DemoRoutes.serialize,
      )..attach();
    }
  }

  List<CarpenterRoute> _buildRoutes() => [
    CarpenterRoute(
      route: DemoRoutes.dashboard,
      shell: (context, child) => _shell(
        selectedId: 'dashboard',
        title: 'Overview',
        subtitle: 'Carpenter example workspace',
        child: child,
      ),
      page: (context) => DashboardPage(
        navigator: _navigator,
        commands: _commands,
        toaster: _toaster,
      ),
    ),
    CarpenterRoute(
      route: DemoRoutes.projects,
      shell: (context, child) => _shell(
        selectedId: 'projects',
        title: 'Projects',
        subtitle: 'Collection patterns and navigation',
        child: child,
      ),
      page: (context) => ProjectsPage(navigator: _navigator, toaster: _toaster),
    ),
    CarpenterRoute(
      route: DemoRoutes.project,
      shell: (context, child) => _shell(
        selectedId: 'projects',
        title: context.arguments['id'] ?? 'Project',
        subtitle: 'Record composition',
        child: child,
      ),
      page: (context) => ProjectPage(
        projectId: context.arguments['id'] ?? 'CP-1042',
        navigator: _navigator,
        toaster: _toaster,
      ),
    ),
    CarpenterRoute(
      route: DemoRoutes.operations,
      shell: (context, child) => _shell(
        selectedId: 'operations',
        title: 'Operations',
        subtitle: 'Loading, overlays, feedback and hotkeys',
        child: child,
      ),
      page: (context) => OperationsPage(toaster: _toaster),
    ),
    CarpenterRoute(
      route: DemoRoutes.settings,
      shell: (context, child) => _shell(
        selectedId: 'settings',
        title: 'Settings',
        subtitle: 'Controlled form state',
        child: child,
      ),
      page: (context) => SettingsPage(toaster: _toaster),
    ),
  ];

  Widget _shell({
    required String selectedId,
    required String title,
    required String subtitle,
    required Widget child,
  }) => DemoShell(
    selectedId: selectedId,
    title: title,
    subtitle: subtitle,
    commands: _commands,
    toaster: _toaster,
    child: child,
  );

  @override
  Widget build(BuildContext context) => CarpenterApp(
    title: 'Carpenter Example',
    theme: CarpenterThemeData.light(),
    shells: [CarpenterRouterShell(navigation: _navigation)],
    modules: [_module],
    commands: _commands.all,
    debugShowCheckedModeBanner: false,
  );

  @override
  void dispose() {
    if (_routeInformationSync case final sync?) {
      unawaited(sync.dispose());
    }
    _commands.dispose();
    _toaster.dispose();
    unawaited(_navigation.close());
    super.dispose();
  }
}

final class _ExampleModule extends CarpenterModuleBase {
  const _ExampleModule(this._routes);

  final List<CarpenterRoute> _routes;

  @override
  String get id => 'carpenter.example.workspace';

  @override
  List<CarpenterRoute> get routes => _routes;
}
