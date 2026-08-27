import 'dart:async';

import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum CarpenterSurfaceKind { inline, sidePanel, fullPage }

abstract interface class CarpenterSurfaceController {
  Future<T?> openInline<T>(WidgetBuilder builder);
  Future<T?> openSidePanel<T>(WidgetBuilder builder);
  Future<T?> openPage<T>(Object destination);
}

typedef CarpenterPageSurfaceOpener =
    Future<Object?> Function(Object destination);

/// Hosts transient application surfaces without taking ownership of routing.
/// Side panels become full-page overlays below [sidePanelBreakpoint].
class CarpenterSurfaceHost extends StatefulWidget {
  const CarpenterSurfaceHost({
    super.key,
    required this.child,
    this.openPage,
    this.sidePanelWidth = 720,
    this.sidePanelBreakpoint = 900,
    this.sidePanelAlignment = Alignment.centerRight,
  });

  final Widget child;
  final CarpenterPageSurfaceOpener? openPage;
  final double sidePanelWidth;
  final double sidePanelBreakpoint;
  final Alignment sidePanelAlignment;

  @override
  State<CarpenterSurfaceHost> createState() => _CarpenterSurfaceHostState();
}

class _CarpenterSurfaceHostState extends State<CarpenterSurfaceHost>
    implements CarpenterSurfaceController {
  _CarpenterSurfaceRequest? _request;

  @override
  Future<T?> openInline<T>(WidgetBuilder builder) =>
      _open<T>(CarpenterSurfaceKind.inline, builder);

  @override
  Future<T?> openSidePanel<T>(WidgetBuilder builder) =>
      _open<T>(CarpenterSurfaceKind.sidePanel, builder);

  Future<T?> _open<T>(CarpenterSurfaceKind kind, WidgetBuilder builder) {
    _close();
    final request = _CarpenterSurfaceRequest(kind, builder);
    setState(() => _request = request);
    return request.completer.future.then((value) => value as T?);
  }

  @override
  Future<T?> openPage<T>(Object destination) async {
    final opener = widget.openPage;
    if (opener == null) {
      throw StateError('CarpenterSurfaceHost.openPage is not configured.');
    }
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
  Widget build(BuildContext context) => CarpenterSurfaceScope(
    controller: this,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final request = _request;
        if (request == null) return widget.child;
        final narrow = constraints.maxWidth < widget.sidePanelBreakpoint;
        final fullPage =
            narrow || request.kind == CarpenterSurfaceKind.fullPage;
        final minimumWidth = constraints.maxWidth < 320
            ? constraints.maxWidth
            : 320.0;
        final width = request.kind == CarpenterSurfaceKind.inline
            ? constraints.maxWidth.clamp(minimumWidth, 760).toDouble()
            : widget.sidePanelWidth
                  .clamp(minimumWidth, constraints.maxWidth)
                  .toDouble();
        return CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
          child: Focus(
            autofocus: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                Semantics(
                  button: true,
                  label: 'Закрыть панель',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _close(),
                    child: ColoredBox(
                      color: context.face.color('surface.scrim'),
                    ),
                  ),
                ),
                Align(
                  alignment: fullPage
                      ? Alignment.center
                      : request.kind == CarpenterSurfaceKind.inline
                      ? Alignment.center
                      : widget.sidePanelAlignment,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(request),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, child) =>
                        FractionalTranslation(
                          translation:
                              fullPage ||
                                  request.kind == CarpenterSurfaceKind.inline
                              ? Offset.zero
                              : Offset(
                                  widget.sidePanelAlignment.x < 0
                                      ? progress - 1
                                      : 1 - progress,
                                  0,
                                ),
                          child: child,
                        ),
                    child: SizedBox(
                      width: fullPage ? constraints.maxWidth : width,
                      height: constraints.maxHeight,
                      child: CarpenterSurfaceCloseScope(
                        close: _close,
                        child: Builder(builder: request.builder),
                      ),
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

  @override
  void dispose() {
    final request = _request;
    _request = null;
    if (request != null && !request.completer.isCompleted) {
      request.completer.complete();
    }
    super.dispose();
  }
}

class CarpenterSurfaceCloseScope extends InheritedWidget {
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

class _CarpenterSurfaceRequest {
  _CarpenterSurfaceRequest(this.kind, this.builder);

  final CarpenterSurfaceKind kind;
  final WidgetBuilder builder;
  final Completer<Object?> completer = Completer<Object?>();
}

class CarpenterSurfaceScope extends InheritedWidget {
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
