import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final pageStateComponent = WidgetbookComponent(
  name: 'Page State',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'State matrix', builder: _matrix),
  ],
);

Widget _playground(BuildContext context) {
  final kind = context.knobs.object.segmented(
    label: 'State · Kind',
    options: CarpenterPageStateKind.values,
    labelBuilder: semanticValueLabel,
  );
  final action = context.knobs.boolean(
    label: 'State · Action',
    initialValue: true,
  );
  final longDescription = context.knobs.boolean(
    label: 'Content · Long description',
  );
  return preview(
    SizedBox(
      width: 520,
      height: 320,
      child: CarpenterPageStatePresentation(
        kind: kind,
        title: _title(kind),
        description: longDescription
            ? 'The page cannot show its primary content yet. This deliberately long explanation checks wrapping and centered state composition in constrained layouts.'
            : _description(kind),
        action: action && kind != CarpenterPageStateKind.initialLoading
            ? CarpenterActionDescriptor(
                id: 'state-action',
                label: kind == CarpenterPageStateKind.initialError
                    ? 'Retry'
                    : 'Create record',
                onInvoke: () {},
              )
            : null,
      ),
    ),
  );
}

Widget _matrix(BuildContext context) => previewColumn([
  for (final kind in CarpenterPageStateKind.values)
    SizedBox(
      width: 520,
      height: 220,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: CarpenterTheme.of(context).overlay.border),
        ),
        child: CarpenterPageStatePresentation(
          kind: kind,
          title: _title(kind),
          description: _description(kind),
          action: kind == CarpenterPageStateKind.initialError
              ? CarpenterActionDescriptor(
                  id: 'retry-${kind.name}',
                  label: 'Retry',
                  onInvoke: () {},
                )
              : null,
        ),
      ),
    ),
]);

String _title(CarpenterPageStateKind kind) => switch (kind) {
  CarpenterPageStateKind.initialLoading => 'Loading records',
  CarpenterPageStateKind.zero => 'No records yet',
  CarpenterPageStateKind.emptyResult => 'No matching records',
  CarpenterPageStateKind.initialError => 'Could not load records',
};

String _description(CarpenterPageStateKind kind) => switch (kind) {
  CarpenterPageStateKind.initialLoading => 'The initial request is in progress.',
  CarpenterPageStateKind.zero => 'Create the first record to start working.',
  CarpenterPageStateKind.emptyResult => 'Change or clear the active filters.',
  CarpenterPageStateKind.initialError => 'Check the connection and retry the request.',
};
