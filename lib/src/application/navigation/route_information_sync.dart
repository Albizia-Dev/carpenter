import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yx_navigation/yx_navigation.dart';

/// Converts incoming platform route information into the application's
/// yx_navigation route tree.
typedef CarpenterRouteTreeParser = RouteNode Function(Uri uri);

/// Serializes the current yx_navigation route tree into platform route
/// information.
typedef CarpenterRouteTreeSerializer = Uri Function(RouteNode? node);

/// Synchronizes yx_navigation route state with Flutter route information/history.
final class CarpenterRouteInformationSync with WidgetsBindingObserver {
  /// Creates a bidirectional bridge between a route-node state manager and
  /// Flutter platform history. Call [attach] once and [dispose] when its owner is
  /// torn down.
  CarpenterRouteInformationSync({
    required this.navigation,
    required this.parse,
    required this.convert,
    this.useMultiEntryHistory = true,
  });

  /// Navigation state manager observed for application-initiated route changes
  /// and mutated for platform-initiated route information.
  final RouteNodeStateManager navigation;

  /// Parser used for incoming platform URIs before mutating [navigation].
  final CarpenterRouteTreeParser parse;

  /// Serializer used when reporting navigation state back to platform history.
  final CarpenterRouteTreeSerializer convert;

  /// Whether [attach] asks the platform to use multi-entry browser/history
  /// integration before synchronizing route changes.
  final bool useMultiEntryHistory;
  StreamSubscription<RouteNode?>? _subscription;
  Uri? _lastUri;

  /// URI derived from Flutter's initial platform route name.
  static Uri get initialUri =>
      Uri.parse(WidgetsBinding.instance.platformDispatcher.defaultRouteName);

  /// Starts observing platform route information and navigation changes, reports
  /// the current state as a replacement entry, and optionally enables multi-entry
  /// history.
  void attach() {
    WidgetsBinding.instance.addObserver(this);
    if (useMultiEntryHistory)
      unawaited(SystemNavigator.selectMultiEntryHistory());
    _reportRouteInformation(navigation.state, replace: true);
    _subscription = navigation.stream.listen(_onRouteChanged);
  }

  /// Stops platform observation and awaits cancellation of the navigation stream
  /// subscription.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Handles platform or browser route information by parsing it, recording its
  /// canonical serialized URI, mutating navigation state, and reporting the event
  /// as handled.
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final nextTree = parse(routeInformation.uri);
    _lastUri = convert(nextTree);
    navigation.mutate((_) => nextTree);
    return true;
  }

  void _onRouteChanged(RouteNode? node) =>
      _reportRouteInformation(node, replace: false);

  void _reportRouteInformation(RouteNode? node, {required bool replace}) {
    final uri = convert(node);
    if (_lastUri?.toString() == uri.toString()) return;
    _lastUri = uri;
    unawaited(
      SystemNavigator.routeInformationUpdated(uri: uri, replace: replace),
    );
  }
}
