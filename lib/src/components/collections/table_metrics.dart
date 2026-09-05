import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

/// Resolved pixel geometry shared by table-shaped collection components.
///
/// Theme and density decisions stay in Carpenter theme tokens. This object is
/// only the component boundary that converts those tokens into layout values,
/// so regular tables, tree tables, table-row list tiles, and action lanes do
/// not each reinterpret the same geometry independently.
@immutable
final class CarpenterTableMetrics {
  const CarpenterTableMetrics({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.cellGap,
    required this.stateGap,
    required this.headerHeight,
    required this.rowHeight,
    required this.bodyMaxHeight,
    required this.stateHeight,
    required this.selectionColumnWidth,
    required this.resizeHandleWidth,
    required this.defaultColumnWidth,
    required this.minimumColumnWidth,
    required this.maximumColumnWidth,
    required this.borderWidth,
    required this.surfaceRadius,
  });

  factory CarpenterTableMetrics.resolve(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double scaled(LengthUnit value) => scaler.scale(context.units(value));

    return CarpenterTableMetrics(
      horizontalPadding: context.units(theme.spacing.tableHorizontal),
      verticalPadding: context.units(theme.spacing.tableVertical),
      cellGap: context.units(theme.spacing.tableCellGap),
      stateGap: context.units(theme.spacing.tableStateGap),
      headerHeight: scaled(theme.sizes.tableHeaderHeight),
      rowHeight: scaled(theme.sizes.tableRowHeight),
      bodyMaxHeight: scaled(theme.sizes.tableBodyMaxHeight),
      stateHeight: scaled(theme.sizes.tableStateHeight),
      selectionColumnWidth: context.units(theme.sizes.tableSelectionColumn),
      resizeHandleWidth: context.units(theme.sizes.tableResizeHandle),
      defaultColumnWidth: context.units(theme.sizes.tableColumn),
      minimumColumnWidth: context.units(theme.sizes.tableColumnMin),
      maximumColumnWidth: context.units(theme.sizes.tableColumnMax),
      borderWidth: context.units(theme.shapes.tableBorderWidth),
      surfaceRadius: context.units(theme.shapes.tableSurfaceRadius),
    );
  }

  final double horizontalPadding;
  final double verticalPadding;
  final double cellGap;
  final double stateGap;
  final double headerHeight;
  final double rowHeight;
  final double bodyMaxHeight;
  final double stateHeight;
  final double selectionColumnWidth;
  final double resizeHandleWidth;
  final double defaultColumnWidth;
  final double minimumColumnWidth;
  final double maximumColumnWidth;
  final double borderWidth;
  final double surfaceRadius;
}
