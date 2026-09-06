# Documentation contract

The source of truth is the public namespace exported by `lib/carpenter.dart`.
DartDoc describes its contract; Widgetbook demonstrates executable usage;
consumer skills must verify the installed version before following recipes.

Public documentation should explain purpose, parameter meanings and defaults,
return values, caller/controller ownership, lifecycle, side effects,
constraints, and failure behavior where relevant. Prefer concrete examples and
symbol links over repeating an identifier in prose. Document non-obvious
private contracts, but do not add boilerplate to every private helper.

Generated token and icon declarations are tracked separately. Fix their
upstream generators when needed; never hand-edit generated output.

Widgetbook examples should share taxonomy, environment and fixture conventions.
A controlled component must round-trip its callbacks into example state. Owned
controllers, focus nodes, timers and cancellation signals must be disposed.
Missing states are not excused by a constructor reference elsewhere in a file.

Coverage commands and their limitations are documented in
`../tool/documentation/README.md`. The current baseline explicitly records
unfinished documentation and catalog work. Passing the regression gate does
not mean the full documentation project is complete. Reducing this baseline is
a reviewable part of each documentation change; adding new debt is not the
normal way to fix CI.

Repository rules prohibit screenshot/golden validation. Keep verification in
static analysis, non-golden unit/widget tests, DartDoc generation and web builds.
