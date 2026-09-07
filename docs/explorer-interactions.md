# Explorer interaction contracts

These contracts form the public explorer interaction baseline introduced in
Carpenter 0.3.0.

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

## Composition rule

One application operation should be represented once and projected into every
input surface that exposes it. A move, copy, link, rename, delete, or restore
operation may therefore appear as a command shortcut, context action, toolbar
button, row action, or drag/drop gesture without each surface acquiring its own
persistence callback.

Clipboard state, undo history, current/remembered locations, selection, and edit
drafts are intentionally caller-owned. Applications may preserve them across
navigation, serialize them, or discard them according to product policy without
Carpenter hiding a second source of truth in widget state.

Server-backed explorers should apply authoritative mutation results through
`CarpenterTreePatch` where possible and reserve full snapshot refreshes for
explicit refresh or reconciliation. This keeps unrelated branches stable while
still leaving persistence and conflict handling to the application.

The Widgetbook catalog includes a live Explorer interactions example covering
location switching, the typed clipboard and undo scopes, and both inline-edit
primitives so these contracts remain visible while applications adopt them.
