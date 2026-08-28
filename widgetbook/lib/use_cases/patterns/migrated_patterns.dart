import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

final recordPatternComponent = WidgetbookComponent(
  name: 'Record',
  useCases: [
    WidgetbookUseCase(name: 'Entity composition', builder: _record),
    WidgetbookUseCase(name: 'Narrow', builder: _recordNarrow),
  ],
);

final editorPatternComponent = WidgetbookComponent(
  name: 'Editor',
  useCases: [WidgetbookUseCase(name: 'State matrix', builder: _editor)],
);

final workflowPatternComponent = WidgetbookComponent(
  name: 'Workflow',
  useCases: [WidgetbookUseCase(name: 'Transitions', builder: (_) => const _WorkflowPreview())],
);

final explorerPatternComponent = WidgetbookComponent(
  name: 'Explorer',
  useCases: [
    WidgetbookUseCase(name: 'Wide', builder: _explorer),
    WidgetbookUseCase(name: 'Narrow', builder: _explorerNarrow),
  ],
);

Widget _record(BuildContext context) => SizedBox(width: 980, height: 680, child: _recordPage());
Widget _recordNarrow(BuildContext context) => SizedBox(width: 420, height: 680, child: _recordPage());

Widget _recordPage() => CarpenterRecordPage<void>(
  descriptor: const CarpenterPageDescriptor(id: CarpenterPageId('invoice.440'), title: 'Invoice INV-440', kind: CarpenterPageKind.record),
  header: CarpenterEntityHeader(
    title: 'Invoice INV-440',
    subtitle: 'Albizia LLC · 28 August 2026',
    status: const CarpenterPageStatus(label: 'Awaiting approval', role: FeedbackColorRole.warning),
    metadata: const [CarpenterTag(label: '125,000.40 ₽', tone: CarpenterTagTone.info), CarpenterTag(label: 'Contract CTR-22')],
    primaryActions: [CarpenterActionDescriptor(id: 'approve', label: 'Approve', colorRole: ActionColorRole.primary, onInvoke: () {})],
    secondaryActions: [CarpenterActionDescriptor(id: 'edit', label: 'Edit', onInvoke: () {})],
  ),
  summary: const CarpenterRecordSummary(children: [
    CarpenterRecordMetric(label: 'Amount', value: CarpenterText.title('125,000.40 ₽')),
    CarpenterRecordMetric(label: 'Due date', value: CarpenterText.title('05.09.2026')),
    CarpenterRecordMetric(label: 'Owner', value: CarpenterText.title('NC')),
  ]),
  sections: [
    CarpenterRecordSection(
      id: const CarpenterPageSectionId('details'),
      title: 'Details',
      child: CarpenterRecordDetails(details: const [
        CarpenterRecordDetail(label: 'Counterparty', value: CarpenterText.body('Albizia LLC')),
        CarpenterRecordDetail(label: 'Bank account', value: CarpenterText.body('40702810900000000001')),
        CarpenterRecordDetail(label: 'Purpose', value: CarpenterText.body('Payment under contract CTR-22')),
      ]),
    ),
  ],
  timeline: CarpenterTimeline(items: [
    CarpenterTimelineItem(id: 1, title: 'Invoice created', timestamp: DateTime(2026, 8, 27, 10, 30), description: 'Imported from external system'),
    CarpenterTimelineItem(id: 2, title: 'Sent for approval', timestamp: DateTime(2026, 8, 28, 9, 15)),
  ]),
);

enum _EditorScenario { ready, dirty, validating, saving, validationFailure, saveFailure, conflict, forbidden }

Widget _editor(BuildContext context) {
  final scenario = context.knobs.object.dropdown(
    label: 'Editor · State',
    options: _EditorScenario.values,
    initialOption: _EditorScenario.dirty,
    labelBuilder: (value) => value.name,
  );
  final state = switch (scenario) {
    _EditorScenario.ready => const CarpenterEditorReady(dirty: false),
    _EditorScenario.dirty => const CarpenterEditorReady(dirty: true),
    _EditorScenario.validating => const CarpenterEditorValidating(),
    _EditorScenario.saving => const CarpenterEditorSaving(),
    _EditorScenario.validationFailure => const CarpenterEditorValidationFailure({CarpenterFieldId('name'): 'Name is required', CarpenterFieldId('inn'): 'INN must contain 10 digits'}),
    _EditorScenario.saveFailure => CarpenterEditorSaveFailure(StateError('Backend rejected the update')),
    _EditorScenario.conflict => const CarpenterEditorConflict(message: 'This record was changed in another session.'),
    _EditorScenario.forbidden => const CarpenterEditorForbidden(),
  };
  return SizedBox(
    width: 900,
    height: 620,
    child: CarpenterEditorPage<void>(
      descriptor: const CarpenterPageDescriptor(id: CarpenterPageId('counterparty.editor'), title: 'Edit counterparty', kind: CarpenterPageKind.editor),
      editorState: state,
      sections: [
        CarpenterPageSection(
          id: const CarpenterPageSectionId('main'),
          title: 'Main information',
          child: _DemoEditorFields(),
        ),
      ],
    ),
  );
}

final class _DemoEditorFields extends StatefulWidget {
  @override
  State<_DemoEditorFields> createState() => _DemoEditorFieldsState();
}

final class _DemoEditorFieldsState extends State<_DemoEditorFields> {
  final TextEditingController _name = TextEditingController(text: 'Albizia LLC');
  final TextEditingController _inn = TextEditingController(text: '7712345678');
  @override
  void dispose() { _name.dispose(); _inn.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => CarpenterFieldGroup(columns: 2, children: [
    CarpenterInput(controller: _name, label: 'Name', required: true),
    CarpenterInput(controller: _inn, label: 'INN', required: true),
  ]);
}

final class _WorkflowPreview extends StatefulWidget {
  const _WorkflowPreview();
  @override
  State<_WorkflowPreview> createState() => _WorkflowPreviewState();
}

final class _WorkflowPreviewState extends State<_WorkflowPreview> {
  late final CarpenterWorkflowControllerBase<int, Map<String, Object?>> _controller = CarpenterWorkflowControllerBase<int, Map<String, Object?>>(
    initialState: 0,
    context: <String, Object?>{},
    transitions: (state, context) => switch (state) {
      0 => [
          CarpenterWorkflowTransition<int, Map<String, Object?>>(
            id: const CarpenterWorkflowTransitionId('continue'),
            title: 'Continue',
            canExecute: (_, _) => true,
            execute: (_) async => Future<void>.delayed(const Duration(milliseconds: 500)),
          ),
        ],
      1 => [
          CarpenterWorkflowTransition<int, Map<String, Object?>>(
            id: const CarpenterWorkflowTransitionId('reject'),
            title: 'Reject',
            canExecute: (_, _) => true,
            execute: (_) async => Future<void>.delayed(const Duration(milliseconds: 450)),
          ),
          CarpenterWorkflowTransition<int, Map<String, Object?>>(
            id: const CarpenterWorkflowTransitionId('approve'),
            title: 'Approve',
            canExecute: (_, _) => true,
            execute: (_) async => Future<void>.delayed(const Duration(milliseconds: 700)),
          ),
        ],
      _ => const [],
    },
    reduce: (state, transition) => state + 1,
  );

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 900,
    height: 620,
    child: CarpenterWorkflowPage<int, Map<String, Object?>>(
      descriptor: const CarpenterPageDescriptor(id: CarpenterPageId('approval.workflow'), title: 'Payment approval', kind: CarpenterPageKind.workflow),
      controller: _controller,
      progress: CarpenterProgress(value: (_controller.state + 1) / 3),
      stages: [
        CarpenterFormWorkflowStage<int, Map<String, Object?>>(
          id: 'review',
          title: 'Review payment',
          description: 'Check the amount and payment purpose before continuing.',
          when: (state, _) => state == 0,
          fields: (_, _) => const [
            CarpenterRecordMetric(label: 'Amount', value: CarpenterText.title('125,000.40 ₽')),
            CarpenterRecordMetric(label: 'Purpose', value: CarpenterText.body('Payment under contract CTR-22')),
          ],
        ),
        CarpenterSelectionWorkflowStage<int, Map<String, Object?>, String>(
          id: 'decision',
          title: 'Choose decision',
          when: (state, _) => state == 1,
          items: (_, _) => const ['Approve without comment', 'Request clarification'],
          identity: (item) => item,
          selectedIdentity: (_, context) => context['decision'],
          onSelected: (item) => setState(() => _controller.context['decision'] = item),
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
          block: (_, _, _) => const CarpenterNotice(title: 'Workflow complete', message: 'No transitions remain.', tone: CarpenterNoticeTone.success),
        ),
      ],
    ),
  );
}

Widget _explorer(BuildContext context) => SizedBox(width: 980, height: 620, child: _explorerPage());
Widget _explorerNarrow(BuildContext context) => SizedBox(width: 420, height: 620, child: _explorerPage());

Widget _explorerPage() => CarpenterExplorerPage(
  descriptor: const CarpenterPageDescriptor(id: CarpenterPageId('files.explorer'), title: 'Files', kind: CarpenterPageKind.explorer),
  search: const CarpenterText.caption('Search area'),
  navigation: const CarpenterCard(child: CarpenterInspector(value: {'folders': ['Contracts', 'Invoices', 'Acts']})),
  compactNavigation: const CarpenterCard(child: CarpenterText.body('Current: Contracts')),
  content: const CarpenterCard(child: CarpenterInspector(value: {'files': ['CTR-22.pdf', 'INV-440.pdf', 'ACT-18.pdf']})),
  inspector: const SizedBox(width: 240, child: CarpenterCard(child: CarpenterInspector(value: {'name': 'CTR-22.pdf', 'size': '2.4 MB', 'owner': 'NC'}))),
);
