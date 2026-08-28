import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

const _weights = <int>[0, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950, 1000];

final foundationColorsComponent = WidgetbookComponent(
  name: 'Colors',
  useCases: [
    WidgetbookUseCase(name: 'Palettes', builder: _palettes),
    WidgetbookUseCase(name: 'Semantic tokens', builder: _semanticTokens),
    WidgetbookUseCase(name: 'Action matrix', builder: _actionMatrix),
    WidgetbookUseCase(name: 'Selection roles', builder: _selectionRoles),
  ],
);

Widget _palettes(BuildContext context) => preview(
  _PaletteCatalog(
    families: [
      _PaletteFamily('neutral', palette.neutral),
      _PaletteFamily('brand', palette.brand),
      _PaletteFamily('secondary', palette.secondary),
      _PaletteFamily('success', palette.success),
      _PaletteFamily('warning', palette.warning),
      _PaletteFamily('danger', palette.danger),
      _PaletteFamily('info', palette.info),
      _PaletteFamily('utility', palette.utility),
    ],
  ),
);

Widget _semanticTokens(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final theme = CarpenterTheme.of(context);
      return _Catalog(
        sections: [
          _ColorSection(
            title: 'surface.* / overlay.*',
            colors: [
              _NamedColor('surface.base', theme.surface.base, theme.content.primary),
              _NamedColor('surface.subtle', theme.surface.subtle, theme.content.primary),
              _NamedColor('overlay.background', theme.overlay.background, theme.overlay.foreground),
              _NamedColor('overlay.foreground', theme.overlay.foreground, theme.surface.base),
              _NamedColor('overlay.supporting', theme.overlay.supporting, theme.overlay.background),
              _NamedColor('overlay.border', theme.overlay.border, theme.surface.base),
              _NamedColor('overlay.hovered', theme.overlay.hovered, theme.overlay.foreground),
              _NamedColor('overlay.selected', theme.overlay.selected, theme.overlay.foreground),
              _NamedColor('overlay.scrim', theme.overlay.scrim, palette.white),
              _NamedColor('overlay.tooltip.background', theme.overlay.tooltipBackground, theme.overlay.tooltipForeground),
              _NamedColor('overlay.tooltip.foreground', theme.overlay.tooltipForeground, theme.overlay.tooltipBackground),
            ],
          ),
          _ColorSection(
            title: 'content.*',
            colors: [
              for (final role in ContentColorRole.values)
                _NamedColor(
                  'content.${role.name}',
                  theme.content.resolve(role),
                  theme.surface.base,
                ),
            ],
          ),
          _ColorSection(
            title: 'field.*',
            colors: [
              _NamedColor('field.background', theme.fields.background, theme.fields.foreground),
              _NamedColor('field.backgroundHovered', theme.fields.backgroundHovered, theme.fields.foreground),
              _NamedColor('field.backgroundDisabled', theme.fields.backgroundDisabled, theme.fields.disabledForeground),
              _NamedColor('field.foreground', theme.fields.foreground, theme.fields.background),
              _NamedColor('field.placeholder', theme.fields.placeholder, theme.fields.background),
              _NamedColor('field.border', theme.fields.border, theme.surface.base),
              _NamedColor('field.borderHovered', theme.fields.borderHovered, theme.surface.base),
              _NamedColor('field.borderFocused', theme.fields.borderFocused, theme.surface.base),
              _NamedColor('field.borderError', theme.fields.borderError, theme.surface.base),
              _NamedColor('field.error', theme.fields.error, theme.surface.base),
              _NamedColor('field.selection', theme.fields.selection, theme.fields.foreground),
            ],
          ),
          for (final role in ActionColorRole.values)
            _ColorSection(
              title: 'action.${role.name}.*',
              colors: _actionTokenColors(theme, role),
            ),
          _ColorSection(
            title: 'feedback.*',
            colors: [
              for (final role in FeedbackColorRole.values) ...[
                _NamedColor(
                  'feedback.${role.name}.background',
                  theme.feedback.resolve(role).background,
                  theme.feedback.resolve(role).foreground,
                ),
                _NamedColor(
                  'feedback.${role.name}.foreground',
                  theme.feedback.resolve(role).foreground,
                  theme.feedback.resolve(role).background,
                ),
                _NamedColor(
                  'feedback.${role.name}.border',
                  theme.feedback.resolve(role).border,
                  theme.surface.base,
                ),
              ],
            ],
          ),
          _ColorSection(
            title: 'focus / disabled',
            colors: [
              _NamedColor('focus.color', theme.focus.color, theme.surface.base),
              _NamedColor('action.disabledBackground', theme.actions.disabledBackground, theme.actions.disabledForeground),
              _NamedColor('action.disabledForeground', theme.actions.disabledForeground, theme.surface.base),
              _NamedColor('content.disabled', theme.content.disabled, theme.surface.base),
            ],
          ),
        ],
      );
    },
  ),
);

List<_NamedColor> _actionTokenColors(
  CarpenterThemeData theme,
  ActionColorRole role,
) {
  final rolePalette = switch (role) {
    ActionColorRole.neutral => theme.actions.neutral,
    ActionColorRole.primary => theme.actions.primary,
    ActionColorRole.utility => theme.actions.utility,
    ActionColorRole.danger => theme.actions.danger,
    ActionColorRole.warning => theme.actions.warning,
    ActionColorRole.success => theme.actions.success,
    ActionColorRole.info => theme.actions.info,
  };
  return [
    _NamedColor('action.${role.name}.normal', rolePalette.normal, theme.surface.base),
    _NamedColor('action.${role.name}.hovered', rolePalette.hovered, theme.surface.base),
    _NamedColor('action.${role.name}.pressed', rolePalette.pressed, theme.surface.base),
    _NamedColor('action.${role.name}.state', rolePalette.state, rolePalette.normal),
    _NamedColor('action.${role.name}.strongState', rolePalette.strongState, rolePalette.normal),
  ];
}

Widget _actionMatrix(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarpenterText.title('Action role × prominence'),
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
                    onPressed: _noop,
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

final class _PaletteFamily {
  const _PaletteFamily(this.name, this.values);

  final String name;
  final dynamic values;
}

final class _PaletteCatalog extends StatelessWidget {
  const _PaletteCatalog({required this.families});

  final List<_PaletteFamily> families;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.large);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final family in families) ...[
          CarpenterText.title(family.name),
          SizedBox(height: gap / 2),
          Wrap(
            spacing: gap / 2,
            runSpacing: gap / 2,
            children: [
              for (final weight in _weights)
                _ColorSwatch(
                  color: _NamedColor(
                    '${family.name}[$weight]',
                    family.values[weight] as Color,
                    _contrastFor(family.values[weight] as Color),
                  ),
                  compact: true,
                ),
            ],
          ),
          SizedBox(height: gap),
        ],
      ],
    );
  }
}

Color _contrastFor(Color color) =>
    color.computeLuminance() > .45 ? palette.black : palette.white;

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
  const _ColorSwatch({required this.color, this.compact = false});

  final _NamedColor color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inset = context.units(theme.spacing.small);
    final width = context.units(compact ? const Rem(7.5) : const Rem(11));
    final height = context.units(compact ? const Rem(4.25) : const Rem(5.5));
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography
                      .resolve(
                        context,
                        TypographyRole.caption,
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
