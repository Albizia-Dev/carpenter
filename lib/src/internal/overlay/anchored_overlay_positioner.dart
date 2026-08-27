import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';

final class AnchoredOverlayPosition {
  const AnchoredOverlayPosition({
    required this.offset,
    required this.placement,
  });

  final Offset offset;
  final OverlayPlacement placement;
}

final class AnchoredOverlayPositioner {
  const AnchoredOverlayPositioner._();

  static AnchoredOverlayPosition calculate({
    required Size viewport,
    required Rect anchor,
    required Size child,
    required OverlayPlacement preferred,
    required TextDirection textDirection,
    required double gap,
    required double viewportInset,
    List<OverlayPlacement> fallbacks = const [],
  }) {
    final safeRect = Rect.fromLTWH(
      viewportInset,
      viewportInset,
      math.max(0, viewport.width - viewportInset * 2),
      math.max(0, viewport.height - viewportInset * 2),
    );
    final candidates = <OverlayPlacement>{
      preferred,
      ...fallbacks,
      ..._defaultFallbacks(preferred),
    }.toList();

    OverlayPlacement chosen = candidates.first;
    var desired = _desiredOffset(
      anchor: anchor,
      child: child,
      placement: chosen,
      textDirection: textDirection,
      gap: gap,
    );
    var bestArea = -1.0;
    for (final candidate in candidates) {
      final candidateOffset = _desiredOffset(
        anchor: anchor,
        child: child,
        placement: candidate,
        textDirection: textDirection,
        gap: gap,
      );
      final candidateRect = candidateOffset & child;
      if (safeRect.contains(candidateRect.topLeft) &&
          safeRect.contains(candidateRect.bottomRight)) {
        chosen = candidate;
        desired = candidateOffset;
        break;
      }
      final visibleArea = candidateRect.intersect(safeRect);
      final area = visibleArea.isEmpty
          ? 0.0
          : visibleArea.width * visibleArea.height;
      if (area > bestArea) {
        bestArea = area;
        chosen = candidate;
        desired = candidateOffset;
      }
    }

    final maxX = math.max(safeRect.left, safeRect.right - child.width);
    final maxY = math.max(safeRect.top, safeRect.bottom - child.height);
    return AnchoredOverlayPosition(
      placement: chosen,
      offset: Offset(
        desired.dx.clamp(safeRect.left, maxX),
        desired.dy.clamp(safeRect.top, maxY),
      ),
    );
  }

  static Offset _desiredOffset({
    required Rect anchor,
    required Size child,
    required OverlayPlacement placement,
    required TextDirection textDirection,
    required double gap,
  }) {
    final startX = textDirection == TextDirection.ltr
        ? anchor.left
        : anchor.right - child.width;
    final endX = textDirection == TextDirection.ltr
        ? anchor.right - child.width
        : anchor.left;
    return switch (placement) {
      OverlayPlacement.top => Offset(
        anchor.center.dx - child.width / 2,
        anchor.top - gap - child.height,
      ),
      OverlayPlacement.bottom => Offset(
        anchor.center.dx - child.width / 2,
        anchor.bottom + gap,
      ),
      OverlayPlacement.left => Offset(
        anchor.left - gap - child.width,
        anchor.center.dy - child.height / 2,
      ),
      OverlayPlacement.right => Offset(
        anchor.right + gap,
        anchor.center.dy - child.height / 2,
      ),
      OverlayPlacement.topStart => Offset(
        startX,
        anchor.top - gap - child.height,
      ),
      OverlayPlacement.topEnd => Offset(endX, anchor.top - gap - child.height),
      OverlayPlacement.bottomStart => Offset(startX, anchor.bottom + gap),
      OverlayPlacement.bottomEnd => Offset(endX, anchor.bottom + gap),
    };
  }

  static List<OverlayPlacement> _defaultFallbacks(OverlayPlacement placement) =>
      switch (placement) {
        OverlayPlacement.top => const [
          OverlayPlacement.bottom,
          OverlayPlacement.right,
          OverlayPlacement.left,
        ],
        OverlayPlacement.bottom => const [
          OverlayPlacement.top,
          OverlayPlacement.right,
          OverlayPlacement.left,
        ],
        OverlayPlacement.left => const [
          OverlayPlacement.right,
          OverlayPlacement.bottom,
          OverlayPlacement.top,
        ],
        OverlayPlacement.right => const [
          OverlayPlacement.left,
          OverlayPlacement.bottom,
          OverlayPlacement.top,
        ],
        OverlayPlacement.topStart => const [
          OverlayPlacement.bottomStart,
          OverlayPlacement.topEnd,
          OverlayPlacement.bottomEnd,
        ],
        OverlayPlacement.topEnd => const [
          OverlayPlacement.bottomEnd,
          OverlayPlacement.topStart,
          OverlayPlacement.bottomStart,
        ],
        OverlayPlacement.bottomStart => const [
          OverlayPlacement.topStart,
          OverlayPlacement.bottomEnd,
          OverlayPlacement.topEnd,
        ],
        OverlayPlacement.bottomEnd => const [
          OverlayPlacement.topEnd,
          OverlayPlacement.bottomStart,
          OverlayPlacement.topStart,
        ],
      };
}
