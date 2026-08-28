# Carpenter application example

This example is a small connected workspace rather than a component gallery. It demonstrates Carpenter as an application UI layer around `yx_navigation`.

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

- `/` — overview dashboard
- `/projects` — searchable, sortable and paginated project collection
- `/projects/:id` — record details with metrics, tabs and timeline
- `/operations` — loading aggregation, nested loading boundaries, hotkeys, dialogs and toasts
- `/settings` — controlled form state

`RouteNodeStateManager` owns navigation state. `CarpenterRouterShell` exposes it through Carpenter runtime, `CarpenterRouteRenderer` renders route declarations, and `CarpenterRouteInformationSync` keeps browser URLs/history synchronized.

## Hotkeys

The same `CarpenterCommand` instances drive both sidebar items and keyboard shortcuts:

- `Ctrl+1` / `Cmd+1` — overview
- `Ctrl+2` / `Cmd+2` — projects
- `Ctrl+3` / `Cmd+3` — operations
- `Ctrl+,` / `Cmd+,` — settings
- `Ctrl+Shift+N` / `Cmd+Shift+N` — notification

## Loading

The root shell contains an application `LoadingBoundary`; page operations call `context.loading.track(...)` and appear as progress in the header. Some cards create nested boundaries to demonstrate nearest-scope interception and local overlays.
