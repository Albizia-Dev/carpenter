## Unreleased — Messenger access cancellation

- Add optional controlled cancelLabel/onCancel to messenger access, independently of account switching; defaults preserve existing callers.
- Keep cancellation disabled during busy stages; extend the canonical Playground and narrow-screen form/confirmation golden checks.

## Unreleased — Messenger access

- Add experimental controlled CarpenterMessengerAccess: credential form, connection, account preparation, browser handoff, failure and exit stages.
- Preserve form geometry during submission, obscure passwords by default, support keyboard submission and keyboard-inset scrolling.
- Add a canonical Widgetbook Playground and five light/dark/large-text goldens plus interaction checks.

## Unreleased — Contextual workspace shell

- Add controlled CarpenterWorkspaceShell and CarpenterNavigationPalette, with adaptive navigation, workspace selection, global header actions, notice/activity slots and caller-owned search states.
- Keep page editors mounted while navigation collapses, changes breakpoint or opens as a modal drawer; share Escape, focus trapping and focus restoration with other overlays.
- Add a canonical Widgetbook Playground with 55 named scenarios and wide/narrow behavioral coverage; document application-owned routing, permissions and persistence.

## Unreleased — Messenger attachment messages

- Add controlled file labels to message bubbles and captionless composer submission for persisted attachments.
- Keep the composer at the bottom when the attachment tray is shorter than its height limit.
- Add a Widgetbook ready-file/send/retry scenario and wide/light and narrow/dark/large-text golden coverage.

## Unreleased — RSP detail loading

- Add controlled result-loading composition that unmounts acceptance actions during loading/failure.
- Add Widgetbook initial/loading/error scenes, three goldens, and retry verification without automatic acceptance.

## Unreleased — RSP result acceptance

- Add reviewRequired recovery state for a confirmed earlier command whose current result must be reloaded; avoid falsely reporting that confirmation was rejected.

- Add controlled result acceptance composition with explicit unknown-outcome recovery, permission-based action visibility, and no optimistic success.
- Add Widgetbook phases and five reviewed golden cases using generated Core fixture text.

## Unreleased — Work inbox

- Keep one shared stale-data recovery notice visible above both list and details; show refresh progress within details.
- Generate Widgetbook inbox fixtures from the shared Core scenario catalog, including typed kind mapping and matching description search/order.

- Add controlled CarpenterWorkInbox with search, filters, flat queue rows, responsive details, explicit return to list, preview and recovery states.
- Add canonical Widgetbook scenes and six light/dark/narrow/large-text golden cases with filtering, recovery and navigation checks.

## Unreleased — Messenger workspace

- Notify the host when pending original navigation is cancelled by the user, allowing scoped queued lookup cancellation.

- Cancel pending quote navigation on a host-reported failure for that message; add an original-lookup failure scenario to Widgetbook.

- Automatically open a requested quote original when the host resolves it; cancel pending navigation on explicit cancellation, scrolling, another quote, or room disposal.

- Add a host callback for unavailable quoted originals and an accessible room-scoped lookup status, with a Widgetbook recovery scenario.

- Add loaded-original navigation from quotes with lazy variable-height history, an explicit original marker, return to latest, and an unavailable-original state.

- Add controlled reply actions and quote previews in message bubbles/composer, with cancellation and a narrow-screen golden.
- Ignore pointer-up pressed-state updates after an interactive region is disposed by opening a long-press menu.

- Add optional controlled directory search and visible-ID filtering without losing the selected detail; clear/Escape restores the list, and empty/error states remain distinct.
- Add controlled messenger workspace, bubbles and composer with per-room history loading/retry presentation and explicit NeedAnswer.
- Use compact conversation headers, separate incoming/outgoing surfaces, bounded message widths, timestamp slots and consecutive-author grouping with stable identities and a five-minute/same-day bound.
- Move message copy to a keyboard/pointer action menu and send to the composer trailing action. Bubble menus require an Overlay ancestor; controlled callbacks remain host-owned.
- Cover the canonical Widgetbook layout in light/narrow/dark/large-text and grouped-message goldens, including keyboard, clipboard and draft-preservation behavior.

## Unreleased — Nested actions

- Add `CarpenterActionDescriptor.group` and recursive children for menu and toolbar actions, retaining existing constructor calls.
- Navigate submenu levels with Enter/Right, Back/Left and Escape; selecting a leaf dismisses the menu. Submenus stay within the anchored menu bounds on compact screens.
- Add `CarpenterPageHeader.overflowActions` for actions that always remain under the overflow button.

## Unreleased — Treasury interaction refinements

- Add optional independent `onOpen` navigation to expandable surfaces and optional shortcut badges to buttons, including descriptor-based actions.
- Keep section actions aligned with their heading and measure shortcut badges in action overflow layout.
- Use Russian default calendar, pagination, input, collection and action guidance; compact pagination uses x/y and wide pagination omits redundant summary text.
- Preserve existing constructor calls; Widgetbook playgrounds expose disclosure navigation and shortcut badges.

## Unreleased

- Keep page and entity header actions beside the heading at compact widths, collapsing into overflow without moving below it.
- Add variable-height collection rows with parent-owned corners and optional DataList item padding for composed interactive rows.

- Preserve the invoking page default text style when opening typed dialogs, including editor panels.

- Add controlled toggle actions across buttons, icon buttons and menus: neutral when off, the configured action role when on, with native toggle semantics.
- Show shortcuts in action menus and icon hover hints; add optional identity slots to page and record headers.
- Add adaptive editor dialogs and opt-in short-list wrapping without changing existing defaults.

- Preserve mounted page content and natural document height during refresh, blocking and skeleton states; show indeterminate progress when no percentage is available.

- Add controlled searchable MultiSelect with removable values, bounded results and caller-owned remote search state; replace entity checkbox lists in Projects+ specimens.

- Keep definition-list actions adjacent to their values and tighten metadata row spacing.
- Add opt-in frozen first columns to EditableTable, preserving editor identity, focus, hit testing and RTL positioning during horizontal scrolling.
- Refine Projects+ board metadata, linked-record selection and conflict comparison specimens.

- Present kanban columns as unframed lanes with compact count badges; card builders own item surfaces.
- Include fixed column widths and row spacing in editable-table horizontal scroll extents.
- Add 28 deterministic Projects+ compositions to Widgetbook, including boards, forms, materials, financials and correspondence.

- Add an open-state chevron to select fields, preserving field state colors and sizing.

- Add controlled inline disclosure and persistent condition summaries to FilterBar; hide secondary Treasury filters by default.
- Keep single-line input hints within one line; remove empty search-label spacing.
- Localize pagination labels and retain leading totals at narrow widths and larger text scales.
- Add deterministic Treasury page and panel compositions, including record tabs, to Widgetbook.

- Add CarpenterExpander.listGroup for flush homogeneous list groups: no nested card or content padding, with a shared disclosure header.

- Align tree branch/leaf disclosure lanes and row heights, including scaled text; use directional chevrons and ellipsized labels.
- Give list slots semantic typography and move rich-row trailing content below descriptions on narrow layouts.
- Avoid expander layout invalidation when nested sections close with animations disabled.
- Make expander headers keyboard/click accessible with disclosure semantics and icons; preserve independent header actions.
- Add shared desktop payment, account, folder-tree and nested audit examples to Widgetbook with visual goldens.

- Fix definition-list spacing and compact status badges in project layouts.
- Keep constrained button labels on one line and account for text scale and focus in action-strip sizing.
- Wrap filled selection groups into readable rows and preserve keyboard navigation after controlled rebuilds.
- Preserve tree row identity when root items change during filtering; keep table text within complete visible lines at larger text scales.
- Add shared dsktp project/materials examples to Widgetbook with desktop, narrow, editing, loading, and scaled-text goldens.

## 0.4.10

- Date input reports incomplete, invalid and accepted edits through the optional `onInputValidityChanged` callback so forms can block stale-value submission.

## 0.4.9

- Kanban columns scroll independently below fixed headings in bounded layouts, preserving content-sized embedding and stable column scroll positions.

## 0.4.8

- Separate pointer focus from keyboard focus highlighting in action controls; tabs keep one selected traversal stop and preserve arrow-key navigation.
- Autosuggest and ComboBox close suggestions when focus leaves, let outside clicks reach the next control, and keep editing focus during suggestion selection. Only the active suggestion is highlighted.

## 0.4.7

- Allow host font families and fallback families in the shared typography resolver, consistently across content and component roles.

## 0.4.6

- Project commands with asynchronously collected input into shared header, menu, and dialog actions. Cancellation, unmounting, and changed availability prevent late execution; scoped command effects and error handling remain intact.

# 0.4.5

- Collection search can atomically update domain filters and reset pagination
  while retaining shared debounce and cancellation. Clearing a draft or applying
  an explicit query now cancels stale pending search commits.

# 0.4.4

- Input now supports native capitalization and a non-editable unit suffix.
- Added controlled password masking to Input, disabling suggestions and protecting
  the semantic value when obscured.
- Added a scoped dialog builder for stateful forms while preserving the existing
  typed static dialog API, focus management and route results.

# 0.4.3

- Nullable Select options now display and select their explicit label, allowing
  application filters to offer an accessible “All” choice.

# 0.4.2

- CarpenterApp forwards localization delegates, supported locales, root rem and
  an application builder; tab activation now retains keyboard navigation.

- Ссылки по умолчанию не подчёркиваются; размеры checkbox/radio согласованы.
- Дата, диапазон и время выбираются без диалогов: прямой цифровой ввод,
  календарь рядом с полем на desktop и внутри формы на мобильных платформах.
- Добавлены клавиатурная навигация календаря и выбор месяца/года.
- Обновлены Notice, системные Gravity Icons и неопределённый прогресс загрузки.
- Усилен контраст полей, выбора, disabled-состояний и анимированной загрузки;
  добавлены матрица контрастов и поведенческие тесты.

# 0.4.1

- Fixed the legacy entrypoint in the published package by including the legacy
  icon implementation that a case-insensitive Git ignore rule omitted from 0.4.0.
- Kept the complete legacy API available through `carpenter_older.dart`.

# 0.4.0

- Bundled the complete `carpenter_older` 0.0.1 implementation inside Carpenter,
  available through the separate `package:carpenter/carpenter_older.dart` import.
- Kept legacy types, behavior, and exports isolated from `carpenter.dart` and the
  modern layered entrypoints; the standalone `carpenter_older` dependency is no
  longer needed by migrated applications.
- Retained the legacy API for incremental integration without deprecating or
  removing it, and carried over its existing compatibility tests.
- Included the nested task composition, cancellable inline editing, action glyph,
  and project sample improvements developed since 0.3.4.

# 0.3.4

- Added semantic `CarpenterLinkRole` variants for inline, standalone,
  subtle, and prominent link presentation.
- Added independent `CarpenterLinkUnderline` policies with semantic
  automatic defaults and explicit always, hover/focus, or none behavior.
- Changed the default `CarpenterLink` treatment to neutral standalone
  styling with hover/focus underline while preserving explicit action
  color overrides.
- Added Widgetbook role coverage and regression tests for link styling,
  focus behavior, activation, and accessibility semantics.

# 0.3.3

- Removed card chrome and row dividers from `CarpenterDefinitionList` so it can
  compose cleanly inside page regions.
- Added adaptive primary and secondary row actions backed by semantic
  `CarpenterActionDescriptor` values.

# 0.3.1

- Fixed `CarpenterPage` primary content layout so desktop pointer hit testing
  cannot observe its page padding before that padding has a size.

# 0.3.0

- Reworked breadcrumbs into a strictly single-line, width-aware path that
  collapses ancestors into an accessible overflow menu instead of wrapping.
- Added typed application clipboard state and reusable copy, cut, and paste
  commands with familiar Cmd/Ctrl shortcuts; cut remains presentation-only
  until a successful paste.
- Added reusable undo/redo stacks and command-result policy so one semantic
  operation can drive keyboard shortcuts, actions, and reversible mutations.
- Expanded drag-and-drop into Finder-like move/copy/link operation negotiation,
  including desktop modifier policy and dragging selected tree roots as one
  batch.
- Added controlled inline editing with pencil-to-check commit presentation,
  Enter commit, Escape cancel, caller-owned drafts, validation, and persistence.
- Added a generic explorer location strip for primary destinations plus an
  optional remembered destination, with bounded-width joined controls.
- Added immutable tree presentation patches for update, insert, remove, and
  reparent operations with structural sharing, allowing authoritative server
  mutation results to update only affected tree ancestry without refetching an
  entire tree.

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
