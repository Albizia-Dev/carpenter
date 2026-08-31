import 'package:yx_navigation/yx_navigation.dart';

abstract final class DemoRoutes {
  static const dashboard = YxRoute(id: 'dashboard');
  static const projects = YxRoute(id: 'projects');
  static const project = YxRoute(id: 'project');
  static const planning = YxRoute(id: 'planning');
  static const explorer = YxRoute(id: 'explorer');
  static const operations = YxRoute(id: 'operations');
  static const settings = YxRoute(id: 'settings');

  static RouteNode parse(Uri uri) {
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return dashboard.toNode();
    return switch (segments.first) {
      'projects' when segments.length > 1 => project.toNode(
        arguments: <String, String>{'id': segments[1]},
      ),
      'projects' => projects.toNode(),
      'planning' => planning.toNode(),
      'explorer' => explorer.toNode(),
      'operations' => operations.toNode(),
      'settings' => settings.toNode(),
      _ => dashboard.toNode(),
    };
  }

  static Uri serialize(RouteNode? node) {
    if (node == null) return Uri(path: '/');
    return switch (node.route.id) {
      'projects' => Uri(path: '/projects'),
      'project' => Uri(path: '/projects/${node.arguments['id'] ?? 'CP-1042'}'),
      'planning' => Uri(path: '/planning'),
      'explorer' => Uri(path: '/explorer'),
      'operations' => Uri(path: '/operations'),
      'settings' => Uri(path: '/settings'),
      _ => Uri(path: '/'),
    };
  }
}

final class DemoNavigator {
  const DemoNavigator(this.navigation);

  final NavigationController navigation;

  void dashboard() => go(DemoRoutes.dashboard);
  void projects() => go(DemoRoutes.projects);
  void planning() => go(DemoRoutes.planning);
  void explorer() => go(DemoRoutes.explorer);
  void operations() => go(DemoRoutes.operations);
  void settings() => go(DemoRoutes.settings);

  void project(String id) =>
      go(DemoRoutes.project, arguments: <String, String>{'id': id});

  void go(YxRoute route, {Map<String, String>? arguments}) {
    navigation.mutate(
      (_) => route.toNode(arguments: arguments ?? const <String, String>{}),
    );
  }
}
