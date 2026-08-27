import 'package:carpenter/src/legacy/src/block/page_blocks.dart';
import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/components/basic/card.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

extension type const CarpenterWorkflowTransitionId(String value) {}

final class CarpenterWorkflowException implements Exception {
  const CarpenterWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CarpenterWorkflowTransition<TState, TContext> {
  const CarpenterWorkflowTransition({
    required this.id,
    required this.title,
    required this.canExecute,
    required this.execute,
  });

  final CarpenterWorkflowTransitionId id;
  final String title;
  final bool Function(TState state, TContext context) canExecute;
  final Future<void> Function(TContext context) execute;
}

abstract interface class CarpenterWorkflowController<TState, TContext>
    implements Listenable {
  TState get state;

  TContext get context;

  List<CarpenterWorkflowTransition<TState, TContext>> get availableTransitions;

  bool get executing;

  Object? get error;

  bool get completed;

  Future<void> transition(
    CarpenterWorkflowTransition<TState, TContext> transition,
  );

  Future<void> retry();

  Future<void> cancel();
}

class CarpenterWorkflowControllerBase<TState, TContext> extends ChangeNotifier
    implements CarpenterWorkflowController<TState, TContext> {
  CarpenterWorkflowControllerBase({
    required TState initialState,
    required this.context,
    required List<CarpenterWorkflowTransition<TState, TContext>> Function(
      TState state,
      TContext context,
    )
    transitions,
    required TState Function(
      TState state,
      CarpenterWorkflowTransitionId transition,
    )
    reduce,
    Future<void> Function()? onCancel,
  }) : _state = initialState,
       _transitions = transitions,
       _reduce = reduce,
       _onCancel = onCancel;

  TState _state;

  @override
  TState get state => _state;
  @override
  final TContext context;
  final List<CarpenterWorkflowTransition<TState, TContext>> Function(
    TState state,
    TContext context,
  )
  _transitions;
  final TState Function(TState state, CarpenterWorkflowTransitionId transition)
  _reduce;
  final Future<void> Function()? _onCancel;
  CarpenterWorkflowTransition<TState, TContext>? _last;

  @override
  bool executing = false;
  @override
  Object? error;
  @override
  bool completed = false;

  @override
  List<CarpenterWorkflowTransition<TState, TContext>>
  get availableTransitions => _transitions(state, context);

  @override
  Future<void> transition(
    CarpenterWorkflowTransition<TState, TContext> transition,
  ) async {
    if (executing || !transition.canExecute(state, context)) return;
    executing = true;
    error = null;
    _last = transition;
    notifyListeners();
    try {
      await transition.execute(context);
      _state = _reduce(state, transition.id);
      completed = availableTransitions.isEmpty;
    } catch (failure) {
      error = failure;
    } finally {
      executing = false;
      notifyListeners();
    }
  }

  @override
  Future<void> retry() async {
    final last = _last;
    if (last != null) await transition(last);
  }

  @override
  Future<void> cancel() async {
    await _onCancel?.call();
  }
}

/// Bridges a domain-owned state machine into the Carpenter workflow renderer.
///
/// Use this adapter while the state and transition side effects must remain in
/// an existing feature controller. New workflows can usually use
/// [CarpenterWorkflowControllerBase] directly.
class CarpenterWorkflowDelegateController<TState, TContext>
    extends ChangeNotifier
    implements CarpenterWorkflowController<TState, TContext> {
  CarpenterWorkflowDelegateController({
    required TState Function() readState,
    required this.context,
    required List<CarpenterWorkflowTransition<TState, TContext>> Function(
      TState state,
      TContext context,
    )
    transitions,
    bool Function(TState state, TContext context)? isCompleted,
    Future<void> Function()? onCancel,
  }) : _readState = readState,
       _transitions = transitions,
       _isCompleted = isCompleted,
       _onCancel = onCancel;

  final TState Function() _readState;
  @override
  final TContext context;
  final List<CarpenterWorkflowTransition<TState, TContext>> Function(
    TState state,
    TContext context,
  )
  _transitions;
  final bool Function(TState state, TContext context)? _isCompleted;
  final Future<void> Function()? _onCancel;
  CarpenterWorkflowTransition<TState, TContext>? _last;
  bool _disposed = false;

  @override
  TState get state => _readState();

  @override
  List<CarpenterWorkflowTransition<TState, TContext>>
  get availableTransitions => _transitions(state, context);

  @override
  bool executing = false;

  @override
  Object? error;

  @override
  bool get completed => _isCompleted?.call(state, context) ?? false;

  /// Notifies workflow surfaces after an external domain-state change.
  void notifyExternalChange() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> transition(
    CarpenterWorkflowTransition<TState, TContext> transition,
  ) async {
    if (executing || !transition.canExecute(state, context)) return;
    executing = true;
    error = null;
    _last = transition;
    notifyExternalChange();
    try {
      await transition.execute(context);
    } catch (failure) {
      error = failure;
    } finally {
      executing = false;
      notifyExternalChange();
    }
  }

  @override
  Future<void> retry() async {
    final last = _last;
    if (last != null) await transition(last);
  }

  @override
  Future<void> cancel() async {
    await _onCancel?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

abstract class CarpenterWorkflowStage<TState, TContext> {
  const CarpenterWorkflowStage({
    required this.id,
    required this.title,
    required this.when,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final bool Function(TState state, TContext context) when;

  Widget build(BuildContext context, TState state, TContext workflowContext);
}

/// A workflow stage composed from fields. Carpenter owns the card, labels,
/// vertical rhythm, scrolling and keyboard submission.
class CarpenterFormWorkflowStage<TState, TContext>
    extends CarpenterWorkflowStage<TState, TContext> {
  const CarpenterFormWorkflowStage({
    required super.id,
    required super.title,
    required super.when,
    required this.fields,
    super.description,
  });

  final List<Widget> Function(TState state, TContext context) fields;

  @override
  Widget build(BuildContext context, TState state, TContext workflowContext) {
    final values = fields(state, workflowContext);
    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            values[index],
            if (index < values.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// A workflow stage for choosing exactly one domain item.
class CarpenterSelectionWorkflowStage<TState, TContext, TItem>
    extends CarpenterWorkflowStage<TState, TContext> {
  const CarpenterSelectionWorkflowStage({
    required super.id,
    required super.title,
    required super.when,
    required this.items,
    required this.identity,
    required this.selectedIdentity,
    required this.onSelected,
    required this.itemBuilder,
    this.emptyMessage = 'Нет доступных вариантов',
    super.description,
  });

  final List<TItem> Function(TState state, TContext context) items;
  final Object Function(TItem item) identity;
  final Object? Function(TState state, TContext context) selectedIdentity;
  final ValueChanged<TItem> onSelected;
  final Widget Function(
    BuildContext context,
    TItem item,
    bool selected,
    VoidCallback select,
  )
  itemBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, TState state, TContext workflowContext) {
    final values = items(state, workflowContext);
    final selected = selectedIdentity(state, workflowContext);
    return CarpenterCard(
      child: values.isEmpty
          ? CarpenterEmptyState(
              descriptor: CarpenterEmptyStateDescriptor(title: emptyMessage),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  itemBuilder(
                    context,
                    values[index],
                    identity(values[index]) == selected,
                    () => onSelected(values[index]),
                  ),
                  if (index < values.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

/// Escape hatch for a genuinely domain-specific block, not a page layout.
class CarpenterDomainWorkflowStage<TState, TContext>
    extends CarpenterWorkflowStage<TState, TContext> {
  const CarpenterDomainWorkflowStage({
    required super.id,
    required super.title,
    required super.when,
    required this.block,
    super.description,
  });

  final Widget Function(
    BuildContext context,
    TState state,
    TContext workflowContext,
  )
  block;

  @override
  Widget build(BuildContext context, TState state, TContext workflowContext) =>
      block(context, state, workflowContext);
}

class CarpenterWorkflowPage<TState, TContext> extends StatelessWidget {
  const CarpenterWorkflowPage({
    super.key,
    required this.descriptor,
    required this.controller,
    required this.stages,
    this.header,
    this.progress,
    this.history,
    this.cancelLabel = 'Отмена',
  });

  final CarpenterPageDescriptor descriptor;
  final CarpenterWorkflowController<TState, TContext> controller;
  final List<CarpenterWorkflowStage<TState, TContext>> stages;
  final Widget? header;
  final Widget? progress;
  final Widget? history;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.workflow);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stage = stages
            .cast<CarpenterWorkflowStage<TState, TContext>?>()
            .firstWhere(
              (candidate) =>
                  candidate!.when(controller.state, controller.context),
              orElse: () => null,
            );
        final transitions = controller.availableTransitions;
        final submit = transitions.lastOrNull;
        final page = CarpenterPage(
          descriptor: descriptor,
          state: controller.executing
              ? const CarpenterPageBlocking()
              : const CarpenterPageReady(),
          header: header ?? CarpenterPageHeader(title: Text(descriptor.title)),
          body: ListView(
            children: [
              if (progress != null) ...[progress!, const SizedBox(height: 12)],
              if (stage != null) ...[
                Text(stage.title),
                if (stage.description != null) ...[
                  const SizedBox(height: 4),
                  Text(stage.description!),
                ],
                const SizedBox(height: 12),
              ],
              if (controller.error != null) ...[
                CarpenterNotice(
                  title: const Text('Не удалось выполнить переход'),
                  content: Text(controller.error.toString()),
                  tone: CarpenterNoticeTone.danger,
                  action: CarpenterButton(
                    label: 'Повторить',
                    prominence: .outlined,
                    onInvoke: controller.retry,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (stage != null)
                stage.build(context, controller.state, controller.context),
              if (history != null) ...[const SizedBox(height: 12), history!],
            ],
          ),
          footer: CarpenterActionBar(
            secondary: [
              CarpenterButton(
                label: cancelLabel,
                prominence: .outlined,
                onInvoke: controller.executing ? null : controller.cancel,
              ),
              for (final transition in transitions.take(
                transitions.length > 1 ? transitions.length - 1 : 0,
              ))
                CarpenterButton(
                  label: transition.title,
                  prominence: .outlined,
                  onInvoke:
                      !controller.executing &&
                          transition.canExecute(
                            controller.state,
                            controller.context,
                          )
                      ? () => controller.transition(transition)
                      : null,
                ),
            ],
            primary: [
              if (submit != null)
                CarpenterButton(
                  label: submit.title,
                  colorRole: .primary,
                  prominence: .high,
                  onInvoke:
                      !controller.executing &&
                          submit.canExecute(
                            controller.state,
                            controller.context,
                          )
                      ? () => controller.transition(submit)
                      : null,
                ),
            ],
          ),
        );
        if (submit == null) return page;
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
              if (!controller.executing &&
                  submit.canExecute(controller.state, controller.context)) {
                controller.transition(submit);
              }
            },
          },
          child: Focus(autofocus: true, child: page),
        );
      },
    );
  }
}
