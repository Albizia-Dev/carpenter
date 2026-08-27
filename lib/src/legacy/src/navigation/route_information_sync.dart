import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

typedef CarpenterRouteTreeParser = RouteNode Function(Uri uri);
typedef CarpenterRouteTreeSerializer = Uri Function(RouteNode? node);

class CarpenterRouteInformationSync with WidgetsBindingObserver {
  CarpenterRouteInformationSync({
    required this.navigation,
    required this.parse,
    required this.convert,
    this.useMultiEntryHistory = true,
  });

  final RouteNodeStateManager navigation;
  final CarpenterRouteTreeParser parse;
  final CarpenterRouteTreeSerializer convert;
  final bool useMultiEntryHistory;

  StreamSubscription<RouteNode?>? _subscription;
  Uri? _lastUri;

  static Uri get initialUri {
    return Uri.parse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
  }

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    if (useMultiEntryHistory) {
      unawaited(SystemNavigator.selectMultiEntryHistory());
    }
    _reportRouteInformation(navigation.state, replace: true);
    _subscription = navigation.stream.listen(_onRouteChanged);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final nextTree = parse(routeInformation.uri);
    _lastUri = convert(nextTree);
    navigation.mutate((_) => nextTree);
    return true;
  }

  void _onRouteChanged(RouteNode? node) {
    _reportRouteInformation(node, replace: false);
  }

  void _reportRouteInformation(RouteNode? node, {required bool replace}) {
    final uri = convert(node);

    if (_lastUri?.toString() == uri.toString()) {
      return;
    }

    _lastUri = uri;
    unawaited(
      SystemNavigator.routeInformationUpdated(uri: uri, replace: replace),
    );
  }
}
