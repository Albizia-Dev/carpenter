import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';
import 'pages.dart';
import 'specs.dart';

final projectsPlusComponents = [
  for (final spec in projectsPlusSpecs)
    WidgetbookComponent(
      name: 'Projects+ · ${spec.title}',
      useCases: [
        WidgetbookUseCase(
          name: 'Playground',
          builder: (context) => layoutViewportPreview(
            context,
            child: ProjectsPlusPreview(
              pageId: spec.id,
              visualState: context.knobs.object.dropdown(
                label: 'Состояние',
                options: ProjectsPlusState.values,
                labelBuilder: (state) => state.name,
              ),
            ),
          ),
        ),
      ],
    ),
];
