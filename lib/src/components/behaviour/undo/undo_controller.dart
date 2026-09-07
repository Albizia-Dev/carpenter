import 'dart:async';

import 'package:flutter/foundation.dart';

import 'undoable_operation.dart';

enum CarpenterUndoExecution { idle, undoing, redoing }

@immutable
final class CarpenterUndoState {
  const CarpenterUndoState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.execution = CarpenterUndoExecution.idle,
    this.error,
  });

  final List<CarpenterUndoableOperation> undoStack;
  final List<CarpenterUndoableOperation> redoStack;
  final CarpenterUndoExecution execution;
  final Object? error;

  bool get canUndo =>
      execution == CarpenterUndoExecution.idle && undoStack.isNotEmpty;
  bool get canRedo =>
      execution == CarpenterUndoExecution.idle && redoStack.isNotEmpty;
  CarpenterUndoableOperation? get nextUndo =>
      undoStack.isEmpty ? null : undoStack.last;
  CarpenterUndoableOperation? get nextRedo =>
      redoStack.isEmpty ? null : redoStack.last;
}

/// Caller-ownable undo/redo history for application commands.
///
/// Registering a new operation clears redo history. Failed undo or redo work
/// leaves both stacks untouched so the caller can retry after recovering from a
/// transient failure.
final class CarpenterUndoController extends ValueNotifier<CarpenterUndoState> {
  CarpenterUndoController({this.maximumDepth = 100})
    : assert(maximumDepth > 0),
      super(const CarpenterUndoState());

  final int maximumDepth;

  bool get canUndo => value.canUndo;
  bool get canRedo => value.canRedo;

  void register(CarpenterUndoableOperation operation) {
    final next = [...value.undoStack, operation];
    if (next.length > maximumDepth) {
      next.removeRange(0, next.length - maximumDepth);
    }
    value = CarpenterUndoState(
      undoStack: List.unmodifiable(next),
      execution: CarpenterUndoExecution.idle,
    );
  }

  void clear() => value = const CarpenterUndoState();

  Future<bool> undo() async {
    if (!value.canUndo) return false;
    final before = value;
    final operation = before.undoStack.last;
    value = CarpenterUndoState(
      undoStack: before.undoStack,
      redoStack: before.redoStack,
      execution: CarpenterUndoExecution.undoing,
    );
    try {
      await Future<void>.sync(operation.undo);
      final remaining = before.undoStack.take(before.undoStack.length - 1);
      value = CarpenterUndoState(
        undoStack: List.unmodifiable(remaining),
        redoStack: operation.redo == null
            ? before.redoStack
            : List.unmodifiable([...before.redoStack, operation]),
      );
      return true;
    } catch (error) {
      value = CarpenterUndoState(
        undoStack: before.undoStack,
        redoStack: before.redoStack,
        error: error,
      );
      rethrow;
    }
  }

  Future<bool> redo() async {
    if (!value.canRedo) return false;
    final before = value;
    final operation = before.redoStack.last;
    final redo = operation.redo;
    if (redo == null) return false;
    value = CarpenterUndoState(
      undoStack: before.undoStack,
      redoStack: before.redoStack,
      execution: CarpenterUndoExecution.redoing,
    );
    try {
      await Future<void>.sync(redo);
      final remaining = before.redoStack.take(before.redoStack.length - 1);
      value = CarpenterUndoState(
        undoStack: List.unmodifiable([...before.undoStack, operation]),
        redoStack: List.unmodifiable(remaining),
      );
      return true;
    } catch (error) {
      value = CarpenterUndoState(
        undoStack: before.undoStack,
        redoStack: before.redoStack,
        error: error,
      );
      rethrow;
    }
  }
}
