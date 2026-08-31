# Carpenter

Carpenter is a semantic, adaptive UI toolkit for Flutter business applications on desktop, web, and mobile.

It provides application shells, commands and hotkeys, loading scopes, typed fields, structured collections, drag-and-drop surfaces, page patterns, semantic theming, and a bundled Gravity UI icon set without requiring Material or Cupertino as the application architecture.

## Status

Carpenter is pre-1.0. The public API is usable, but still evolving as production patterns are extracted and stabilized.

## Installation

```yaml
dependencies:
  carpenter: ^0.1.2
```

Then use the main barrel for components, units, navigation types, and bundled icons:

```dart
import 'package:carpenter/carpenter.dart';
```

## What is included

- application runtime, modules, route rendering, commands, hotkeys, loading scopes, sidebar and root layouts;
- buttons, text, inputs, masks, number/date/time/range/file fields, select, combo box and autosuggest;
- tables, filters, pagination, tabs, breadcrumbs, notifications, trees and tree tables;
- typed drag-and-drop, reorderable collections, Kanban and planning boards;
- record, workflow, explorer and editor-oriented composition patterns;
- semantic themes, roles, adaptive regions, `rem`/`em`/`px` units and bundled Gravity UI SVG icons.

## State model

Meaningful application state stays controlled by the caller. Ephemeral interaction state stays inside Carpenter unless you explicitly opt into controlling it.

For example, a select normally needs only its domain value:

```dart
CarpenterSelect<String>(
  value: status,
  onChanged: (value) => setState(() => status = value),
  label: 'Status',
  options: const [
    CarpenterOption(id: 'draft', value: 'draft', label: 'Draft'),
    CarpenterOption(id: 'active', value: 'active', label: 'Active'),
  ],
)
```

If an application really needs to control dropdown visibility, `open` and `onOpenChanged` remain available.

Ordinary scrollable pages can use `CarpenterPageBody` for standard page padding and rhythm instead of rebuilding the same `ListView` and spacers on every screen.

## Example application

`example/` is a connected workspace, not a component gallery. It demonstrates real composition and caller-owned state across:

- dashboard and loading boundaries;
- searchable/sortable/paginated project tables;
- record details, breadcrumbs and timeline;
- generic reorder and live Kanban drag-and-drop;
- keyboard-friendly hierarchical resource explorer;
- dialogs, toasts, commands and hotkeys;
- a production-shaped form with typed, masked, selectable, date/time and file fields.

Run it with:

```sh
cd example
flutter run
```

See [example/README.md](example/README.md) for routes and shortcuts.

## Widgetbook

`widgetbook/` is the exhaustive development catalog for individual component states, sizes, semantic roles and edge cases. The example application intentionally focuses on realistic workflows instead of duplicating that catalog.

## Development

```sh
flutter pub get
dart analyze lib
flutter test
```

The repository CI also builds the Widgetbook and example web applications and audits the `rem` migration invariants.

## License

See [LICENSE](LICENSE).
