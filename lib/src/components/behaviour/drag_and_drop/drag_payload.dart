import 'package:flutter/foundation.dart';

import 'drag_operation.dart';

@immutable
final class CarpenterDragPayload<T> {
  const CarpenterDragPayload({
    required this.data,
    this.id,
    this.allowedOperations = const {CarpenterDragOperation.move},
    this.metadata = const {},
  }) : assert(allowedOperations.length > 0);

  final T data;
  final Object? id;
  final Set<CarpenterDragOperation> allowedOperations;
  final Map<String, Object?> metadata;

  bool supports(CarpenterDragOperation operation) =>
      allowedOperations.contains(operation);

  CarpenterDragPayload<R> map<R>(R Function(T value) transform) =>
      CarpenterDragPayload<R>(
        data: transform(data),
        id: id,
        allowedOperations: allowedOperations,
        metadata: metadata,
      );
}
