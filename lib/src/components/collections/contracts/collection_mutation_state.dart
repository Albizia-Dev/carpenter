import 'package:flutter/foundation.dart';

import 'collection_load_phase.dart';

/// Execution phase of an item-level mutation, independent of collection
/// loading.
enum CollectionMutationPhase {
  /// No mutation is currently in progress.
  idle,

  /// The affected item operation is being executed.
  running,

  /// The operation completed successfully.
  succeeded,

  /// The operation failed and may require retry or reconciliation.
  failed,
}

/// How an optimistic local change relates to its authoritative result.
enum CollectionReconciliation {
  /// No optimistic reconciliation is required.
  none,

  /// An optimistic change is visible but not yet confirmed.
  pending,

  /// The authoritative result confirmed the optimistic change.
  confirmed,

  /// The caller has rolled back the optimistic change after failure.
  rolledBack,
}

/// Immutable item-level mutation status keyed independently of the current
/// loaded rows.
///
/// It describes progress and reconciliation only; it neither performs
/// persistence nor rolls back data. Use separate instances for independently
/// running operations.
@immutable
final class CollectionMutationState<K> {
  /// Creates mutation status and defensively copies [affectedKeys] into an
  /// unmodifiable set.
  CollectionMutationState({
    this.phase = CollectionMutationPhase.idle,
    Iterable<K> affectedKeys = const [],
    this.optimistic = false,
    this.reconciliation = CollectionReconciliation.none,
    this.failure,
  }) : affectedKeys = Set.unmodifiable(affectedKeys);

  /// Current operation execution phase.
  final CollectionMutationPhase phase;

  /// Stable keys affected by this operation, including keys outside the
  /// loaded page.
  final Set<K> affectedKeys;

  /// Whether the caller presented the change before authoritative
  /// confirmation.
  final bool optimistic;

  /// Confirmation or rollback status of an optimistic change.
  final CollectionReconciliation reconciliation;

  /// Optional error information when the operation failed.
  final CollectionFailure? failure;

  /// Starts a new status for [keys], clearing any previous failure.
  /// Optimistic operations begin pending reconciliation; others require no
  /// reconciliation.
  CollectionMutationState<K> running(
    Iterable<K> keys, {
    bool optimistic = false,
  }) => CollectionMutationState<K>(
    phase: CollectionMutationPhase.running,
    affectedKeys: keys,
    optimistic: optimistic,
    reconciliation: optimistic
        ? CollectionReconciliation.pending
        : CollectionReconciliation.none,
  );

  /// Returns successful status for the same keys. Optimistic changes become
  /// confirmed and failure information is cleared.
  CollectionMutationState<K> succeeded() => CollectionMutationState<K>(
    phase: CollectionMutationPhase.succeeded,
    affectedKeys: affectedKeys,
    optimistic: optimistic,
    reconciliation: optimistic
        ? CollectionReconciliation.confirmed
        : CollectionReconciliation.none,
  );

  /// Records [failure] for the same keys and preserves optimistic status.
  /// Setting [rolledBack] marks reconciliation as rolled back; it does not
  /// undo application data.
  CollectionMutationState<K> failed(
    CollectionFailure failure, {
    bool rolledBack = false,
  }) => CollectionMutationState<K>(
    phase: CollectionMutationPhase.failed,
    affectedKeys: affectedKeys,
    optimistic: optimistic,
    reconciliation: rolledBack
        ? CollectionReconciliation.rolledBack
        : reconciliation,
    failure: failure,
  );
}
