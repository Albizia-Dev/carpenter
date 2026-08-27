import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carpenter/src/internal/overlay/anchored_overlay_positioner.dart';

void main() {
  const viewport = Size(400, 300);
  const child = Size(80, 60);
  const centerAnchor = Rect.fromLTWH(180, 130, 40, 40);

  test('every placement positions on its requested side when it fits', () {
    for (final placement in OverlayPlacement.values) {
      final result = AnchoredOverlayPositioner.calculate(
        viewport: viewport,
        anchor: centerAnchor,
        child: child,
        preferred: placement,
        textDirection: TextDirection.ltr,
        gap: 6,
        viewportInset: 8,
      );
      expect(result.placement, placement, reason: placement.name);
      final rect = result.offset & child;
      switch (placement) {
        case OverlayPlacement.top:
        case OverlayPlacement.topStart:
        case OverlayPlacement.topEnd:
          expect(rect.bottom, lessThanOrEqualTo(centerAnchor.top));
        case OverlayPlacement.bottom:
        case OverlayPlacement.bottomStart:
        case OverlayPlacement.bottomEnd:
          expect(rect.top, greaterThanOrEqualTo(centerAnchor.bottom));
        case OverlayPlacement.left:
          expect(rect.right, lessThanOrEqualTo(centerAnchor.left));
        case OverlayPlacement.right:
          expect(rect.left, greaterThanOrEqualTo(centerAnchor.right));
      }
    }
  });

  test('flips and shifts inside viewport edges', () {
    final flipped = AnchoredOverlayPositioner.calculate(
      viewport: viewport,
      anchor: const Rect.fromLTWH(180, 270, 40, 20),
      child: child,
      preferred: OverlayPlacement.bottom,
      textDirection: TextDirection.ltr,
      gap: 6,
      viewportInset: 8,
    );
    expect(flipped.placement, OverlayPlacement.top);

    final shifted = AnchoredOverlayPositioner.calculate(
      viewport: viewport,
      anchor: const Rect.fromLTWH(390, 120, 10, 20),
      child: child,
      preferred: OverlayPlacement.bottomStart,
      fallbacks: const [OverlayPlacement.bottomEnd],
      textDirection: TextDirection.ltr,
      gap: 6,
      viewportInset: 8,
    );
    expect(shifted.offset.dx, inInclusiveRange(8, 312));
  });

  test('logical start mirrors in RTL and moving anchor recalculates', () {
    AnchoredOverlayPosition position(Rect anchor, TextDirection direction) =>
        AnchoredOverlayPositioner.calculate(
          viewport: viewport,
          anchor: anchor,
          child: child,
          preferred: OverlayPlacement.bottomStart,
          textDirection: direction,
          gap: 6,
          viewportInset: 8,
        );

    final ltr = position(centerAnchor, TextDirection.ltr);
    final rtl = position(centerAnchor, TextDirection.rtl);
    expect(ltr.offset.dx, centerAnchor.left);
    expect(rtl.offset.dx, centerAnchor.right - child.width);

    final moved = position(centerAnchor.translate(40, 20), TextDirection.ltr);
    expect(moved.offset, ltr.offset + const Offset(40, 20));
  });

  test('oversized content remains shifted to the safe viewport origin', () {
    final result = AnchoredOverlayPositioner.calculate(
      viewport: const Size(100, 80),
      anchor: const Rect.fromLTWH(0, 0, 10, 10),
      child: const Size(200, 160),
      preferred: OverlayPlacement.top,
      textDirection: TextDirection.ltr,
      gap: 6,
      viewportInset: 8,
    );
    expect(result.offset, const Offset(8, 8));
  });
}
