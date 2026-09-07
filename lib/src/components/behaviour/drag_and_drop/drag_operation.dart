import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CarpenterDragOperation { move, copy, link }

enum CarpenterDropPosition { before, inside, after }

enum CarpenterDropAxis { vertical, horizontal }

/// Platform-aware operation selection for finder-like drag and drop.
///
/// The standard policy follows familiar desktop conventions: Option copies on
/// macOS, Command+Option links; Ctrl copies on Windows/Linux, Alt links, and
/// Shift explicitly requests a move. Unsupported operations fall back to the
/// source's preferred/default allowed operation.
@immutable
final class CarpenterDragOperationPolicy {
  const CarpenterDragOperationPolicy.standard();

  CarpenterDragOperation resolve({
    required TargetPlatform platform,
    required Set<LogicalKeyboardKey> pressedKeys,
    required Set<CarpenterDragOperation> allowedOperations,
    CarpenterDragOperation preferred = CarpenterDragOperation.move,
  }) {
    assert(allowedOperations.isNotEmpty);
    final apple =
        platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
    final control = _pressed(
      pressedKeys,
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    );
    final meta = _pressed(
      pressedKeys,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    );
    final alt = _pressed(
      pressedKeys,
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    );
    final shift = _pressed(
      pressedKeys,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    );

    CarpenterDragOperation? requested;
    if (apple) {
      if (meta && alt) {
        requested = CarpenterDragOperation.link;
      } else if (alt) {
        requested = CarpenterDragOperation.copy;
      }
    } else if (alt) {
      requested = CarpenterDragOperation.link;
    } else if (control) {
      requested = CarpenterDragOperation.copy;
    } else if (shift) {
      requested = CarpenterDragOperation.move;
    }

    if (requested != null && allowedOperations.contains(requested)) {
      return requested;
    }
    if (allowedOperations.contains(preferred)) return preferred;
    for (final candidate in const [
      CarpenterDragOperation.move,
      CarpenterDragOperation.copy,
      CarpenterDragOperation.link,
    ]) {
      if (allowedOperations.contains(candidate)) return candidate;
    }
    throw StateError('Drag payload has no allowed operations.');
  }

  bool _pressed(
    Set<LogicalKeyboardKey> keys,
    LogicalKeyboardKey generic,
    LogicalKeyboardKey left,
    LogicalKeyboardKey right,
  ) => keys.contains(generic) || keys.contains(left) || keys.contains(right);
}
