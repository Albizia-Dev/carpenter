import 'package:flutter/foundation.dart';

import 'selection_mode.dart';

@immutable
final class CollectionSelection<K> {
  CollectionSelection._({
    required this.mode,
    required Set<K> selectedKeys,
    required Set<K> excludedKeys,
  }) : selectedKeys = Set.unmodifiable(selectedKeys),
       excludedKeys = Set.unmodifiable(excludedKeys);

  factory CollectionSelection.none() => CollectionSelection._(
    mode: CollectionSelectionMode.none,
    selectedKeys: const {},
    excludedKeys: const {},
  );

  factory CollectionSelection.single([K? selectedKey]) => CollectionSelection._(
    mode: CollectionSelectionMode.single,
    selectedKeys: selectedKey == null ? const {} : {selectedKey},
    excludedKeys: const {},
  );

  factory CollectionSelection.multiple([Iterable<K> selectedKeys = const []]) =>
      CollectionSelection._(
        mode: CollectionSelectionMode.multiple,
        selectedKeys: selectedKeys.toSet(),
        excludedKeys: const {},
      );

  factory CollectionSelection.allMatching([
    Iterable<K> excludedKeys = const [],
  ]) => CollectionSelection._(
    mode: CollectionSelectionMode.allMatching,
    selectedKeys: const {},
    excludedKeys: excludedKeys.toSet(),
  );

  final CollectionSelectionMode mode;
  final Set<K> selectedKeys;
  final Set<K> excludedKeys;

  bool get isEnabled => mode != CollectionSelectionMode.none;
  bool get isEmpty => switch (mode) {
    CollectionSelectionMode.none => true,
    CollectionSelectionMode.single ||
    CollectionSelectionMode.multiple => selectedKeys.isEmpty,
    CollectionSelectionMode.allMatching => false,
  };

  bool contains(K key) => switch (mode) {
    CollectionSelectionMode.none => false,
    CollectionSelectionMode.single ||
    CollectionSelectionMode.multiple => selectedKeys.contains(key),
    CollectionSelectionMode.allMatching => !excludedKeys.contains(key),
  };

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

  CollectionSelection<K> toggle(K key) =>
      contains(key) ? unselect(key) : select(key);

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

  CollectionSelection<K> clear() => switch (mode) {
    CollectionSelectionMode.none => this,
    CollectionSelectionMode.single => CollectionSelection<K>.single(),
    CollectionSelectionMode.multiple => CollectionSelection<K>.multiple(),
    CollectionSelectionMode.allMatching => CollectionSelection<K>.multiple(),
  };
}
