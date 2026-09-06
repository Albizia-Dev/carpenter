# Carpenter Widgetbook

The catalog is executable documentation of Carpenter's public API. Its single
registry is `lib/catalog.dart`; the app and catalog tests use that same object.

## Run and verify

```sh
flutter pub get
flutter run -d chrome
dart analyze lib test
flutter test
flutter build web --release --base-href /carpenter/
```

The interactive run command is for developers; repository automation uses only
static analysis, non-golden widget tests, and builds. Do not add screenshot or
golden tests.

## Catalog conventions

Use the existing groups: Foundation, Basic, Behaviour, Collections, Layout,
Page Patterns, Samples. Each component outside Foundation has exactly one
`Playground`. Additional cases isolate a meaningful contract or compare roles;
they must not duplicate every possible knob combination.

Use the global viewport, theme, density, contrast, units, text scaling, motion,
and semantics controls. The shared theme list covers light/dark, normal/compact,
and normal/high-contrast combinations. Do not add another viewport selector to
a component. Fixed viewport helpers remain available for explicitly named
regression scenarios, not as a competing global environment.

Knobs use semantic labels such as `Content`, `State`, `Appearance`, `Behavior`,
and `Data`. Enum labels go through `semanticValueLabel`; the fallback humanizes
new enum names rather than exposing qualified Dart identifiers.

Stateful examples own and dispose their controllers. Demonstrate real edits,
selection and callbacks, with deterministic fixtures and local fake loaders.
Do not call live services or pretend a decorated error is validation. Use
`package:carpenter/carpenter.dart`, not implementation imports.

The additional primitives, editable table, and validation examples exercise
calendar selection, async options and failure/cancellation, custom field
shells, upload progress, bundled SVG icons, row addition/removal, totals, and
field-validation summaries.

## Coverage status

The public API is larger than the current catalog. This refactor does not claim
that every public widget and state has been covered. Run the documentation audit
from `../tool/documentation` for current counts, evidence and named remaining
debt. Catalog-source references, registration tests and behavioral tests are
separate measurements, not interchangeable percentages.
