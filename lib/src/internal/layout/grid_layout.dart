import 'dart:math' as math;

/// Internal geometry contract shared by tabular Carpenter collections.
///
/// Public table and tree-table APIs translate their semantic width contracts
/// into these resolved pixel values. The resolver owns only geometry; it does
/// not know about table actions, selection, tree structure, or theme tokens.
final class GridColumnSpec {
  const GridColumnSpec({
    required this.id,
    required this.preferred,
    required this.minimum,
    required this.maximum,
    this.flex = 0,
    this.flexible = false,
    this.pinned = false,
  }) : assert(minimum >= 0),
       assert(maximum >= minimum),
       assert(flex >= 0);

  final String id;
  final double preferred;
  final double minimum;
  final double maximum;
  final int flex;
  final bool flexible;
  final bool pinned;
}

final class GridLayout {
  const GridLayout({
    required this.widths,
    required this.minimums,
    required this.maximums,
    required this.totalWidth,
  });

  final Map<String, double> widths;
  final Map<String, double> minimums;
  final Map<String, double> maximums;
  final double totalWidth;
}

final class GridLayoutResolver {
  const GridLayoutResolver._();

  static GridLayout resolve({
    required List<GridColumnSpec> columns,
    required double viewportWidth,
    double fixedExtent = 0,
    double outerInset = 0,
    double gap = 0,
    int additionalCells = 0,
  }) {
    assert(fixedExtent >= 0);
    assert(outerInset >= 0);
    assert(gap >= 0);
    assert(additionalCells >= 0);

    final widths = <String, double>{};
    final minimums = <String, double>{};
    final maximums = <String, double>{};
    var preferredTotal = fixedExtent;
    var totalFlex = 0;

    for (final column in columns) {
      final preferred = column.preferred
          .clamp(column.minimum, column.maximum)
          .toDouble();
      widths[column.id] = preferred;
      minimums[column.id] = column.minimum;
      maximums[column.id] = column.maximum;
      preferredTotal += preferred;
      if (column.flexible && !column.pinned) totalFlex += column.flex;
    }

    final cellCount = columns.length + additionalCells;
    final totalGap = math.max(0, cellCount - 1) * gap;
    final chrome = outerInset * 2 + totalGap;
    final availableInner = viewportWidth.isFinite
        ? math.max(0.0, viewportWidth - chrome)
        : double.infinity;

    if (availableInner.isFinite &&
        preferredTotal < availableInner &&
        totalFlex > 0) {
      var remaining = availableInner - preferredTotal;
      var active = columns
          .where(
            (column) =>
                column.flexible &&
                !column.pinned &&
                column.flex > 0 &&
                widths[column.id]! < column.maximum,
          )
          .toList(growable: false);

      // Re-distribute unused flex share when one column reaches its maximum.
      // Without this pass a capped column can leave visible space unused even
      // though another flexible column is still able to grow.
      while (remaining > 0.0001 && active.isNotEmpty) {
        final activeFlex = active.fold<int>(0, (sum, column) => sum + column.flex);
        var consumed = 0.0;
        for (final column in active) {
          final share = remaining * column.flex / activeFlex;
          final current = widths[column.id]!;
          final next = math.min(column.maximum, current + share);
          widths[column.id] = next;
          consumed += next - current;
        }
        if (consumed <= 0.0001) break;
        remaining -= consumed;
        active = active
            .where((column) => widths[column.id]! < column.maximum - 0.0001)
            .toList(growable: false);
      }
    }

    final innerWidth =
        fixedExtent + widths.values.fold<double>(0, (sum, width) => sum + width);
    final naturalWidth = innerWidth + chrome;
    return GridLayout(
      widths: Map.unmodifiable(widths),
      minimums: Map.unmodifiable(minimums),
      maximums: Map.unmodifiable(maximums),
      totalWidth: viewportWidth.isFinite
          ? math.max(viewportWidth, naturalWidth)
          : naturalWidth,
    );
  }
}
