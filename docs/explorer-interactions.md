# Explorer interaction contracts

Carpenter owns reusable explorer mechanics while applications own domain state,
validation and persistence.

The shared contracts are intentionally the same across tables, trees and file-like
views:

- `CarpenterBreadcrumbs` keeps one physical line and overflows ancestors by width.
- `CarpenterExplorerLocationStrip` renders caller-owned primary destinations plus
  an optional remembered destination without owning navigation history.
- `CarpenterClipboardController` represents typed copy/cut state; cut remains a
  presentation state until a successful paste.
- `CarpenterUndoController` stores successful reversible operations. Commands can
  return undo/redo callbacks through `CarpenterCommandResult`.
- `CarpenterDragOperation` uses move/copy/link semantics and desktop modifier
  policy. Tree dragging carries the selected root set as one operation.
- `CarpenterInlineTextEdit` uses an explicit pencil-to-check interaction; the
  application owns edit state, draft, validation and persistence.
- `CarpenterTreePatch` applies authoritative server mutation results with
  structural sharing, so unaffected branches retain identity and consumers do
  not need to refetch a whole tree after a local mutation.

Application code should project one domain operation into commands, context
actions, keyboard shortcuts and drag/drop rather than implementing each input
surface separately.
