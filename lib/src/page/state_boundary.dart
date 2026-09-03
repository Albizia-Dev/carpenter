import 'package:flutter/widgets.dart';

import '../components/basic/loader.dart';
import '../components/basic/progress.dart';
import '../components/behaviour/notice.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import 'state.dart';

import 'package:carpenter_units/carpenter_units.dart';

/// Standard rendering of infrastructure-level page states.
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
    CarpenterPageReady() => child,
    CarpenterPageInitialLoading(:final presentation) =>
      presentation == CarpenterLoadingPresentation.topBar
          ? Stack(
              fit: StackFit.expand,
              children: [
                child,
                const Align(
                  alignment: Alignment.topCenter,
                  child: CarpenterProgress(value: .45),
                ),
              ],
            )
          : presentation == CarpenterLoadingPresentation.skeleton
          ? ColoredBox(
              color: CarpenterTheme.of(context).surface.subtle,
              child: const SizedBox.expand(),
            )
          : const Center(child: CarpenterLoader()),
    CarpenterPageRefreshing() => Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Align(
          alignment: Alignment.topCenter,
          child: CarpenterProgress(value: .65),
        ),
      ],
    ),
    CarpenterPageBlocking(:final message) => Stack(
      fit: StackFit.expand,
      children: [
        child,
        ColoredBox(
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
      ],
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
