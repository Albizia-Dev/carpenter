import 'dart:async';

import 'package:flutter/foundation.dart';

import 'undoable_operation.dart';

/// Current execution phase of the undo/redo history.
enum CarpenterUndoExecution {
  /// No undo or redo callback is currently running.
  idle,

  /// The next undo callback is currently running.
  undoing,

  /// The next redo callback is currently running.
  redoing,
}

/// Immutable snapshot of caller-owned undo/redo history.
@immutable
final class CarpenterUndoState {
  /// Creates an undo state from explicit stacks and execution state.
  const CarpenterUndoState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.execution = CarpenterUndoExecution.idle,
    this.error,
  });

  /// Completed operations currently available for undo, oldest first.
  final List<CarpenterUndoableOperation> undoStack;

  /// Undone operations currently available for redo, oldest first.
  final List<CarpenterUndoableOperation> redoStack;

  /// Current undo/redo execution phase.
  final CarpenterUndoExecution execution;

  /// Most recent undo/redo error retained for caller presentation or recovery.
  final Object? error;

  /// Whether one operation may currently be undone.
  bool get canUndo =>
      execution == CarpenterUndoExecution.idle && undoStack.isNotEmpty;

  /// Whether one operation may currently be redone.
  bool get canRedo =>
      execution == CarpenterUndoExecution.idle && redoStack.isNotEmpty;

  /// Most recent operation that would be undone next.
  CarpenterUndoableOperation? get nextUndo =>
      undoStack.isEmpty ? null : undoStack.last;

  /// Most recent operation that would be redone next.
  CarpenterUndoableOperation? get nextRedo =>
      redoStack.isEmpty ? null : redoStack.last;
}

/// Caller-ownable undo/redo history for application commands.
///
/// Registering a new operation clears redo history. Failed undo or redo work
/// leaves both stacks untouched so the caller can retry after recovering from a
/// transient failure.
final class CarpenterUndoController extends ValueNotifier<CarpenterUndoState> {
  /// Creates empty history with the bounded [maximumDepth].
  CarpenterUndoController({this.maximumDepth = 100})
    : assert(maximumDepth > 0),
      super(const CarpenterUndoState());

  /// Maximum number of completed operations retained for undo.
  final int maximumDepth;

  /// Whether an undo can start now.
  bool get canUndo => value.canUndo;

  /// Whether a redo can start now.
  bool get canRedo => value.canRedo;

  /// Registers a completed reversible [operation] and clears redo history.
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

  /// Clears both history stacks and the last error.
  void clear() => value = const CarpenterUndoState();

  /// Executes the next undo operation and returns whether one ran.
  ///
  /// A failed callback restores both stacks, stores the error, and rethrows it.
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

  /// Executes the next redo operation and returns whether one ran.
  ///
  /// A failed callback restores both stacks, stores the error, and rethrows it.
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
