import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../components/basic/card.dart';
import '../components/basic/text.dart';
import '../components/behaviour/notice.dart';
import '../components/layout/page_header.dart';
import '../components/layout/patterns/page_body.dart';
import '../components/layout/patterns/page_blocks.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

extension type const CarpenterWorkflowTransitionId(String value) {}

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

final class CarpenterWorkflowControllerBase<TState, TContext>
    extends ChangeNotifier
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

final class CarpenterWorkflowDelegateController<TState, TContext>
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
  void notifyExternalChange() => notifyListeners();
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

final class CarpenterFormWorkflowStage<TState, TContext>
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
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            values[index],
            if (index < values.length - 1) SizedBox(height: gap),
          ],
        ],
      ),
    );
  }
}

final class CarpenterSelectionWorkflowStage<TState, TContext, TItem>
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
    this.emptyMessage = 'No options',
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
    if (values.isEmpty) return Center(child: CarpenterText.body(emptyMessage));
    final selected = selectedIdentity(state, workflowContext);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in values)
          Padding(
            padding: EdgeInsets.only(bottom: context.units(.5.rem)),
            child: itemBuilder(
              context,
              item,
              identity(item) == selected,
              () => onSelected(item),
            ),
          ),
      ],
    );
  }
}

final class CarpenterDomainWorkflowStage<TState, TContext>
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

final class CarpenterWorkflowPage<TState, TContext> extends StatelessWidget {
  const CarpenterWorkflowPage({
    super.key,
    required this.descriptor,
    required this.controller,
    required this.stages,
    this.header,
    this.progress,
    this.history,
    this.cancelLabel = 'Cancel',
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
    final gap = context.units(CarpenterTheme.of(context).spacing.layoutSection);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        CarpenterWorkflowStage<TState, TContext>? stage;
        for (final candidate in stages) {
          if (candidate.when(controller.state, controller.context)) {
            stage = candidate;
            break;
          }
        }
        final transitions = controller.availableTransitions;
        final submit = transitions.isEmpty ? null : transitions.last;
        final page = CarpenterPage(
          descriptor: descriptor,
          state: controller.executing
              ? const CarpenterPageBlocking()
              : const CarpenterPageReady(),
          header: header ?? CarpenterPageHeader(title: descriptor.title),
          body: CarpenterPageBody(
            children: [
              if (progress != null) progress!,
              if (stage != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CarpenterText.title(stage.title),
                    if (stage.description != null) ...[
                      SizedBox(height: context.units(.25.rem)),
                      CarpenterText.body(
                        stage.description!,
                        colorRole: ContentColorRole.secondary,
                      ),
                    ],
                    SizedBox(height: gap),
                    stage.build(context, controller.state, controller.context),
                  ],
                ),
              if (controller.error != null)
                CarpenterNotice(
                  title: 'Transition failed',
                  message: controller.error.toString(),
                  tone: CarpenterNoticeTone.danger,
                  action: CarpenterActionDescriptor(
                    id: 'workflow.retry',
                    label: 'Retry',
                    onInvoke: controller.retry,
                  ),
                ),
              if (history != null) history!,
            ],
          ),
          footer: CarpenterActionBar(
            secondary: [
              CarpenterButton(
                label: cancelLabel,
                prominence: ActionProminence.outlined,
                onInvoke: controller.executing ? null : controller.cancel,
              ),
              for (final transition in transitions.take(
                transitions.length > 1 ? transitions.length - 1 : 0,
              ))
                CarpenterButton(
                  label: transition.title,
                  prominence: ActionProminence.outlined,
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
                  colorRole: ActionColorRole.primary,
                  prominence: ActionProminence.high,
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
                  submit.canExecute(controller.state, controller.context))
                controller.transition(submit);
            },
          },
          child: Focus(autofocus: true, child: page),
        );
      },
    );
  }
}
