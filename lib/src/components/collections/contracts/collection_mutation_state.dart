import 'package:flutter/foundation.dart';

import 'collection_load_phase.dart';

enum CollectionMutationPhase { idle, running, succeeded, failed }

enum CollectionReconciliation { none, pending, confirmed, rolledBack }

@immutable
final class CollectionMutationState<K> {
  CollectionMutationState({
    this.phase = CollectionMutationPhase.idle,
    Iterable<K> affectedKeys = const [],
    this.optimistic = false,
    this.reconciliation = CollectionReconciliation.none,
    this.failure,
  }) : affectedKeys = Set.unmodifiable(affectedKeys);

  final CollectionMutationPhase phase;
  final Set<K> affectedKeys;
  final bool optimistic;
  final CollectionReconciliation reconciliation;
  final CollectionFailure? failure;

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

  CollectionMutationState<K> succeeded() => CollectionMutationState<K>(
    phase: CollectionMutationPhase.succeeded,
    affectedKeys: affectedKeys,
    optimistic: optimistic,
    reconciliation: optimistic
        ? CollectionReconciliation.confirmed
        : CollectionReconciliation.none,
  );

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
