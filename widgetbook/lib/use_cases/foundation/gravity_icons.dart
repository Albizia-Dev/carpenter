import 'package:carpenter/carpenter.dart';
import 'package:carpenter/gravity_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';

final gravityIconsComponent = WidgetbookComponent(
  name: 'Gravity icons',
  useCases: [WidgetbookUseCase(name: 'Catalog', builder: _catalog)],
);

Widget _catalog(BuildContext context) {
  final query = context.knobs.string(
    label: 'Content · Search',
    initialValue: '',
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: IconSize.values,
    initialOption: IconSize.medium,
    labelBuilder: semanticValueLabel,
  );
  final colorRole = context.knobs.object.dropdown(
    label: 'Appearance · Role',
    options: ContentColorRole.values,
    initialOption: ContentColorRole.primary,
    labelBuilder: semanticValueLabel,
  );

  final normalizedQuery = query.trim().toLowerCase();
  final icons = GravityIcons.values
      .where(
        (icon) =>
            normalizedQuery.isEmpty ||
            icon.name.toLowerCase().contains(normalizedQuery),
      )
      .toList(growable: false);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 92,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: CarpenterTheme.of(
                context,
              ).content.resolve(ContentColorRole.muted),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarpenterIcon(icon, size: size, colorRole: colorRole),
                const SizedBox(height: 8),
                CarpenterText.caption(
                  icon.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  colorRole: ContentColorRole.secondary,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
