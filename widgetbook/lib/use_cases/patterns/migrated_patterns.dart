import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

enum _EditorScenario {
  ready,
  dirty,
  validating,
  saving,
  validationFailure,
  saveFailure,
  conflict,
  forbidden,
}

enum _WorkflowStart { review, decision, done }

final recordPatternComponent = WidgetbookComponent(
  name: 'Record',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _record)],
);

final editorPatternComponent = WidgetbookComponent(
  name: 'Editor',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _editor)],
);

final workflowPatternComponent = WidgetbookComponent(
  name: 'Workflow',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _workflow)],
);

final explorerPatternComponent = WidgetbookComponent(
  name: 'Explorer',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _explorer)],
);

Widget _record(BuildContext context) {
  final title = context.knobs.string(
    label: 'Entity · Title',
    initialValue: 'Invoice INV-440',
  );
  final subtitle = context.knobs.string(
    label: 'Entity · Subtitle',
    initialValue: 'Albizia LLC · 28 August 2026',
  );
  final statusLabel = context.knobs.string(
    label: 'Status · Label',
    initialValue: 'Awaiting approval',
  );
  final statusRole = context.knobs.object.segmented(
    label: 'Status · Role',
    options: FeedbackColorRole.values,
    initialOption: FeedbackColorRole.warning,
    labelBuilder: (value) => value.name,
  );
  final amount = context.knobs.string(
    label: 'Data · Amount',
    initialValue: '125,000.40 ₽',
  );
  final owner = context.knobs.string(
    label: 'Data · Owner',
    initialValue: 'NC',
  );
  final showPrimaryAction = context.knobs.boolean(
    label: 'Actions · Primary',
    initialValue: true,
  );
  final showTimeline = context.knobs.boolean(
    label: 'Content · Timeline',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 980,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final height = context.knobs.double.slider(
    label: 'Layout · Height',
    initialValue: 680,
    min: 420,
    max: 900,
    divisions: 24,
  );

  return SizedBox(
    width: width,
    height: height,
    child: CarpenterRecordPage<void>(
      descriptor: CarpenterPageDescriptor(
        id: const CarpenterPageId('invoice.440'),
        title: title,
        kind: CarpenterPageKind.record,
      ),
      header: CarpenterEntityHeader(
        title: title,
        subtitle: subtitle,
        status: CarpenterPageStatus(label: statusLabel, role: statusRole),
        metadata: [
          CarpenterTag(label: amount, tone: CarpenterTagTone.info),
          const CarpenterTag(label: 'Contract CTR-22'),
        ],
        primaryActions: showPrimaryAction
            ? [
                CarpenterActionDescriptor(
                  id: 'approve',
                  label: 'Approve',
                  colorRole: ActionColorRole.primary,
                  onInvoke: () {},
                ),
              ]
            : const [],
        secondaryActions: [
          CarpenterActionDescriptor(id: 'edit', label: 'Edit', onInvoke: () {}),
        ],
      ),
      summary: CarpenterRecordSummary(
        children: [
          CarpenterRecordMetric(
            label: 'Amount',
            value: CarpenterText.title(amount),
          ),
          const CarpenterRecordMetric(
            label: 'Due date',
            value: CarpenterText.title('05.09.2026'),
          ),
          CarpenterRecordMetric(
            label: 'Owner',
            value: CarpenterText.title(owner),
          ),
        ],
      ),
      sections: [
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('details'),
          title: 'Details',
          child: const CarpenterRecordDetails(
            details: [
              CarpenterRecordDetail(
                label: 'Counterparty',
                value: CarpenterText.body('Albizia LLC'),
              ),
              CarpenterRecordDetail(
                label: 'Bank account',
                value: CarpenterText.body('40702810900000000001'),
              ),
              CarpenterRecordDetail(
                label: 'Purpose',
                value: CarpenterText.body('Payment under contract CTR-22'),
              ),
            ],
          ),
        ),
      ],
      timeline: showTimeline
          ? CarpenterTimeline(
              items: [
                CarpenterTimelineItem(
                  id: 1,
                  title: 'Invoice created',
                  timestamp: DateTime(2026, 8, 27, 10, 30),
                  description: 'Imported from external system',
                ),
                CarpenterTimelineItem(
                  id: 2,
                  title: 'Sent for approval',
                  timestamp: DateTime(2026, 8, 28, 9, 15),
                ),
              ],
            )
          : null,
    ),
  );
}

Widget _editor(BuildContext context) {
  final scenario = context.knobs.object.segmented(
    label: 'State · Editor',
    options: _EditorScenario.values,
    initialOption: _EditorScenario.dirty,
    labelBuilder: (value) => value.name,
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Edit counterparty',
  );
  final name = context.knobs.string(
    label: 'Data · Name',
    initialValue: 'Albizia LLC',
  );
  final inn = context.knobs.string(
    label: 'Data · INN',
    initialValue: '7712345678',
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 900,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final height = context.knobs.double.slider(
    label: 'Layout · Height',
    initialValue: 620,
    min: 420,
    max: 900,
    divisions: 24,
  );

  final state = switch (scenario) {
    _EditorScenario.ready => const CarpenterEditorReady(dirty: false),
    _EditorScenario.dirty => const CarpenterEditorReady(dirty: true),
    _EditorScenario.validating => const CarpenterEditorValidating(),
    _EditorScenario.saving => const CarpenterEditorSaving(),
    _EditorScenario.validationFailure =>
      const CarpenterEditorValidationFailure({
        CarpenterFieldId('name'): 'Name is required',
        CarpenterFieldId('inn'): 'INN must contain 10 digits',
      }),
    _EditorScenario.saveFailure => CarpenterEditorSaveFailure(
      StateError('Backend rejected the update'),
    ),
    _EditorScenario.conflict => const CarpenterEditorConflict(
      message: 'This record was changed in another session.',
    ),
    _EditorScenario.forbidden => const CarpenterEditorForbidden(),
  };

  return SizedBox(
    width: width,
    height: height,
    child: CarpenterEditorPage<void>(
      descriptor: CarpenterPageDescriptor(
        id: const CarpenterPageId('counterparty.editor'),
        title: title,
        kind: CarpenterPageKind.editor,
      ),
      editorState: state,
      sections: [
        CarpenterPageSection(
          id: const CarpenterPageSectionId('main'),
          title: 'Main information',
          child: _DemoEditorFields(name: name, inn: inn),
        ),
      ],
    ),
  );
}

final class _DemoEditorFields extends StatefulWidget {
  const _DemoEditorFields({required this.name, required this.inn});

  final String name;
  final String inn;

  @override
  State<_DemoEditorFields> createState() => _DemoEditorFieldsState();
}

final class _DemoEditorFieldsState extends State<_DemoEditorFields> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name,
  );
  late final TextEditingController _inn = TextEditingController(text: widget.inn);

  @override
  void didUpdateWidget(_DemoEditorFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _name.text = widget.name;
    if (oldWidget.inn != widget.inn) _inn.text = widget.inn;
  }

  @override
  void dispose() {
    _name.dispose();
    _inn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterFieldGroup(
    columns: 2,
    children: [
      CarpenterInput(controller: _name, label: 'Name', required: true),
      CarpenterInput(controller: _inn, label: 'INN', required: true),
    ],
  );
}

Widget _workflow(BuildContext context) {
  final start = context.knobs.object.segmented(
    label: 'State · Start stage',
    options: _WorkflowStart.values,
    initialOption: _WorkflowStart.review,
    labelBuilder: (value) => value.name,
  );
  final failTransitions = context.knobs.boolean(
    label: 'Execution · Fail transitions',
    initialValue: false,
  );
  final delayMs = context.knobs.double.slider(
    label: 'Execution · Delay (ms)',
    initialValue: 500,
    min: 0,
    max: 2000,
    divisions: 20,
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Payment approval',
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 900,
    min: 320,
    max: 1200,
    divisions: 44,
  );

  final initialState = switch (start) {
    _WorkflowStart.review => 0,
    _WorkflowStart.decision => 1,
    _WorkflowStart.done => 2,
  };

  return _WorkflowPreview(
    key: ValueKey((initialState, failTransitions, delayMs)),
    initialState: initialState,
    failTransitions: failTransitions,
    delay: Duration(milliseconds: delayMs.round()),
    title: title,
    width: width,
  );
}

final class _WorkflowPreview extends StatefulWidget {
  const _WorkflowPreview({
    super.key,
    required this.initialState,
    required this.failTransitions,
    required this.delay,
    required this.title,
    required this.width,
  });

  final int initialState;
  final bool failTransitions;
  final Duration delay;
  final String title;
  final double width;

  @override
  State<_WorkflowPreview> createState() => _WorkflowPreviewState();
}

final class _WorkflowPreviewState extends State<_WorkflowPreview> {
  late final CarpenterWorkflowControllerBase<int, Map<String, Object?>>
  _controller = CarpenterWorkflowControllerBase<int, Map<String, Object?>>(
    initialState: widget.initialState,
    context: <String, Object?>{},
    transitions: (state, context) => switch (state) {
      0 => [
        CarpenterWorkflowTransition<int, Map<String, Object?>>(
          id: const CarpenterWorkflowTransitionId('continue'),
          title: 'Continue',
          canExecute: (_, _) => true,
          execute: (_) async {
            await Future<void>.delayed(widget.delay);
            if (widget.failTransitions) {
              throw StateError('Simulated transition failure');
            }
          },
        ),
      ],
      1 => [
        CarpenterWorkflowTransition<int, Map<String, Object?>>(
          id: const CarpenterWorkflowTransitionId('reject'),
          title: 'Reject',
          canExecute: (_, _) => true,
          execute: (_) async {
            await Future<void>.delayed(widget.delay);
            if (widget.failTransitions) {
              throw StateError('Simulated transition failure');
            }
          },
        ),
        CarpenterWorkflowTransition<int, Map<String, Object?>>(
          id: const CarpenterWorkflowTransitionId('approve'),
          title: 'Approve',
          canExecute: (_, _) => true,
          execute: (_) async {
            await Future<void>.delayed(widget.delay);
            if (widget.failTransitions) {
              throw StateError('Simulated transition failure');
            }
          },
        ),
      ],
      _ => const [],
    },
    reduce: (state, transition) => state + 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    height: 620,
    child: CarpenterWorkflowPage<int, Map<String, Object?>>(
      descriptor: CarpenterPageDescriptor(
        id: const CarpenterPageId('approval.workflow'),
        title: widget.title,
        kind: CarpenterPageKind.workflow,
      ),
      controller: _controller,
      progress: CarpenterProgress(value: (_controller.state + 1) / 3),
      stages: [
        CarpenterFormWorkflowStage<int, Map<String, Object?>>(
          id: 'review',
          title: 'Review payment',
          description:
              'Check the amount and payment purpose before continuing.',
          when: (state, _) => state == 0,
          fields: (_, _) => const [
            CarpenterRecordMetric(
              label: 'Amount',
              value: CarpenterText.title('125,000.40 ₽'),
            ),
            CarpenterRecordMetric(
              label: 'Purpose',
              value: CarpenterText.body('Payment under contract CTR-22'),
            ),
          ],
        ),
        CarpenterSelectionWorkflowStage<int, Map<String, Object?>, String>(
          id: 'decision',
          title: 'Choose decision',
          when: (state, _) => state == 1,
          items: (_, _) => const [
            'Approve without comment',
            'Request clarification',
          ],
          identity: (item) => item,
          selectedIdentity: (_, context) => context['decision'],
          onSelected: (item) =>
              setState(() => _controller.context['decision'] = item),
          itemBuilder: (context, item, selected, select) => CarpenterListTile(
            title: CarpenterText.body(item),
            selected: selected,
            onInvoke: select,
          ),
        ),
        CarpenterDomainWorkflowStage<int, Map<String, Object?>>(
          id: 'done',
          title: 'Completed',
          when: (state, _) => state >= 2,
          block: (_, _, _) => const CarpenterNotice(
            title: 'Workflow complete',
            message: 'No transitions remain.',
            tone: CarpenterNoticeTone.success,
          ),
        ),
      ],
    ),
  );
}

Widget _explorer(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Files',
  );
  final searchLabel = context.knobs.string(
    label: 'Content · Search area',
    initialValue: 'Search files and folders',
  );
  final currentFolder = context.knobs.string(
    label: 'Data · Current folder',
    initialValue: 'Contracts',
  );
  final selectedFile = context.knobs.string(
    label: 'Data · Selected file',
    initialValue: 'CTR-22.pdf',
  );
  final showInspector = context.knobs.boolean(
    label: 'Content · Inspector',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 980,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final height = context.knobs.double.slider(
    label: 'Layout · Height',
    initialValue: 620,
    min: 420,
    max: 900,
    divisions: 24,
  );

  return SizedBox(
    width: width,
    height: height,
    child: CarpenterExplorerPage(
      descriptor: CarpenterPageDescriptor(
        id: const CarpenterPageId('files.explorer'),
        title: title,
        kind: CarpenterPageKind.explorer,
      ),
      search: CarpenterText.caption(searchLabel),
      navigation: const CarpenterCard(
        child: CarpenterInspector(
          value: {
            'folders': ['Contracts', 'Invoices', 'Acts'],
          },
        ),
      ),
      compactNavigation: CarpenterCard(
        child: CarpenterText.body('Current: $currentFolder'),
      ),
      content: const CarpenterCard(
        child: CarpenterInspector(
          value: {
            'files': ['CTR-22.pdf', 'INV-440.pdf', 'ACT-18.pdf'],
          },
        ),
      ),
      inspector: showInspector
          ? SizedBox(
              width: 240,
              child: CarpenterCard(
                child: CarpenterInspector(
                  value: {
                    'name': selectedFile,
                    'size': '2.4 MB',
                    'owner': 'NC',
                  },
                ),
              ),
            )
          : null,
    ),
  );
}
