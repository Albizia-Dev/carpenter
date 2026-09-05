import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../basic/status_indicator.dart';
import 'table_actions.dart';
import 'table_text.dart';

enum CarpenterTableColumnAlignment { start, center, end }

enum CarpenterTableColumnVerticalAlignment { top, center, bottom }

enum CarpenterTableColumnWidthPolicy { fixed, flexible, actionLane }

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

  /// Compact non-flexing lane for semantic row actions.
  ///
  /// When [preferred] is omitted, the table resolves the extent from its action
  /// control size, gaps, and cell padding instead of coupling layout to a
  /// concrete action-cell widget.
  const CarpenterTableColumnWidth.actionLane({
    this.preferred,
    this.minimum,
    this.maximum,
  }) : policy = CarpenterTableColumnWidthPolicy.actionLane,
       flex = 0;

  final CarpenterTableColumnWidthPolicy policy;
  final int flex;
  final LengthUnit? preferred;
  final LengthUnit? minimum;
  final LengthUnit? maximum;

  bool get isFlexible => policy == CarpenterTableColumnWidthPolicy.flexible;
}

typedef CarpenterTableCellBuilder<T> = Widget Function(
  BuildContext context,
  T item,
);

@immutable
final class CarpenterTableColumn<T> {
  const CarpenterTableColumn.custom({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.alignment = CarpenterTableColumnAlignment.start,
    this.verticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.width = const CarpenterTableColumnWidth.flexible(),
    this.sortable = false,
    this.resizable = true,
    this.semanticLabel,
    @Deprecated(
      'Use width: CarpenterTableColumnWidth.actionLane(). '
      'isActionColumn is retained for source compatibility.',
    )
    bool isActionColumn = false,
  }) : _legacyIsActionColumn = isActionColumn;

  factory CarpenterTableColumn.text({
    required String id,
    required String header,
    required String Function(T item) value,
    CarpenterTableColumnAlignment alignment =
        CarpenterTableColumnAlignment.start,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) => CarpenterTableText.cell(
      value(item),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );

  factory CarpenterTableColumn.number({
    required String id,
    required String header,
    required num? Function(T item) value,
    String Function(num value)? formatter,
    CarpenterTableColumnAlignment alignment = CarpenterTableColumnAlignment.end,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) {
      final number = value(item);
      return CarpenterTableText.cell(
        number == null ? '' : formatter?.call(number) ?? '$number',
        textAlign: switch (alignment) {
          CarpenterTableColumnAlignment.start => TextAlign.start,
          CarpenterTableColumnAlignment.center => TextAlign.center,
          CarpenterTableColumnAlignment.end => TextAlign.end,
        },
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
    CarpenterTableColumnAlignment alignment =
        CarpenterTableColumnAlignment.start,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool sortable = false,
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    sortable: sortable,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, item) =>
        CarpenterStatusIndicator(label: label(item), role: role(item)),
  );

  /// Creates a compact, geometry-stable action column.
  ///
  /// [actions] are primary actions. Up to two icon-bearing actions stay inline;
  /// remaining primary actions and every [secondaryActions] entry live under
  /// overflow. The default [width] is a semantic action lane and therefore does
  /// not participate in flexible data-column growth.
  factory CarpenterTableColumn.actions({
    required String id,
    required String header,
    required List<CarpenterActionDescriptor> Function(T item) actions,
    List<CarpenterActionDescriptor> Function(T item)? secondaryActions,
    CarpenterTableColumnAlignment alignment = CarpenterTableColumnAlignment.end,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.actionLane(),
    bool resizable = false,
    String? semanticLabel,
    String overflowLabel = 'More actions',
  }) => CarpenterTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    isActionColumn: true,
    cellBuilder: (context, item) => CarpenterTableActionCell(
      primary: actions(item),
      secondary: secondaryActions?.call(item) ?? const [],
      overflowLabel: overflowLabel,
      semanticLabel: semanticLabel ?? header,
    ),
  );

  final String id;
  final String header;
  final String? semanticLabel;
  final CarpenterTableCellBuilder<T> cellBuilder;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final CarpenterTableColumnWidth width;
  final bool sortable;
  final bool resizable;
  final bool _legacyIsActionColumn;

  @Deprecated(
    'Use width: CarpenterTableColumnWidth.actionLane(). '
    'isActionColumn is retained for source compatibility.',
  )
  bool get isActionColumn =>
      _legacyIsActionColumn ||
      width.policy == CarpenterTableColumnWidthPolicy.actionLane;

  /// Resolves the legacy action-column marker into the semantic width contract.
  CarpenterTableColumnWidth get effectiveWidth {
    if (!isActionColumn ||
        width.policy == CarpenterTableColumnWidthPolicy.fixed ||
        width.policy == CarpenterTableColumnWidthPolicy.actionLane) {
      return width;
    }
    return CarpenterTableColumnWidth.actionLane(
      preferred: width.preferred,
      minimum: width.minimum,
      maximum: width.maximum,
    );
  }
}

AlignmentDirectional carpenterTableCellAlignment(
  CarpenterTableColumnAlignment horizontal,
  CarpenterTableColumnVerticalAlignment vertical,
) => AlignmentDirectional(
  switch (horizontal) {
    CarpenterTableColumnAlignment.start => -1,
    CarpenterTableColumnAlignment.center => 0,
    CarpenterTableColumnAlignment.end => 1,
  },
  switch (vertical) {
    CarpenterTableColumnVerticalAlignment.top => -1,
    CarpenterTableColumnVerticalAlignment.center => 0,
    CarpenterTableColumnVerticalAlignment.bottom => 1,
  },
);
