# 0.2.1

- Added adaptive contextual actions so secondary pointer presses and touch
  long-presses invoke the same semantic `CarpenterActionDescriptor` set.
- Made table and tree-table action lanes remain pinned to the trailing edge while
  horizontally scrolling data columns move underneath them.
- Reused `CarpenterTableColumn.actions` and `CarpenterTreeTableColumn.actions`
  builders for inline, overflow, and contextual action presentation instead of
  requiring duplicate application action definitions.
- Kept the legacy `CarpenterTreeTable.actions` and `secondaryActions` shorthand
  source-compatible while projecting those actions into the same pinned and
  contextual behavior.

# 0.2.0

Carpenter 0.2.0 is a migration release that consolidates the application,
resource, command, collection, and semantic presentation contracts introduced
since 0.1.8.

## Migration notes

- `CarpenterResourceController.data` is now read-only to consumers. Use
  `replaceData` or `updateData` for local reconciliation and optimistic changes.
- `CarpenterResourceController` is an application extension point again and
  exposes `didChangeData(previous, next)` for derived state such as command
  availability. The base controller owns the corresponding notification.
- Resource refresh failures no longer erase already loaded data. Existing data
  remains visible and `refreshFailure` exposes the failure separately; initial
  load failures remain blocking.
- Resource `refreshCommand` and `retryCommand` now fail their command lifecycle
  when the underlying load fails, while direct `refresh()` remains a
  state-driven, non-throwing controller API.
- Command availability no longer retains stale `disabledReason` values across
  later availability transitions.
- Presentation-only command surfaces consume an already-recorded asynchronous
  command failure instead of leaking a second uncaught Future error. Direct
  command/executor calls still propagate failures to programmatic callers.

## Application and behaviour

- Added a semantic command execution lifecycle with started, succeeded, and
  failed events, command effects, refresh scopes, blocking effects, and a shared
  executor boundary.
- Added application command policy helpers for centralized success/failure
  feedback, undo handling, and semantic invalidation without coupling commands
  to a particular state-management or cache implementation.
- Added shared request-gate cancellation and stale-request protection used by
  application resource and collection lifecycles.
- Centralized loading behaviour below application pages so loading ownership and
  presentation can be reused without duplicating page-specific machinery.
- Unified command-to-action projection so buttons, shortcuts, toolbars, table
  rows, and other action surfaces share the same command availability and
  execution semantics.

## Collections and actions

- Added a shared grid layout resolver used by ordinary and tree tables for
  consistent fixed/flexible sizing and capped-flex redistribution.
- Unified toolbar, table, and tree-table adaptive actions behind the shared
  action-strip and overflow behaviour.
- Added semantic table action lanes with stable geometry and compact preferred
  widths instead of ad-hoc action-column sizing.
- Made tree-table actions ordinary columns through
  `CarpenterTreeTableColumn.actions`, while retaining the legacy top-level
  action shorthand as a compatibility path.
- Expanded table and tree-table column contracts with semantic text, number,
  status, alignment, vertical alignment, width, and resizing behaviour.
- Unified table/tree cell geometry, metrics, typography, borders, selection,
  hover treatment, and animated Gravity chevrons for tree disclosure.

## Components and foundation

- Promoted `CarpenterFieldShell` to the public shared field primitive and routed
  text-editing and selectable fields through the same label, feedback, spacing,
  and semantic structure.
- Added richer field feedback and semantic surface coverage for validation,
  accessibility, and state presentation.
- Expanded semantic theme roles and generated Mordant component/metric tokens
  used by controls, tables, typography, loading, and application surfaces.
- Added conceptual public entrypoints for application, components, collections,
  foundation, layout, and patterns while retaining the umbrella
  `package:carpenter/carpenter.dart` entrypoint.

## Quality

- Strengthened pull-request verification to require repository formatting,
  library analysis, all non-golden package tests, and successful Widgetbook and
  example web builds.
- Added public-entrypoint, command-policy, request-gate, resource lifecycle,
  field-shell, grid-layout, table, tree-table, action, and theme regression
  coverage.

# 0.1.8

- Added a controlled, keyboard-accessible joined selection-button group for
  switching local content scopes without a navigation sidebar.
- Unified tree-table headers and rows with Carpenter table geometry, spacing,
  borders, hover transitions, selection states, and vertical alignment.
- Replaced tree disclosure markers with animated Gravity chevrons, added typed
  entity icons, and animated branch and root-content transitions.
- Allowed explorer pages to omit navigation when their content scope is exposed
  by another control.

# 0.1.7

- Added opt-in desktop multiple-selection semantics for trees and tree tables:
  unmodified activation replaces selection, Ctrl/Cmd toggles, and Shift selects
  a visible range while preserving the source-compatible toggle default.
- Added caller-owned scroll controllers to trees and tree tables for restoring
  explorer position per location.
- Added immutable local explorer history with independent back and forward
  stacks that does not depend on application router history.

# 0.1.6

- Made typed dialog close callbacks route-aware so a delayed asynchronous
  action cannot pop the page below an already dismissed dialog.

# 0.1.5

- Added typed `showCarpenterDialog<T>` route composition with result-bearing
  actions and automatic capture of the nearest Carpenter theme and root `rem`,
  including support for locally hosted Carpenter subtrees during incremental
  migrations from other UI systems.
- Kept tree row geometry keys outside default drag feedback so draggable trees
  no longer duplicate `GlobalKey` instances while a row is moving.

# 0.1.4

- Unified page viewport ownership so `CarpenterPage` owns ordinary document
  scrolling while explorer and collection content can explicitly keep a
  child-owned viewport, eliminating duplicated page inset and nested scrolling.
- Made the flow-native `CarpenterPageSection` canonical and removed the hidden
  legacy section implementation from the page-block compatibility layer.
- Added independent tree selection and activation, keyboard activation,
  filtering with retained ancestor paths, and `CarpenterTreeController.reveal`
  for controlled navigation to nested nodes.
- Extended `CarpenterTreeTable` with the same tree interaction contracts and
  added fixed/flexible column widths plus semantic column alignment.
- Moved display/title sizing from runtime `CarpenterText` scaling into Mordant
  typography tokens and regenerated the checked-in token output.
- Added project-shaped Widgetbook coverage for page composition, tree-table
  filtering/reveal/activation, and regression tests for filtered paths and
  controller reveal-path discovery.

# 0.1.3

- Stabilized collection hover styling so state transitions animate color without
  re-running row layout geometry on every animation tick.
- Avoided redundant drag-and-drop target rebuilds while the pointer remains in
  the same accepted payload, operation, and before/inside/after position.
- Extended `CarpenterProgress` with an indeterminate mode by making `value`
  optional while preserving determinate progress for finite values.
- Animated determinate progress changes with Carpenter motion tokens and drove
  indeterminate progress from the existing Mordant loading-cycle token, with
  reduced-motion handling retained.
- Added regression coverage for stable list/tree hover geometry, drag hover
  rebuilds, and determinate/indeterminate progress semantics.

# 0.1.2

- Stabilized default drag feedback geometry so flex and stretched children keep
  the rendered source size while moving through an overlay.
- Kept Kanban columns as stable drop targets, including empty columns, while
  retaining precise card insertion positioning for non-empty columns.
- Made `CarpenterSelect`, `CarpenterComboBox`, and `CarpenterAutosuggest`
  self-manage transient overlay visibility by default while preserving an
  optional controlled `open` / `onOpenChanged` mode.
- Added `CarpenterPageBody` for standard scrollable page padding and vertical
  rhythm without repeating `ListView` and spacer boilerplate on every screen.
- Exported bundled Gravity UI icons through the main `carpenter.dart` barrel so
  ordinary applications can use one package import.
- Fixed `CarpenterTreeView.actions` so semantic row actions without icons render
  as compact text actions instead of asserting at runtime.
- Reworked the example into a connected feature workspace with live controlled
  Kanban and generic reordering, a keyboard-friendly tree explorer, persistent
  notifications, record breadcrumbs, and a production-shaped typed form using
  masked, number, date, time, range, select, autosuggest, combo, and file
  inputs.
- Rewrote package and example documentation around the current public API,
  state-ownership model, routes, commands, and real application composition.

# 0.1.1

- Added adaptive breadcrumbs with overflow navigation for deep paths.
- Added controlled numeric, time, and date-range inputs, including numeric
  input formatting and validation support in the shared field pipeline.
- Added badges, avatar groups with automatic overflow, and persistent
  notification lists with unread state, actions, and caller-owned dismissal.
- Added interactive Widgetbook playgrounds and behavioural tests for the new
  components.
- Added `CarpenterMaskedInput` and rebuilt date, time, and date-range controls
  as masked text fields with trailing adaptive picker actions.
- Refined breadcrumbs to the compact text-and-chevron presentation used by the
  example while retaining deep-path overflow behaviour.
- Added the typed drag-and-drop kernel with payloads, move/copy/link operation
  negotiation, shared sessions, draggable adapters, drop targets, and
  before/inside/after positioning.

# 0.1.0

- Added the framework-only `Application` root with Carpenter theme and unit
  scopes plus Navigator and Router integration.
- Added semantic action prominence variants, the utility action color role,
  and matching role support for buttons and icon buttons.
- Added independently configurable logical start/end shape roles for controls
  and status indicators.
- Replaced loading content substitution with a token-driven animated striped
  background that preserves action content and geometry.
- Added generated OKLCH palette tokens and expanded the Widgetbook catalog.
- Added warning, success, and info action roles, role-tinted action state
  backgrounds, and the revised loading-stripe direction.
- Added extra-small and extra-large control/icon size roles, tokenized loading
  rotation, and generator-backed OKLCH ramps for every semantic palette.
- Added semantic field infrastructure, text input and text area controls,
  tri-state checkbox, generic radio groups, switches, and interactive
  Widgetbook playgrounds for the complete Basic control set.
- Added full mouse text-selection gestures, semantic color roles for checkbox,
  radio, and switch controls, and size-dependent rounded shape tokens.
- Added shared anchored-overlay infrastructure plus controlled popover, menu,
  action dropdown, and semantic tooltip components.
- Added typed Select, ComboBox, Autosuggest, queued toast presentation, modal
  dialogs, and a shared overlay lifecycle and option-navigation runtime.
- Added the backend-neutral Collections Kernel and a controlled structured-data
  Table with typed columns, stable-key selection, pagination, resizing, and
  keyboard navigation.
- Added semantic application shell, navigation and adaptive regions, page
  headers, overflow toolbars, controlled split views, and master/detail layout.
- Added controlled collection, report, object, form, and master/detail page
  patterns with unified zero, empty-result, loading, and initial-error states.
- Expanded Layout and Page Patterns Widgetbook cases with deterministic
  network-like loading, cursor pagination, refresh failures, and async actions.
- Added Foundation color catalogs, role and size comparison cases, and
  Layout/Page Pattern-only semantic viewport presets with an off mode.
- Hardened Table body sizing for short viewport constraints used by adaptive
  page patterns.

# 0.1.0-dev.1

- Established the initial publishable Flutter package.
- Added the development example application.
- Added Widgetbook development catalog.
- Added package documentation and publication quality gates.
