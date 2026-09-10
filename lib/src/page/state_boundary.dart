import 'package:flutter/widgets.dart';

import '../components/basic/loader.dart';
import '../components/basic/progress.dart';
import '../components/behaviour/notice.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import 'state.dart';
import 'package:carpenter_units/carpenter_units.dart';

/// Standard rendering of infrastructure-level page states.
///
/// Works in bounded workspaces and content-sized document viewports. Refreshing
/// keeps the content mounted and interactive; blocking preserves its state while
/// excluding pointer input and keyboard focus. Unknown progress is indeterminate.
final class CarpenterPageStateBoundary extends StatelessWidget {
  const CarpenterPageStateBoundary({
    super.key,
    required this.state,
    required this.child,
  });
  final CarpenterPageState state;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (state) {
    CarpenterPageReady() => _content(context),
    CarpenterPageInitialLoading(:final presentation) =>
      presentation == CarpenterLoadingPresentation.topBar
          ? _content(context, refreshing: true)
          : presentation == CarpenterLoadingPresentation.skeleton
          ? _content(context, skeleton: true)
          : const Center(child: CarpenterLoader()),
    CarpenterPageRefreshing() => _content(context, refreshing: true),
    CarpenterPageBlocking(:final message) => _content(
      context,
      blocking: true,
      message: message,
    ),
    CarpenterPageEmpty(:final descriptor) => _CenteredState(
      title: descriptor.title,
      message: descriptor.message,
      action: descriptor.action == null
          ? null
          : CarpenterActionDescriptor(
              id: '${descriptor.action!.id}.empty',
              label: descriptor.action!.title,
              onInvoke: () => descriptor.action!.execute(null),
            ),
    ),
    CarpenterPageFailure(:final error, :final message, :final retryCommand) =>
      _CenteredState(
        title: 'Unable to load page',
        message: message ?? error.toString(),
        tone: CarpenterNoticeTone.danger,
        action: retryCommand == null
            ? null
            : CarpenterActionDescriptor(
                id: '${retryCommand.id}.retry',
                label: retryCommand.title,
                onInvoke: () => retryCommand.execute(null),
              ),
      ),
    CarpenterPageForbidden(:final reason) => _CenteredState(
      title: 'Access denied',
      message: reason ?? 'You do not have permission to view this page.',
      tone: CarpenterNoticeTone.warning,
    ),
    CarpenterPageUnavailable(:final message, :final retryCommand) =>
      _CenteredState(
        title: 'Page temporarily unavailable',
        message: message,
        tone: CarpenterNoticeTone.warning,
        action: retryCommand == null
            ? null
            : CarpenterActionDescriptor(
                id: '${retryCommand.id}.retry',
                label: retryCommand.title,
                onInvoke: () => retryCommand.execute(null),
              ),
      ),
  };

  // The same content slot survives ready/refreshing/blocking transitions.
  // Positioned overlays follow its natural height in a document viewport and
  // fill the available space in a bounded collection viewport.
  Widget _content(
    BuildContext context, {
    bool refreshing = false,
    bool blocking = false,
    bool skeleton = false,
    String? message,
  }) => Stack(
    fit: StackFit.passthrough,
    children: [
      ExcludeFocus(
        excluding: blocking || skeleton,
        child: AbsorbPointer(
          absorbing: blocking || skeleton,
          child: ExcludeSemantics(
            excluding: skeleton,
            child: Opacity(opacity: skeleton ? 0 : 1, child: child),
          ),
        ),
      ),
      if (refreshing)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(child: CarpenterProgress()),
        ),
      if (skeleton)
        Positioned.fill(
          child: ColoredBox(color: CarpenterTheme.of(context).surface.subtle),
        ),
      if (blocking)
        Positioned.fill(
          child: ColoredBox(
            color: CarpenterTheme.of(context).overlay.scrim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CarpenterLoader(),
                  if (message != null) ...[
                    SizedBox(height: context.units(.75.rem)),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

final class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.title,
    this.message,
    this.tone = CarpenterNoticeTone.info,
    this.action,
  });
  final String title;
  final String? message;
  final CarpenterNoticeTone tone;
  final CarpenterActionDescriptor? action;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.units(35.rem)),
      child: CarpenterNotice(
        title: title,
        message: message,
        tone: tone,
        action: action,
      ),
    ),
  );
}
