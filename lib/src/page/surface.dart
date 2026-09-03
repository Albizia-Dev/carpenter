import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/theme.dart';

enum CarpenterSurfaceKind { inline, sidePanel, fullPage }

abstract interface class CarpenterSurfaceController {
  Future<T?> openInline<T>(WidgetBuilder builder);
  Future<T?> openSidePanel<T>(WidgetBuilder builder);
  Future<T?> openPage<T>(Object destination);
}

typedef CarpenterPageSurfaceOpener =
    Future<Object?> Function(Object destination);

final class CarpenterSurfaceHost extends StatefulWidget {
  const CarpenterSurfaceHost({
    super.key,
    required this.child,
    this.openPage,
    this.sidePanelWidth = const Rem(45),
    this.sidePanelBreakpoint = const Rem(56.25),
    this.sidePanelAlignment = Alignment.centerRight,
  });
  final Widget child;
  final CarpenterPageSurfaceOpener? openPage;
  final LengthUnit sidePanelWidth;
  final LengthUnit sidePanelBreakpoint;
  final Alignment sidePanelAlignment;

  @override
  State<CarpenterSurfaceHost> createState() => _CarpenterSurfaceHostState();
}

final class _CarpenterSurfaceHostState extends State<CarpenterSurfaceHost>
    implements CarpenterSurfaceController {
  _SurfaceRequest? _request;

  @override
  Future<T?> openInline<T>(WidgetBuilder builder) =>
      _open<T>(CarpenterSurfaceKind.inline, builder);
  @override
  Future<T?> openSidePanel<T>(WidgetBuilder builder) =>
      _open<T>(CarpenterSurfaceKind.sidePanel, builder);
  Future<T?> _open<T>(CarpenterSurfaceKind kind, WidgetBuilder builder) {
    _close();
    final request = _SurfaceRequest(kind, builder);
    setState(() => _request = request);
    return request.completer.future.then((value) => value as T?);
  }

  @override
  Future<T?> openPage<T>(Object destination) async {
    final opener = widget.openPage;
    if (opener == null)
      throw StateError('CarpenterSurfaceHost.openPage is not configured.');
    return await opener(destination) as T?;
  }

  void _close([Object? result]) {
    final request = _request;
    if (request == null) return;
    _request = null;
    if (!request.completer.isCompleted) request.completer.complete(result);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sidePanelWidth = context.units(widget.sidePanelWidth);
    final sidePanelBreakpoint = context.units(widget.sidePanelBreakpoint);
    final compactMinWidth = context.units(20.rem);
    final inlineMaxWidth = context.units(47.5.rem);

    return CarpenterSurfaceScope(
      controller: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final request = _request;
          if (request == null) return widget.child;
          final narrow = constraints.maxWidth < sidePanelBreakpoint;
          final fullPage =
              narrow || request.kind == CarpenterSurfaceKind.fullPage;
          final minWidth = constraints.maxWidth < compactMinWidth
              ? constraints.maxWidth
              : compactMinWidth;
          final width = request.kind == CarpenterSurfaceKind.inline
              ? constraints.maxWidth.clamp(minWidth, inlineMaxWidth).toDouble()
              : sidePanelWidth.clamp(minWidth, constraints.maxWidth).toDouble();
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _close,
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: ColoredBox(
                      color: CarpenterTheme.of(context).overlay.scrim,
                    ),
                  ),
                  Align(
                    alignment: fullPage
                        ? Alignment.center
                        : request.kind == CarpenterSurfaceKind.inline
                        ? Alignment.center
                        : widget.sidePanelAlignment,
                    child: SizedBox(
                      width: fullPage ? constraints.maxWidth : width,
                      height: constraints.maxHeight,
                      child: CarpenterSurfaceCloseScope(
                        close: _close,
                        child: Builder(builder: request.builder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    final request = _request;
    if (request != null && !request.completer.isCompleted)
      request.completer.complete();
    super.dispose();
  }
}

final class CarpenterSurfaceScope extends InheritedWidget {
  const CarpenterSurfaceScope({
    super.key,
    required this.controller,
    required super.child,
  });
  final CarpenterSurfaceController controller;
  static CarpenterSurfaceController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CarpenterSurfaceScope>();
    assert(scope != null, 'No CarpenterSurfaceScope found in context.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(CarpenterSurfaceScope oldWidget) =>
      controller != oldWidget.controller;
}

extension CarpenterSurfaceBuildContext on BuildContext {
  CarpenterSurfaceController get surfaces => CarpenterSurfaceScope.of(this);
}

final class CarpenterSurfaceCloseScope extends InheritedWidget {
  const CarpenterSurfaceCloseScope({
    super.key,
    required this.close,
    required super.child,
  });
  final void Function([Object? result]) close;
  static bool maybeClose(BuildContext context, [Object? result]) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CarpenterSurfaceCloseScope>();
    if (scope == null) return false;
    scope.close(result);
    return true;
  }

  @override
  bool updateShouldNotify(CarpenterSurfaceCloseScope oldWidget) => false;
}

final class _SurfaceRequest {
  _SurfaceRequest(this.kind, this.builder);
  final CarpenterSurfaceKind kind;
  final WidgetBuilder builder;
  final Completer<Object?> completer = Completer<Object?>();
}
