import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/text.dart';

typedef CarpenterInspectorLabelBuilder = String Function(String key);
typedef CarpenterInspectorScalarBuilder = String Function(Object? value);
typedef CarpenterInspectorFieldFilter =
    bool Function(String key, Object? value);

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
    depth: 0,
  );
}

final class _InspectorValue extends StatelessWidget {
  const _InspectorValue({
    required this.value,
    required this.label,
    required this.scalar,
    required this.fieldFilter,
    required this.emptyMessage,
    required this.depth,
  });

  final Object? value;
  final String Function(String key) label;
  final String Function(Object? value) scalar;
  final CarpenterInspectorFieldFilter? fieldFilter;
  final String emptyMessage;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    if (value is Map) {
      final entries = (value as Map).entries
          .where((entry) {
            final key = '${entry.key}';
            return fieldFilter?.call(key, entry.value) ??
                (entry.value != null && '${entry.value}'.isNotEmpty);
          })
          .toList(growable: false);
      if (entries.isEmpty) {
        return CarpenterText.body(
          emptyMessage,
          colorRole: ContentColorRole.muted,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              SizedBox(
                height: context.units(theme.shapes.actionBorderWidth),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: theme.surface.subtle),
                ),
              ),
            _InspectorField(
              label: label('${entries[index].key}'),
              value: _nested(entries[index].value),
              depth: depth,
            ),
          ],
        ],
      );
    }
    if (value is List) {
      final items = value as List;
      if (items.isEmpty) {
        return CarpenterText.body(
          emptyMessage,
          colorRole: ContentColorRole.muted,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : gap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: context.units(2.rem),
                    child: CarpenterText.caption(
                      '${index + 1}.',
                      colorRole: ContentColorRole.muted,
                    ),
                  ),
                  Expanded(child: _nested(items[index])),
                ],
              ),
            ),
        ],
      );
    }
    return CarpenterText.body(scalar(value));
  }

  Widget _nested(Object? nestedValue) {
    if (nestedValue is! Map && nestedValue is! List) {
      return CarpenterText.body(scalar(nestedValue));
    }
    return _InspectorValue(
      value: nestedValue,
      label: label,
      scalar: scalar,
      fieldFilter: fieldFilter,
      emptyMessage: emptyMessage,
      depth: depth + 1,
    );
  }
}

final class _InspectorField extends StatelessWidget {
  const _InspectorField({
    required this.label,
    required this.value,
    required this.depth,
  });

  final String label;
  final Widget value;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final vertical = context.units(theme.spacing.small) / 2;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: depth == 0 ? 0 : gap,
        top: vertical,
        bottom: vertical,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidget = CarpenterText.label(
            label,
            emphasis: TypographyEmphasis.medium,
            colorRole: ContentColorRole.secondary,
          );
          if (constraints.maxWidth < context.units(32.rem)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelWidget,
                SizedBox(height: gap / 2),
                value,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: context.units(10.rem), child: labelWidget),
              SizedBox(width: gap),
              Expanded(child: value),
            ],
          );
        },
      ),
    );
  }
}
