# Carpenter application example

This example is a connected business workspace rather than a component gallery. Widgetbook covers exhaustive component states; this application demonstrates how Carpenter pieces fit together when state, navigation, loading and interaction are owned by real screens.

## Run

```sh
cd example
flutter run
```

For web:

```sh
flutter run -d chrome
```

## Routes

- `/` — overview dashboard, commands and nested loading boundaries
- `/projects` — searchable, sortable, selectable and paginated project collection
- `/projects/:id` — record details with breadcrumbs, metrics, tabs and timeline
- `/planning` — generic reorder plus live controlled Kanban drag-and-drop
- `/explorer` — controlled hierarchical resource tree with keyboard navigation
- `/operations` — loading aggregation, hotkeys, dialogs and transient feedback
- `/settings` — production-shaped form with text, masks, number/date/time/range, select/combo/autosuggest and file inputs

`RouteNodeStateManager` owns navigation state. `CarpenterRouterShell` exposes it through Carpenter runtime, route declarations render pages, and `CarpenterRouteInformationSync` keeps browser URLs and history synchronized.

## Hotkeys

The same `CarpenterCommand` instances drive both sidebar items and keyboard shortcuts:

- `Ctrl+1` / `Cmd+1` — overview
- `Ctrl+2` / `Cmd+2` — projects
- `Ctrl+3` / `Cmd+3` — operations
- `Ctrl+4` / `Cmd+4` — planning
- `Ctrl+5` / `Cmd+5` — explorer
- `Ctrl+,` / `Cmd+,` — settings
- `Ctrl+Shift+N` / `Cmd+Shift+N` — notification

## State ownership

The example intentionally keeps meaningful values controlled by page state. Kanban and reorderable collections emit move details; the page updates its lists. Tree expansion and selection are caller-owned. Form values are caller-owned, while transient picker and dropdown visibility stays inside Carpenter unless explicitly controlled.

## Loading

The root shell contains an application `LoadingBoundary`; page operations call `context.loading.track(...)` and appear as progress in the header. Some cards create nested boundaries to demonstrate nearest-scope interception and local overlays.
