import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/legacy/src/component/loader/carpenter_loader.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart'
    show CarpenterNotice, CarpenterNoticeTone, CarpenterPageLoadingBar;
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Standard rendering of page-level infrastructure states.
class CarpenterPageStateBoundary extends StatelessWidget {
  const CarpenterPageStateBoundary({
    super.key,
    required this.state,
    required this.child,
  });

  final CarpenterPageState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = state;
    return switch (current) {
      CarpenterPageReady() => child,
      CarpenterPageInitialLoading(:final presentation) =>
        presentation == CarpenterLoadingPresentation.topBar
            ? Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  const Align(
                    alignment: Alignment.topCenter,
                    child: CarpenterPageLoadingBar(),
                  ),
                ],
              )
            : _loading(context, presentation),
      CarpenterPageRefreshing() => Stack(
        fit: StackFit.expand,
        children: [
          child,
          const Align(
            alignment: Alignment.topCenter,
            child: CarpenterPageLoadingBar(),
          ),
        ],
      ),
      CarpenterPageBlocking(:final message) => Stack(
        fit: StackFit.expand,
        children: [
          child,
          ColoredBox(
            color: context.face.color('surface.overlay'),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CarpenterLoader(),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      CarpenterPageEmpty(:final descriptor) => _EmptyState(
        descriptor: descriptor,
      ),
      CarpenterPageFailure(:final error, :final message, :final retryCommand) =>
        _CenteredState(
          title: 'Не удалось загрузить страницу',
          message: message ?? error.toString(),
          tone: CarpenterNoticeTone.danger,
          action: retryCommand == null
              ? null
              : CarpenterButton(
                  label: 'Повторить',
                  onInvoke: () => retryCommand.execute(null),
                ),
        ),
      CarpenterPageForbidden(:final reason) => _CenteredState(
        title: 'Нет доступа',
        message: reason ?? 'У вас нет прав для просмотра этой страницы.',
        tone: CarpenterNoticeTone.warning,
      ),
      CarpenterPageUnavailable(:final message, :final retryCommand) =>
        _CenteredState(
          title: 'Страница временно недоступна',
          message: message,
          tone: CarpenterNoticeTone.warning,
          action: retryCommand == null
              ? null
              : CarpenterButton(
                  label: 'Повторить',
                  onInvoke: () => retryCommand.execute(null),
                ),
        ),
    };
  }

  Widget _loading(
    BuildContext context,
    CarpenterLoadingPresentation presentation,
  ) {
    if (presentation == CarpenterLoadingPresentation.skeleton) {
      return Semantics(
        label: 'Загрузка',
        child: ColoredBox(
          color: context.face.color('surface.muted'),
          child: const SizedBox.expand(),
        ),
      );
    }
    return const Center(child: CarpenterLoader());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.descriptor});

  final CarpenterEmptyStateDescriptor descriptor;

  @override
  Widget build(BuildContext context) => _CenteredState(
    title: descriptor.title,
    message: descriptor.message,
    action: descriptor.action == null
        ? null
        : CarpenterButton(
            label: descriptor.action!.title,
            onInvoke: () => descriptor.action!.execute(null),
          ),
  );
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.title,
    this.message,
    this.tone = CarpenterNoticeTone.info,
    this.action,
  });

  final String title;
  final String? message;
  final CarpenterNoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: CarpenterNotice(
        title: Text(title),
        content: message == null ? null : Text(message!),
        tone: tone,
        action: action,
      ),
    ),
  );
}
