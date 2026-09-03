enum CollectionSelectionMode { none, single, multiple, allMatching }

/// Pointer and keyboard semantics used by a multiple-selection collection.
///
/// [toggle] preserves the compact/touch-friendly behaviour where every
/// activation toggles one item. [desktop] follows desktop collection
/// conventions: an unmodified activation replaces the selection, Ctrl/Cmd
/// toggles one item, and Shift selects a visible range from the anchor.
enum CollectionMultiSelectionBehavior { toggle, desktop }
