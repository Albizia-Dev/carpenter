import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/layout_viewport.dart';

final pageHeaderComponent = WidgetbookComponent(
  name: 'Page Header',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _pageHeaderPlayground),
    WidgetbookUseCase(name: 'Content stress', builder: _pageHeaderStress),
  ],
);

final headerActionsComponent = WidgetbookComponent(
  name: 'Header Actions',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _actionsPlayground)],
);

Widget _pageHeaderPlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Payment order №1542',
  );
  final subtitle = context.knobs.stringOrNull(
    label: 'Content · Subtitle',
    initialValue: 'Supplier payment awaiting approval',
    defaultToNull: false,
  );
  final showStatus = context.knobs.boolean(
    label: 'Content · Status',
    initialValue: true,
  );
  final primaryCount = context.knobs.int.slider(
    label: 'Actions · Primary',
    initialValue: 1,
    min: 0,
    max: 3,
  );
  final secondaryCount = context.knobs.int.slider(
    label: 'Actions · Secondary',
    initialValue: 2,
    min: 0,
    max: 6,
  );
  return layoutViewportPreview(
    context,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: CarpenterPageHeader(
        title: title,
        subtitle: subtitle,
        status: showStatus
            ? const CarpenterPageStatus(
                label: 'In review',
                role: FeedbackColorRole.info,
              )
            : null,
        breadcrumbs: const CarpenterText.caption('Treasury / Payments'),
        primaryActions: [
          for (var index = 0; index < primaryCount; index++)
            _action('primary-$index', index == 0 ? 'Approve' : 'Primary ${index + 1}'),
        ],
        secondaryActions: [
          for (var index = 0; index < secondaryCount; index++)
            _action('secondary-$index', 'Action ${index + 1}'),
        ],
      ),
    ),
  );
}

Widget _pageHeaderStress(BuildContext context) => layoutViewportPreview(
  context,
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: CarpenterPageHeader(
      title: 'Very long structured document title that must remain usable in a narrow operational workspace',
      subtitle:
          'A deliberately verbose subtitle with contextual metadata, ownership information and a description long enough to exercise wrapping.',
      status: const CarpenterPageStatus(
        label: 'Requires immediate attention',
        role: FeedbackColorRole.warning,
      ),
      breadcrumbs: const CarpenterText.caption(
        'Organization / Treasury / Payments / August / Incoming',
      ),
      primaryActions: [_action('approve', 'Approve payment')],
      secondaryActions: [
        _action('edit', 'Edit requisites'),
        _action('copy', 'Copy link'),
        _action('history', 'Open history'),
        _action('export', 'Export document'),
      ],
    ),
  ),
);

Widget _actionsPlayground(BuildContext context) {
  final phase = context.knobs.object.segmented(
    label: 'Primary · Execution',
    options: ActionExecutionPhase.values,
    labelBuilder: semanticValueLabel,
  );
  final secondaryCount = context.knobs.int.slider(
    label: 'Secondary · Count',
    initialValue: 3,
    min: 0,
    max: 8,
  );
  final destructiveCount = context.knobs.int.slider(
    label: 'Destructive · Count',
    initialValue: 1,
    min: 0,
    max: 3,
  );
  return layoutViewportPreview(
    context,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: CarpenterHeaderActions(
        primary: [_action('save', 'Save')],
        secondary: [
          for (var index = 0; index < secondaryCount; index++)
            _action('secondary-$index', 'Action ${index + 1}'),
        ],
        destructive: [
          for (var index = 0; index < destructiveCount; index++)
            CarpenterActionDescriptor(
              id: 'destructive-$index',
              label: index == 0 ? 'Delete' : 'Danger ${index + 1}',
              colorRole: ActionColorRole.danger,
              onInvoke: () {},
            ),
        ],
        primaryExecutionPhase: phase,
      ),
    ),
  );
}

CarpenterActionDescriptor _action(String id, String label) =>
    CarpenterActionDescriptor(id: id, label: label, onInvoke: () {});
