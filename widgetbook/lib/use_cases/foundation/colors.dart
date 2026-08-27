import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final foundationColorsComponent = WidgetbookComponent(
  name: 'Colors',
  useCases: [
    WidgetbookUseCase(name: 'Semantic colors', builder: _semanticColors),
    WidgetbookUseCase(name: 'Action matrix', builder: _actionMatrix),
    WidgetbookUseCase(name: 'Selection roles', builder: _selectionRoles),
  ],
);

Widget _semanticColors(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final theme = CarpenterTheme.of(context);
      return _Catalog(
        sections: [
          _ColorSection(
            title: 'Layout surfaces',
            colors: [
              _NamedColor('Base', theme.surface.base, theme.content.primary),
              _NamedColor(
                'Subtle',
                theme.surface.subtle,
                theme.content.primary,
              ),
              _NamedColor(
                'Overlay',
                theme.overlay.background,
                theme.overlay.foreground,
              ),
              _NamedColor(
                'Overlay selected',
                theme.overlay.selected,
                theme.overlay.foreground,
              ),
              _NamedColor(
                'Tooltip',
                theme.overlay.tooltipBackground,
                theme.overlay.tooltipForeground,
              ),
            ],
          ),
          _ColorSection(
            title: 'Content',
            colors: [
              for (final role in ContentColorRole.values)
                _NamedColor(
                  semanticValueLabel(role),
                  theme.content.resolve(role),
                  theme.surface.base,
                ),
            ],
          ),
          _ColorSection(
            title: 'Feedback pairs',
            colors: [
              for (final role in FeedbackColorRole.values)
                _NamedColor(
                  semanticValueLabel(role),
                  theme.feedback.resolve(role).background,
                  theme.feedback.resolve(role).foreground,
                ),
            ],
          ),
          _ColorSection(
            title: 'Focus and borders',
            colors: [
              _NamedColor('Focus', theme.focus.color, theme.surface.base),
              _NamedColor(
                'Overlay border',
                theme.overlay.border,
                theme.surface.base,
              ),
              _NamedColor(
                'Field border',
                theme.fields.border,
                theme.surface.base,
              ),
              _NamedColor(
                'Field error',
                theme.fields.error,
                theme.surface.base,
              ),
            ],
          ),
        ],
      );
    },
  ),
);

Widget _actionMatrix(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.title('Action role × prominence'),
          SizedBox(height: gap),
          for (final role in ActionColorRole.values) ...[
            CarpenterText.label(semanticValueLabel(role)),
            SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final prominence in ActionProminence.values)
                  CarpenterButton(
                    label: semanticValueLabel(prominence),
                    colorRole: role,
                    prominence: prominence,
                    onInvoke: _noop,
                  ),
              ],
            ),
            SizedBox(height: gap),
          ],
        ],
      );
    },
  ),
);

Widget _selectionRoles(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final role in SelectionColorRole.values)
            CarpenterCheckbox(
              value: CheckboxValue.checked,
              label: semanticValueLabel(role),
              colorRole: role,
              onChanged: (_) {},
            ),
        ],
      );
    },
  ),
);

final class _Catalog extends StatelessWidget {
  const _Catalog({required this.sections});

  final List<_ColorSection> sections;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.large);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          CarpenterText.title(section.title),
          SizedBox(height: gap),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final color in section.colors) _ColorSwatch(color: color),
            ],
          ),
          SizedBox(height: gap),
        ],
      ],
    );
  }
}

final class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final _NamedColor color;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inset = context.units(theme.spacing.medium);
    final width = context.units(const Rem(10));
    final height = context.units(const Rem(5));
    final borderWidth = context.units(theme.shapes.borderWidth);
    return Semantics(
      label: '${color.name}, ${_hex(color.background)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.background,
          border: Border.all(color: theme.overlay.border, width: borderWidth),
          borderRadius: BorderRadius.circular(
            context.units(theme.shapes.radius(ShapeRole.rounded)),
          ),
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  color.name,
                  style: theme.typography
                      .resolve(
                        context,
                        TypographyRole.label,
                        TypographyEmphasis.strong,
                      )
                      .copyWith(color: color.foreground),
                ),
                Text(
                  _hex(color.background),
                  style: theme.typography
                      .resolve(
                        context,
                        TypographyRole.caption,
                        TypographyEmphasis.regular,
                      )
                      .copyWith(color: color.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ColorSection {
  const _ColorSection({required this.title, required this.colors});

  final String title;
  final List<_NamedColor> colors;
}

final class _NamedColor {
  const _NamedColor(this.name, this.background, this.foreground);

  final String name;
  final Color background;
  final Color foreground;
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

void _noop() {}
