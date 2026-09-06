# Public API and Widgetbook coverage

This standalone Dart tool inventories the namespace exported by
`lib/carpenter.dart`. It includes public constructors, fields, accessors,
methods, enum values, extensions, typedefs and functions. It follows exports,
`show`/`hide`, conditional exports, export cycles and parts; imported-only
implementation files are not public API. Conditional implementations are
counted conservatively. Normal Dart analysis remains authoritative for
semantic errors such as ambiguous exports.

Generated declarations and external package re-exports have separate counts.
Generated Dart files are not modified to improve the manual documentation score.

## Run

From this directory:

```sh
dart pub get
dart analyze
dart test
dart run bin/audit.dart ../.. --check
```

Reports are written to `build/documentation/` at the repository root:

- `api.json`: stable declaration IDs, signatures, source lines and DartDoc.
- `widgetbook.json`: public widget constructor references reachable through the
  catalog's source import graph, with evidence file paths.
- `coverage.md`: human-readable counts and outstanding widget references.

`--check` compares named debt against `coverage-baseline.json`. New missing
DartDoc, changed undocumented signatures, newly unreferenced widgets, and new
files classified as generated fail. Resolved debt also requires updating the
baseline, so improvements ratchet forward. To update it after review:

```sh
dart run bin/audit.dart ../.. --write-baseline
git diff -- coverage-baseline.json
```

Do not run `--write-baseline` in normal CI or accept new debt merely to make a
check green. The baseline records unfinished work; it is not a permanent
exemption or a claim of completeness.

```sh
dart run bin/audit.dart ../.. --strict
```

`--strict` fails while any owned declaration lacks nonempty DartDoc or any
public widget lacks a catalog-source constructor reference. It deliberately
continues to fail until the documentation backlog is actually addressed.

## What these checks do not prove

A nonempty comment is not necessarily a good contract. Review purpose,
parameters/defaults, return values, ownership, lifecycle, side effects,
constraints and realistic examples. Do not write tautological comments only to
satisfy a counter. Inherited framework overrides are currently counted
explicitly, not silently exempted.

A constructor reference in a reachable source file is not a guarantee that a
registered story renders it. The tool excludes comments and type annotations,
but does not perform semantic call-graph or runtime reachability analysis.
`widgetbook/test/widgetbook_smoke_test.dart` independently checks the actual
registry, group and use-case uniqueness, canonical playgrounds, and the shared
environment. `documentation_examples_test.dart` tests new executable fixtures.
Infrastructure widgets may be covered compositionally rather than receiving
standalone visual stories; remaining omissions require individual review.

Neither check replaces interaction, accessibility, layout, or state-coverage
tests. Repository policy forbids golden and screenshot workflows; use the
non-golden tests and builds instead.
