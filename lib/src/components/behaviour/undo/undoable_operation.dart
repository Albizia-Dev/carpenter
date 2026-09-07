import 'dart:async';

import 'package:flutter/foundation.dart';

/// One reversible operation registered in a [CarpenterUndoController].
@immutable
final class CarpenterUndoableOperation {
  /// Creates one completed operation with required [undo] and optional [redo].
  const CarpenterUndoableOperation({
    required this.label,
    required this.undo,
    this.redo,
  });

  /// Human-readable operation name used by command and feedback surfaces.
  final String label;

  /// Reverses the completed operation.
  final FutureOr<void> Function() undo;

  /// Reapplies the operation after an undo. Null means the operation is
  /// intentionally undo-only and therefore never enters the redo stack.
  final FutureOr<void> Function()? redo;
}
