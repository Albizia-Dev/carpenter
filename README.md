# Carpenter

Carpenter is a semantic, adaptive UI toolkit for Flutter business applications on desktop, web, and mobile.

It provides application shells, commands and hotkeys, loading scopes, typed fields, structured collections, drag-and-drop surfaces, page patterns, semantic theming, and a bundled Gravity UI icon set without requiring Material or Cupertino as the application architecture.

## Status

Carpenter is pre-1.0. The public API is usable, but still evolving as production patterns are extracted and stabilized.

## Installation

```yaml
dependencies:
  carpenter: ^0.1.8
```

The umbrella import remains supported and is the simplest option for application code that uses Carpenter across layers:

```dart
import 'package:carpenter/carpenter.dart';
```

For packages or features that want a smaller intentional dependency surface, Carpenter also exposes layered entrypoints:

```dart
import 'package:carpenter/foundation.dart';   // roles, theme, units, adaptive primitives
import 'package:carpenter/components.dart';   // + basic controls and behaviours
import 'package:carpenter/collections.dart';  // + collection contracts and views
import 'package:carpenter/layout.dart';       // + shells, regions and page layout
import 'package:carpenter/patterns.dart';     // + page infrastructure and business patterns
import 'package:carpenter/application.dart';  // + runtime, commands, hotkeys and navigation
```

Each higher entrypoint includes the public layers below it, so prefer the lowest layer that owns the concepts a package actually needs. `application.dart` keeps the application-level `yx_navigation` integration; lower UI entrypoints do not expose it accidentally. The existing `carpenter.dart` barrel remains source-compatible.

## What is included

- application runtime, modules, route rendering, commands, hotkeys, sidebar and root layouts;
- framework-neutral loading scopes and asynchronous behaviour primitives;
- buttons, text, inputs, masks, number/date/time/range/file fields, select, combo box and autosuggest;
- tables, filters, pagination, tabs, breadcrumbs, notifications, trees and tree tables;
- typed drag-and-drop, reorderable collections, Kanban and planning boards;
- record, workflow, explorer and editor-oriented composition patterns;
- semantic themes, roles, adaptive regions, `rem`/`em`/`px` units and bundled Gravity UI SVG icons.

## State model

Meaningful application state stays controlled by the caller. Ephemeral interaction state stays inside Carpenter unless you explicitly opt into controlling it.

Carpenter does not require Bloc, Cubit, Riverpod, or another application state-management package. Reusable Carpenter behaviour is exposed through Flutter-native contracts such as `Listenable`, value snapshots, and explicit controllers, and application code is free to adapt those contracts to its own state manager.

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

The repository CI also builds the Widgetbook and example web applications and verifies formatting, analysis, and all non-golden package tests.

## License

See [LICENSE](LICENSE).
