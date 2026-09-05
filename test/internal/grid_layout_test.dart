import 'package:carpenter/src/internal/layout/grid_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps pinned columns stable while flexible columns fill the viewport', () {
    final layout = GridLayoutResolver.resolve(
      viewportWidth: 500,
      columns: const [
        GridColumnSpec(
          id: 'pinned',
          preferred: 120,
          minimum: 80,
          maximum: 240,
          flexible: true,
          flex: 1,
          pinned: true,
        ),
        GridColumnSpec(
          id: 'flex',
          preferred: 100,
          minimum: 80,
          maximum: 500,
          flexible: true,
          flex: 1,
        ),
      ],
    );

    expect(layout.widths['pinned'], 120);
    expect(layout.widths['flex'], 380);
    expect(layout.totalWidth, 500);
  });

  test('redistributes flex space when a column reaches its maximum', () {
    final layout = GridLayoutResolver.resolve(
      viewportWidth: 500,
      columns: const [
        GridColumnSpec(
          id: 'capped',
          preferred: 100,
          minimum: 80,
          maximum: 150,
          flexible: true,
          flex: 1,
        ),
        GridColumnSpec(
          id: 'remaining',
          preferred: 100,
          minimum: 80,
          maximum: 500,
          flexible: true,
          flex: 1,
        ),
      ],
    );

    expect(layout.widths['capped'], 150);
    expect(layout.widths['remaining'], 350);
    expect(layout.totalWidth, 500);
  });

  test('includes fixed lanes, gaps, and outer insets in natural width', () {
    final layout = GridLayoutResolver.resolve(
      viewportWidth: 100,
      fixedExtent: 40,
      outerInset: 10,
      gap: 8,
      additionalCells: 1,
      columns: const [
        GridColumnSpec(
          id: 'a',
          preferred: 100,
          minimum: 80,
          maximum: 200,
        ),
        GridColumnSpec(
          id: 'b',
          preferred: 120,
          minimum: 80,
          maximum: 200,
        ),
      ],
    );

    expect(layout.totalWidth, 296);
  });
}
