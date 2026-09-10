import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';
import 'pages.dart';
import 'specs.dart';

final treasuryComponents = [
  for (final spec in treasurySpecs)
    WidgetbookComponent(
      name: '${spec.id} · ${spec.title}',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) => layoutViewportPreview(
            context,
            child: TreasuryPagePreview(
              pageId: spec.id,
              visualState: context.knobs.object.dropdown(
                label: 'Состояние',
                options: TreasuryVisualState.values,
                labelBuilder: (v) => v.name,
              ),
            ),
          ),
        ),
        for (final (i, tab) in spec.tabs.indexed)
          WidgetbookUseCase(
            name: 'Scenario · $tab',
            builder: (context) => layoutViewportPreview(
              context,
              child: TreasuryPagePreview(pageId: spec.id, initialTab: i),
            ),
          ),
      ],
    ),
];
