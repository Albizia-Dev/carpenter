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
- Added the Widgetbook development catalog.
- Added package documentation and publication quality gates.
