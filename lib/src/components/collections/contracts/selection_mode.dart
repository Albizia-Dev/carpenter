/// Selection policy expressed in stable item keys, not loaded row positions.
enum CollectionSelectionMode {
  /// Selection is disabled; key operations leave the selection unchanged.
  none,

  /// At most one explicit key is selected.
  single,

  /// Any number of explicit keys may be selected.
  multiple,

  /// Every item matching the external query is selected except
  /// [CollectionSelection.excludedKeys], including items not loaded locally.
  allMatching,
}

/// Pointer and keyboard semantics used by a multiple-selection collection.
///
/// [toggle] preserves the compact/touch-friendly behaviour where every
/// activation toggles one item. [desktop] follows desktop collection
/// conventions: an unmodified activation replaces the selection, Ctrl/Cmd
/// toggles one item, and Shift selects a visible range from the anchor.
enum CollectionMultiSelectionBehavior {
  /// Each activation toggles the activated item without requiring a modifier
  /// key.
  toggle,

  /// Plain activation replaces selection, Ctrl/Cmd toggles, and Shift extends
  /// a visible range.
  desktop,
}
