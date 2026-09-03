import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/card.dart';
import '../basic/text.dart';

typedef CarpenterInspectorLabelBuilder = String Function(String key);
typedef CarpenterInspectorScalarBuilder = String Function(Object? value);
typedef CarpenterInspectorFieldFilter = bool Function(
  String key,
  Object? value,
);

/// Recursive readable presentation for map/list payloads and diagnostic data.
final class CarpenterInspector extends StatelessWidget {
  const CarpenterInspector({
    super.key,
    required this.value,
    this.labelBuilder,
    this.scalarBuilder,
    this.fieldFilter,
    this.emptyMessage = 'No data',
  });

  final Object? value;
  final CarpenterInspectorLabelBuilder? labelBuilder;
  final CarpenterInspectorScalarBuilder? scalarBuilder;
  final CarpenterInspectorFieldFilter? fieldFilter;
  final String emptyMessage;

  String _label(String key) => labelBuilder?.call(key) ?? key;
  String _scalar(Object? value) =>
      scalarBuilder?.call(value) ?? value?.toString() ?? '—';

  @override
  Widget build(BuildContext context) => _InspectorValue(
    value: value,
    label: _label,
    scalar: _scalar,
    fieldFilter: fieldFilter,
    emptyMessage: emptyMessage,
  );
}

final class _InspectorValue extends StatelessWidget {
  const _InspectorValue({
    required this.value,
    required this.label,
    required this.scalar,
    required this.fieldFilter,
    required this.emptyMessage,
  });
  final Object? value;
  final String Function(String key) label;
  final String Function(Object? value) scalar;
  final CarpenterInspectorFieldFilter? fieldFilter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final entries = (value as Map).entries
          .where((entry) {
            final key = '${entry.key}';
            return fieldFilter?.call(key, entry.value) ??
                (entry.value != null && '${entry.value}'.isNotEmpty);
          })
          .toList(growable: false);
      if (entries.isEmpty) return CarpenterText.body(emptyMessage);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in entries)
            _InspectorField(
              label: label('${entry.key}'),
              value: entry.value is Map || entry.value is List
                  ? CarpenterInspector(
                      value: entry.value,
                      labelBuilder: label,
                      scalarBuilder: scalar,
                      fieldFilter: fieldFilter,
                      emptyMessage: emptyMessage,
                    )
                  : CarpenterText.body(scalar(entry.value)),
            ),
        ],
      );
    }
    if (value is List) {
      final items = value as List;
      if (items.isEmpty) return CarpenterText.body(emptyMessage);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: context.units(.5.rem)),
              child: CarpenterCard(
                child: CarpenterInspector(
                  value: item,
                  labelBuilder: label,
                  scalarBuilder: scalar,
                  fieldFilter: fieldFilter,
                  emptyMessage: emptyMessage,
                ),
              ),
            ),
        ],
      );
    }
    return CarpenterText.body(scalar(value));
  }
}

final class _InspectorField extends StatelessWidget {
  const _InspectorField({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidget = CarpenterText.label(
            label,
            emphasis: TypographyEmphasis.strong,
            colorRole: ContentColorRole.secondary,
          );
          if (constraints.maxWidth < context.units(26.25.rem))
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelWidget,
                SizedBox(height: gap / 2),
                value,
              ],
            );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: context.units(13.125.rem), child: labelWidget),
              SizedBox(width: gap),
              Expanded(child: value),
            ],
          );
        },
      ),
    );
  }
}
