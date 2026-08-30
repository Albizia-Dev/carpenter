import 'package:flutter/widgets.dart';

import 'drag_payload.dart';

/// Internal carrier used to recover the pointer position from Flutter's
/// drag-target details, whose offset is relative to the drag feedback anchor.
final class CarpenterDragTransport<T> {
  CarpenterDragTransport(this.payload);

  final CarpenterDragPayload<T> payload;
  Offset dragStartPoint = Offset.zero;
}
