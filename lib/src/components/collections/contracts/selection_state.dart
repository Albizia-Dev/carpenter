import 'package:flutter/foundation.dart';

import 'selection_mode.dart';

/// Immutable key-based selection with explicit and all-matching
/// representations.
///
/// [allMatching] represents a query-wide selection, not an enumeration of
/// loaded items. The application must bind it to the intended query and
/// handle query changes. Operations return a new selection; rebuild the
/// consumer with that result.
@immutable
final class CollectionSelection<K> {
  CollectionSelection._({
    required this.mode,
    required Set<K> selectedKeys,
    required Set<K> excludedKeys,
  }) : selectedKeys = Set.unmodifiable(selectedKeys),
       excludedKeys = Set.unmodifiable(excludedKeys);

  /// Creates a disabled selection; contains always returns false.
  factory CollectionSelection.none() => CollectionSelection._(
    mode: CollectionSelectionMode.none,
    selectedKeys: const {},
    excludedKeys: const {},
  );

  /// Creates single-selection state, optionally selecting [selectedKey]. A
  /// null key means no selection.
  factory CollectionSelection.single([K? selectedKey]) => CollectionSelection._(
    mode: CollectionSelectionMode.single,
    selectedKeys: selectedKey == null ? const {} : {selectedKey},
    excludedKeys: const {},
  );

  /// Creates multi-selection state from a defensive, deduplicated copy of
  /// [selectedKeys].
  factory CollectionSelection.multiple([Iterable<K> selectedKeys = const []]) =>
      CollectionSelection._(
        mode: CollectionSelectionMode.multiple,
        selectedKeys: selectedKeys.toSet(),
        excludedKeys: const {},
      );

  /// Selects the entire externally defined query except a defensive copy of
  /// [excludedKeys]. This does not fetch or enumerate items.
  factory CollectionSelection.allMatching([
    Iterable<K> excludedKeys = const [],
  ]) => CollectionSelection._(
    mode: CollectionSelectionMode.allMatching,
    selectedKeys: const {},
    excludedKeys: excludedKeys.toSet(),
  );

  /// Policy controlling how selected and excluded keys are interpreted.
  final CollectionSelectionMode mode;

  /// Unmodifiable explicit keys used by single and multiple modes. Empty in
  /// all-matching mode.
  final Set<K> selectedKeys;

  /// Unmodifiable exceptions to query-wide selection in all-matching mode.
  final Set<K> excludedKeys;

  /// Whether the mode permits selection rather than disabling it.
  bool get isEnabled => mode != CollectionSelectionMode.none;

  /// Whether explicit selection is empty. Always false for all-matching mode
  /// because unloaded matching items may exist.
  bool get isEmpty => switch (mode) {
    CollectionSelectionMode.none => true,
    CollectionSelectionMode.single ||
    CollectionSelectionMode.multiple => selectedKeys.isEmpty,
    CollectionSelectionMode.allMatching => false,
  };

  /// Tests [key] according to [mode]. All-matching mode returns true unless
  /// the key is excluded; the caller is responsible for query membership.
  bool contains(K key) => switch (mode) {
    CollectionSelectionMode.none => false,
    CollectionSelectionMode.single ||
    CollectionSelectionMode.multiple => selectedKeys.contains(key),
    CollectionSelectionMode.allMatching => !excludedKeys.contains(key),
  };

  /// Returns selection including [key]. Single mode replaces the previous
  /// key; multiple mode adds it; all-matching mode removes its exclusion.
  /// Disabled mode is unchanged.
  CollectionSelection<K> select(K key) => switch (mode) {
    CollectionSelectionMode.none => this,
    CollectionSelectionMode.single => CollectionSelection<K>.single(key),
    CollectionSelectionMode.multiple => CollectionSelection<K>.multiple({
      ...selectedKeys,
      key,
    }),
    CollectionSelectionMode.allMatching => CollectionSelection<K>.allMatching(
      excludedKeys.where((candidate) => candidate != key),
    ),
  };

  /// Returns selection without [key]. Single mode clears the selection;
  /// multiple mode removes the key; all-matching mode adds an exclusion.
  /// Disabled mode is unchanged.
  CollectionSelection<K> unselect(K key) => switch (mode) {
    CollectionSelectionMode.none => this,
    CollectionSelectionMode.single => CollectionSelection<K>.single(),
    CollectionSelectionMode.multiple => CollectionSelection<K>.multiple(
      selectedKeys.where((candidate) => candidate != key),
    ),
    CollectionSelectionMode.allMatching => CollectionSelection<K>.allMatching({
      ...excludedKeys,
      key,
    }),
  };

  /// Returns [unselect] for an included key or [select] for an excluded key.
  CollectionSelection<K> toggle(K key) =>
      contains(key) ? unselect(key) : select(key);

  /// Includes the supplied loaded [keys] without discarding selections
  /// outside that set.
  ///
  /// Single mode selects the first distinct supplied key, or clears when no
  /// key is supplied. All-matching mode removes these keys from exclusions.
  /// This is not a server-side select-all operation.
  CollectionSelection<K> selectLoaded(Iterable<K> keys) {
    final loaded = keys.toSet();
    return switch (mode) {
      CollectionSelectionMode.none => this,
      CollectionSelectionMode.single =>
        loaded.isEmpty
            ? CollectionSelection<K>.single()
            : CollectionSelection<K>.single(loaded.first),
      CollectionSelectionMode.multiple => CollectionSelection<K>.multiple({
        ...selectedKeys,
        ...loaded,
      }),
      CollectionSelectionMode.allMatching => CollectionSelection<K>.allMatching(
        excludedKeys.where((key) => !loaded.contains(key)),
      ),
    };
  }

  /// Excludes only the supplied loaded [keys], preserving unrelated explicit
  /// keys or all-matching exclusions. Single mode is cleared only when its
  /// selected key is supplied.
  CollectionSelection<K> unselectLoaded(Iterable<K> keys) {
    final loaded = keys.toSet();
    return switch (mode) {
      CollectionSelectionMode.none => this,
      CollectionSelectionMode.single =>
        loaded.any(selectedKeys.contains)
            ? CollectionSelection<K>.single()
            : this,
      CollectionSelectionMode.multiple => CollectionSelection<K>.multiple(
        selectedKeys.where((key) => !loaded.contains(key)),
      ),
      CollectionSelectionMode.allMatching => CollectionSelection<K>.allMatching(
        {...excludedKeys, ...loaded},
      ),
    };
  }

  /// Removes selection. Disabled and explicit modes keep their policy;
  /// all-matching mode becomes an empty multiple selection rather than
  /// excluding an unknowable universe of keys.
  CollectionSelection<K> clear() => switch (mode) {
    CollectionSelectionMode.none => this,
    CollectionSelectionMode.single => CollectionSelection<K>.single(),
    CollectionSelectionMode.multiple => CollectionSelection<K>.multiple(),
    CollectionSelectionMode.allMatching => CollectionSelection<K>.multiple(),
  };
}
