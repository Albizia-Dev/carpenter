import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';
import '../../basic/status_indicator.dart';

enum CarpenterTableColumnAlignment { start, center, end }

enum CarpenterTableColumnWidthPolicy { fixed, flexible }

@immutable
final class CarpenterTableColumnWidth {
  const CarpenterTableColumnWidth.flexible({
    this.flex = 1,
    this.preferred,
    this.minimum,
    this.maximum,
  }) : policy = CarpenterTableColumnWidthPolicy.flexible,
       assert(flex > 0);

  const CarpenterTableColumnWidth.fixed({
    required LengthUnit width,
    this.minimum,
    this.maximum,
  }) : policy = CarpenterTableColumnWidthPolicy.fixed,
       preferred = width,
       flex = 0;

  final CarpenterTableColumnWidthPolicy policy;
  final int flex;
  final LengthUnit? preferred;
  final LengthUnit? minimum;
  final LengthUnit? maximum;
}

typedef CarpenterTableCellBuilder<T> =
    Widget Function(BuildContext context, T item);

@immutable
final class CarpenterTableColumn<T> {
  const CarpenterTableColumn.custom({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.alignment = CarpenterTableColumnAlignment.start,
    this.width = const CarpenterTableColumnWidth.flexible(),
    this.sortable = false,
    this.resizable = true,
    this.semanticLabel,
  });

  factory CarpenterTableColumn.text({
    required String id,
    required String header,
    required String Function(T item) value,
    CarpenterTableColumnAlignment alignment =
        CarpenterTableColumnAlignment.start,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) =>
        _TableText(value(item), maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  factory CarpenterTableColumn.number({
    required String id,
    required String header,
    required num? Function(T item) value,
    String Function(num value)? formatter,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: CarpenterTableColumnAlignment.end,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) {
      final number = value(item);
      return _TableText(
        number == null ? '' : formatter?.call(number) ?? '$number',
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    },
  );

  factory CarpenterTableColumn.status({
    required String id,
    required String header,
    required String Function(T item) label,
    required FeedbackColorRole Function(T item) role,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: CarpenterStatusIndicator(label: label(item), role: role(item)),
    ),
  );

  factory CarpenterTableColumn.actions({
    required String id,
    required String header,
    required List<CarpenterActionDescriptor> Function(T item) actions,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: CarpenterTableColumnAlignment.end,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) => Wrap(
      alignment: WrapAlignment.end,
      children: actions(item)
          .map(
            (action) => CarpenterButton.fromAction(
              action,
              prominence: ActionProminence.ghost,
              size: ControlSize.xsmall,
            ),
          )
          .toList(growable: false),
    ),
  );

  final String id;
  final String header;
  final String? semanticLabel;
  final CarpenterTableCellBuilder<T> cellBuilder;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnWidth width;
  final bool sortable;
  final bool resizable;
}

final class _TableText extends StatelessWidget {
  const _TableText(
    this.data, {
    required this.maxLines,
    required this.overflow,
    this.textAlign,
  });

  final String data;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Text(
      data,
      style: theme.typography
          .tableCell(context, TypographyEmphasis.regular)
          .copyWith(color: theme.content.primary),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
