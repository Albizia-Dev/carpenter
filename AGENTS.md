# AGENTS.md

# Carpenter agent contract

This file defines how coding agents must work inside the Carpenter repository.

Carpenter is a standalone Flutter UI-platform package for desktop, web, and mobile. It is not an application feature package and not a thin collection of restyled Flutter widgets. Its job is to provide a stable semantic language for visual roles, interaction, structured data presentation, adaptive screen regions, and reusable page patterns.

The architecture is intentionally restrictive. A locally convenient shortcut that weakens the semantic model is not an improvement.

## 1. Instruction priority

When instructions conflict, use this order:

1. The explicit task from the project owner.
2. Accepted architecture decisions and ADRs in the repository.
3. This `AGENTS.md`.
4. Existing implementation details.
5. General framework conventions.

Existing code is evidence of the current state, not proof that an existing pattern is architecturally correct.

Do not change this file unless the task explicitly asks for it.

### 1.1. Owner-mandated execution restrictions

Agents must never run golden tests, update golden baselines, create or inspect
screenshots, or manually operate the application through UI, browser, or
computer-use tooling unless the project owner explicitly revokes this rule in a
later request.

This restriction has priority over task documents, definitions of done,
verification checklists, skill instructions, tool suggestions, and any other
generic instruction to perform visual validation. Use formatting, static
analysis, and non-golden automated tests for verification instead.

## 2. Repository scope

This repository is the `carpenter` project itself.

Do not create sibling packages, a monorepo, workspace packages, application modules, backend services, or infrastructure repositories unless the task explicitly asks for that change.

The current source tree is organized around:

```text
lib/
├── carpenter.dart
└── src/
    ├── foundation/
    ├── components/
    │   ├── basic/
    │   ├── behaviour/
    │   ├── collections/
    │   ├── dataviz/
    │   └── layout/
    │       ├── regions/
    │       └── patterns/
    └── internal/
```

Preserve this architecture. Do not reorganize directories merely because another layout would be personally preferable.

A file already existing in the tree does not mean the feature must be implemented now. Placeholder files express planned structure, not automatic work items.

## 3. Primary architectural model

The conceptual dependency stack is:

```text
foundation
    ↓
basic
    ↓
behaviour
    ↓
collections / dataviz
    ↓
layout
    ↓
layout/patterns
    ↓
application/domain
```

Carpenter contains everything above `application/domain`. Application and domain code do not belong in this repository.

A layer may depend on lower-level layers. It must not depend upward.

Practical rules:

- `foundation` must not import Carpenter component layers.
- `basic` may depend on `foundation`.
- `behaviour` may depend on `foundation` and `basic`.
- `collections` may depend on `foundation`, `basic`, and `behaviour`.
- `dataviz` may depend on `foundation`, `basic`, and reusable behaviour where necessary.
- `layout` may compose lower layers.
- `layout/patterns` may compose all lower Carpenter layers.
- same-level cross-dependencies must have a clear semantic reason and must not create cycles.
- `internal` is not an escape hatch for violating layer direction.

If placement is ambiguous, put the abstraction in the lowest layer that can own its semantics without importing upward.

## 4. What Carpenter is not

Do not add application or infrastructure responsibilities to core Carpenter.

Carpenter is not:

- a domain model;
- an ORM;
- a repository implementation;
- an HTTP, REST, GraphQL, gRPC, or WebSocket client;
- a dependency-injection container;
- a state-management framework;
- an application router;
- an application permission model;
- a persistence layer;
- a generic layout DSL;
- a storage place for arbitrary colors, radii, sizes, spacing, or durations;
- a wrapper around every Flutter class.

Core Carpenter must not know entities such as:

```text
Payment
Contract
Conversation
User
Task
Tenant
Repository
HttpClient
Database
```

Domain entities remain in applications. Carpenter provides generic ways to render and interact with data.

## 5. Layer ownership

### 5.1. `foundation`

Owns the language used by the rest of Carpenter:

- semantic roles;
- theme contracts;
- actions and commands;
- accessibility foundations;
- breakpoints;
- input capabilities;
- common UI state contracts;
- density;
- shape;
- size;
- spacing semantics;
- typography;
- motion;
- elevation and layers;
- generated token/theme output.

Foundation code must be domain-neutral and component-neutral.

### 5.2. `components/basic`

A basic component has one local UI meaning.

Examples:

```text
Button          invokes an action
Select          selects a value
StatusIndicator communicates status
Card            groups one semantic block
TextArea        edits multiline text
```

A basic component may be internally composite, but its responsibility must remain singular.

Do not create accidental mini-applications such as components that combine unrelated filtering, pagination, status, actions, and navigation.

### 5.3. `components/behaviour`

Owns reusable interaction mechanisms that may be shared by different visual components.

Examples:

- overlay;
- selection;
- disclosure;
- drag-and-drop;
- reorder;
- resize;
- inline editing;
- clipboard;
- undo;
- loading mechanisms;
- focus trapping;
- virtualization;
- command palette infrastructure.

Behaviour must not be welded permanently into one table, list, tree, or kanban implementation if the same interaction can be reused elsewhere.

### 5.4. `components/collections`

Owns representation and editing of structured sets or structured objects.

Examples:

- list;
- data list;
- table;
- data grid;
- tree;
- tree table;
- form;
- definition list;
- card collection;
- filter bar;
- pagination;
- timeline;
- kanban.

Collection contracts must not assume one persistence or pagination backend.

### 5.5. `components/dataviz`

Owns quantitative, temporal, categorical, and relational visualization.

Public chart contracts must be backend-neutral.

Chart engines are renderers/adapters, not the Carpenter API.

### 5.6. `components/layout`

Owns semantic screen regions and their adaptive presentation.

Examples:

- application shell;
- primary region;
- navigation region;
- secondary region;
- auxiliary region;
- detail region;
- tools region;
- notification region;
- overlay region;
- adaptive region;
- split view;
- toolbar;
- page header.

### 5.7. `components/layout/patterns`

Owns task-oriented page conventions.

Patterns are allowed to define:

- placement of actions;
- placement of filters;
- detail presentation;
- mobile adaptation;
- required empty/error/loading states;
- keyboard behaviour;
- page-level composition.

Patterns are part of the design system, not application-specific screens.

### 5.8. `internal`

Contains implementation helpers only:

- diagnostics;
- geometry;
- rendering helpers;
- utilities.

Nothing under `src/internal` is public API.

Do not put public contracts in `internal` merely to avoid deciding where they belong.

## 6. Controlled-first is mandatory

Public interactive components are controlled-first:

```text
state in
events out
```

Meaningful state belongs to the caller unless there is a strong reason otherwise.

State that normally belongs outside the component:

- selected entity or selected keys;
- search query;
- filters;
- sort;
- pagination state;
- persistent expansion state;
- form data;
- dirty state;
- workflow step;
- loading/error/freshness state;
- permissions;
- mutation state.

State that may remain internal because it is ephemeral:

- hover;
- focus;
- pressed state;
- pointer capture;
- animation progress;
- overlay geometry;
- drag preview geometry;
- temporary tooltip visibility.

Do not hide meaningful state inside a widget if the application may need to:

- serialize it;
- restore it;
- put it in a URL;
- synchronize it;
- test it;
- persist it;
- share it with another view.

For simple components, prefer ordinary callbacks.

For compound components and page patterns, typed event unions are acceptable.

Do not create an event hierarchy for every button click merely because sealed classes exist.

## 7. State-management boundaries

Core Carpenter must not depend on:

- Bloc;
- Cubit;
- Riverpod;
- `WidgetRef`;
- `AsyncValue`;
- Drift;
- generated Drift tables;
- repositories;
- application notifiers.

The intended boundary is:

```text
Carpenter
    rendering
    interaction contracts
    UI events

application state layer
    feature state
    workflows
    mutations

composition layer
    dependency construction
    lifecycle
    shared dependencies

repository
    domain-facing data access

persistence
    local storage and queries
```

Adapters for external state-management systems may exist outside the core when explicitly introduced, but backend-specific types must not leak into the core public API.

Do not add a `provider`, `bloc`, `cubit`, `ref`, `repository`, or database object to a core component constructor.

## 8. Async and mutation state

Do not reduce all asynchronous behaviour to one `bool isLoading`.

Distinguish, where relevant:

- initial;
- initial loading;
- ready;
- refreshing;
- loading more;
- empty;
- zero results;
- failed;
- stale;
- syncing;
- offline;
- conflicted.

When refreshing existing usable data, prefer preserving the previous data instead of replacing the whole region with a blank loader.

For item-level mutations, model independent creation, update, deletion, and failure state when multiple operations may overlap.

For collections, do not use one global loading flag when rows or regions can mutate independently.

One-shot effects such as navigation, dialogs, and toasts are not permanent boolean state.

## 9. Collection contracts

Collection APIs are UI contracts, not database contracts.

Do not assume:

- offset pagination is always available;
- `pageNumber` always exists;
- total count is always known;
- all selected rows are locally loaded;
- the backend is Drift;
- the backend returns results synchronously.

Collection contracts must be able to represent, when relevant:

- offset pagination;
- cursor pagination;
- keyset pagination;
- progressive loading;
- unknown total;
- live updates;
- position restoration;
- server-side select-all;
- stable item keys.

Use stable keys for collection items.

Do not key mutable collection state by list index when an entity key exists.

For query changes, protect against stale/late results when asynchronous or stream-backed adapters are involved.

## 10. Semantic roles, not raw styling

Components request semantic meaning. They do not request arbitrary physical values.

Do not add standard public parameters such as:

```text
backgroundColor
hoverColor
borderColor
textColor
padding
height
width
borderRadius
textStyle
duration
zIndex
```

when the value can be expressed by a semantic role, size, shape, density, spacing role, layer, or theme contract.

Escape hatches may exist only where they are structurally necessary, for example:

```text
itemBuilder
cellBuilder
emptyBuilder
overlayBuilder
formatter
renderer
```

Do not turn every component into `style: dynamic`.

## 11. Domain-scoped role families

Do not create one universal color-role enum.

At minimum, keep these semantic families distinct:

- action;
- layout;
- content;
- field;
- feedback;
- navigation;
- selection;
- focus;
- dataviz.

Similar enum values do not mean the families are interchangeable.

For example, `danger` in an action family and `danger` in feedback are different contracts with different contrast pairs and different usage rules.

### 11.1. Actions

Action meaning and visual prominence are separate axes.

Conceptually:

```text
ActionColorRole
    × ActionProminence
    × ActionColorSlot
    × WidgetState
    × brightness
    × contrast
```

Do not encode visual emphasis into the semantic action role.

`danger` does not imply high prominence.

`primary` identifies a semantic/color family, not automatically the most important button.

Normally, one local action scope should not contain multiple competing high-prominence actions without a specific reason.

Do not use status colors as decorative confetti.

Color must not be the only carrier of meaning.

### 11.2. Widget state versus operation state

Use Flutter `WidgetState` for interaction states such as:

- hovered;
- focused;
- pressed;
- dragged;
- selected;
- disabled;
- error where applicable.

Do not abuse widget state for business execution.

An operation phase such as:

```text
idle
running
succeeded
failed
```

is a separate concept.

## 12. Tokens and theme

The token architecture is:

```text
primitive tokens
    ↓
semantic foundation tokens
    ↓
domain role tokens
    ↓
component tokens
    ↓
runtime resolved theme
```

Component-specific tokens are a last resort. Before adding one, verify that the value cannot honestly be expressed by an existing domain role.

Do not create increasingly specific token names merely to encode one widget's current implementation.

Bad direction:

```text
button.primary.background.hovered.dark.compact.special
```

Preferred direction:

```text
action.primary.high.background.hovered
```

### 12.1. Canonical token source

DTCG JSON is the canonical token representation.

YAML may be an authoring input, but YAML and JSON must not independently define the same source of truth.

Do not create a second competing token source.

### 12.2. Generated files

Files under generated output, including `.g.dart` files, are generated artifacts.

Do not hand-edit generated output.

Change the source model or generator and regenerate.

If the required generator does not exist yet, do not fake generated output by manually maintaining files that claim to be generated. Implement the generator/source path as part of the explicit task or report the missing prerequisite.

Generated output must be deterministic and stably ordered.

### 12.3. Theme access

Components should resolve Carpenter theme data through the Carpenter theme facade.

Do not scatter direct `Theme.of(context).extension<T>()` lookups through components when `CarpenterTheme.of(context)` owns that access.

Do not read palette primitives directly in normal component rendering when a semantic role exists.

Dark theme is not implemented by reversing a light palette.

High contrast is a first-class mode, not an afterthought.

## 13. Layout rules

Carpenter must not become a public wrapper layer around:

```text
Row
Column
Padding
SizedBox
Gap
Stack
Wrap
```

Flutter layout primitives are allowed internally where appropriate.

Do not expose generic Carpenter layout primitives simply to prevent application developers from using Flutter.

Public layout abstractions must carry semantic meaning.

Examples of semantic meaning:

- application shell;
- navigation region;
- detail region;
- auxiliary inspector;
- master-detail relationship;
- page header;
- task-oriented page pattern.

Do not add a public `CarpenterGap(13)` or equivalent arbitrary spacing escape hatch.

## 14. Adaptive behaviour

Responsive behaviour must be based on semantics, viewport class, and input capabilities rather than platform-name checks.

Do not build core behaviour around:

```dart
Platform.isWindows
Platform.isAndroid
isMobile
```

when the real question is:

- viewport class;
- touch capability;
- precise pointer capability;
- hover support;
- hardware keyboard availability;
- region purpose.

Different semantic regions may adapt differently at the same viewport width.

Examples:

```text
inspector:
    wide    -> side panel
    compact -> bottom sheet

master-detail detail:
    wide    -> adjacent region
    compact -> route/full screen

navigation:
    wide    -> sidebar/rail
    compact -> drawer/bottom navigation
```

Do not duplicate local breakpoint logic in every component when an adaptive region policy should own the decision.

## 15. Behaviour infrastructure must be shared

Do not implement independent ad hoc versions of the same behaviour in every component.

Examples:

- table selection and tree selection should build on shared selection contracts where possible;
- menu, popover, tooltip, dialog, flyout, and autosuggest should not each invent unrelated overlay geometry and dismissal logic;
- kanban reorder and tree reorder should reuse drag/reorder infrastructure where their semantics overlap;
- split view and resizable panels should reuse resize contracts;
- toast presentation should use a toaster/controller/region model rather than arbitrary overlay insertion.

A local implementation is acceptable only when the behaviour is genuinely component-specific.

## 16. Overlay rules

Overlay infrastructure is responsible for behaviour such as:

- anchoring;
- positioning;
- collision handling;
- flip/shift;
- safe areas;
- focus;
- outside dismissal;
- Escape;
- restoration;
- semantics;
- layer ordering;
- nested overlays.

Do not solve these separately in every overlay-based component.

Low-level Flutter overlay mechanisms may be used internally but should remain behind Carpenter contracts.

## 17. Actions and commands

A logical action may be rendered in multiple places:

- button;
- menu item;
- context menu;
- toolbar;
- overflow;
- mobile action area;
- command palette;
- keyboard shortcut.

When the same logical action appears in several presentations, prefer a shared action descriptor rather than duplicating label, enabled state, shortcut, semantic role, and invocation logic.

Keep these concepts distinct:

- action semantic role;
- action prominence;
- placement priority;
- action kind;
- execution phase.

Do not make a descriptor a controller. A controller owns imperative operations; a descriptor describes an action.

Icon-only actions require an accessible semantic label.

## 18. External libraries and rendering engines

External libraries may provide rendering engines or platform integration.

Their types must not define Carpenter's semantic API.

Do not expose types such as:

```text
PlutoColumn
FlSpot
GraphicMark
CartesianSeries
ReactiveForm
FormControl
WidgetRef
AsyncValue
DriftTable
backend-specific DropRegion
```

from public Carpenter constructors, fields, callbacks, events, state, or exported models.

Wrap external engines behind:

- adapters;
- renderers;
- backend-neutral descriptors;
- backend-neutral events.

Do not add a new dependency solely because it makes one local implementation shorter.

Before adding or pinning an external package as part of an explicit task, check:

- Flutter/Dart SDK compatibility;
- license;
- maintenance state;
- required platforms;
- transitive impact;
- whether its types can remain isolated.

Prefer borrowing difficult rendering/platform integration over reimplementing it, while keeping Carpenter's public contract independent.

## 19. Public API

The public package surface is exported deliberately through:

```text
lib/carpenter.dart
```

Do not export `src/internal`.

Do not make a type public merely because another internal file needs it.

Do not leak backend-specific or application-specific types into public signatures.

Token names are API.

Public semantic names are API.

Breaking them is a breaking change even when runtime behaviour appears unchanged.

### 19.1. Naming

Use these naming rules unless the explicit task requires otherwise:

- enum type names are singular;
- state objects end in `State`;
- events use past/requested semantic names such as `SearchChanged` and `RefreshRequested`;
- callbacks use conventional names such as `onChanged`, `onPressed`, and `onEvent`;
- imperative objects may be named `Controller`;
- declarative rule objects may be named `Policy`;
- external integration objects may be named `Adapter`;
- backend rendering implementations may be named `Renderer`;
- descriptors must not be mislabeled as controllers.

Prefer named constructors for real semantic variants.

Good:

```dart
CarpenterProgress.determinate(...)
CarpenterProgress.indeterminate(...)
CarpenterButton.toggle(...)
```

Bad:

```dart
CarpenterButton.red()
CarpenterButton.blue()
```

## 20. API stability and legacy code

Treat stability deliberately:

```text
experimental
beta
stable
deprecated
```

Do not silently treat a new component as stable merely because it compiles.

When changing an established public API:

- preserve compatibility when it is cheap and does not corrupt the new architecture;
- use deprecation paths for renames when appropriate;
- do not keep a bad abstraction forever merely to preserve an internal implementation detail;
- do not make breaking changes outside the task scope;
- document migration when the public contract changes.

Existing legacy code may violate current architecture. Do not reproduce a legacy violation in new code merely for consistency.

At the same time, do not launch a repository-wide migration while implementing one focused task.

Migrate only the necessary dependency path unless broader migration is explicitly requested.

## 21. Component admission rules

Do not create a new design-system component merely because one screen needs a local widget.

Before adding a new public component, determine:

1. What user task does it represent?
2. Why are existing components or composition insufficient?
3. Which layer owns it?
4. What state is controlled?
5. What state is internal?
6. What events exist?
7. What keyboard contract exists?
8. What accessibility semantics exist?
9. How does it adapt?
10. Which semantic roles/tokens does it require?
11. Does it need an external backend?
12. What is the migration path for overlapping existing APIs?

A stable component ultimately requires multiple real use cases. Do not over-generalize from one hypothetical screen.

## 22. Component specification template

When introducing or substantially redesigning a component, its implementation and tests must make these aspects explicit:

```text
Purpose
Use when
Do not use when
Anatomy
Slots
Semantic roles
Controlled state
Internal state
Events
Keyboard
Accessibility
Adaptive behaviour
Composition
Theming
Test matrix
```

This does not require creating a separate Markdown document for every change unless the task asks for documentation. It does require the code and tests to embody these decisions instead of leaving them accidental.

## 23. Accessibility is part of correctness

Accessibility is not optional polish.

Interactive components must consider, where applicable:

- semantic label;
- role/semantics;
- keyboard focus;
- visible focus;
- minimum interactive target;
- screen-reader output;
- high contrast;
- reduced motion;
- text scaling;
- non-color status distinction.

Specific rules:

- icon-only actions require semantic labels;
- tooltip text does not replace an accessible label;
- status must not be expressed only by color;
- menu items require readable labels;
- interactive charts require an accessible data representation;
- focus styling must remain distinguishable from surrounding colors.

Do not remove semantics merely to simplify a golden test.

## 24. Keyboard behaviour is part of correctness

Interactive controls must support the keyboard interactions appropriate to their semantic role.

Relevant interactions may include:

```text
Tab / Shift+Tab
Enter / Space
Arrow keys
Home / End
PageUp / PageDown
Escape
context-menu key
Ctrl/Cmd+A
Ctrl/Cmd+C
Ctrl/Cmd+V
Delete
documented shortcuts
```

Do not implement every key for every component. Implement the keys appropriate to the component's role and document/test the contract.

Mouse-only interaction is incomplete for a desktop-capable Carpenter component unless the component is explicitly non-interactive.

## 25. Testing rules

Every behavioural change must have tests at the level where the behaviour is owned.

Do not rely only on visual inspection.

### 25.1. Interactive widget tests

Test applicable states and inputs:

- pointer;
- touch;
- keyboard;
- focus;
- disabled;
- read-only;
- selected;
- error;
- loading/busy;
- semantics;
- callbacks/events;
- restoration.

Not every component has every state. Test the states it actually exposes.

### 25.2. Golden tests

Golden coverage should consider relevant dimensions:

- light/dark;
- standard/high contrast;
- compact/comfortable/spacious density;
- text scales such as 1.0, 1.3, and 2.0;
- LTR/RTL;
- compact/medium/wide width;
- rest/hover/focus/pressed/selected/disabled/loading/error.

Do not create the full Cartesian product blindly.

Use pairwise coverage plus explicitly critical combinations.

### 25.3. Content stress

For components affected by content length or data scale, test applicable cases such as:

- empty text;
- long text;
- long unbroken words;
- Cyrillic;
- Latin;
- numeric content;
- RTL;
- emoji;
- 200% text scale;
- missing images;
- slow loading;
- duplicate items;
- 0/1/1000 items.

### 25.4. Token/compiler tests

When working on token generation, test:

- schema validation;
- alias resolution;
- cycle detection;
- missing tokens;
- duplicate output names;
- deterministic generation;
- stable sorting;
- invalid numeric output;
- source locations in diagnostics.

### 25.5. Palette tests

When working on color generation/theme resolution, test applicable properties:

- monotonic lightness;
- target gamut;
- unintended hue jumps;
- neutral chroma limits;
- stable seed output;
- contrast pairs;
- focus ring contrast;
- dark theme;
- high contrast;
- Delta E diagnostics;
- categorical color distinguishability.

### 25.6. Performance-sensitive components

For tables, trees, data grids, large collections, drag operations, and charts, avoid implementations whose cost obviously scales with the entire dataset on every frame.

When a task affects performance-sensitive paths, consider:

- first layout;
- scroll frame time;
- rebuild count;
- memory;
- large model counts;
- resize behaviour;
- expansion behaviour;
- theme switching;
- lookup cost.

Do not optimize by sacrificing semantic correctness or accessibility without evidence.

### 25.7. Widgetbook

Widgetbook is Carpenter's interactive visual specification, not a collection of
static examples. Every new public visual component must provide:

- one primary interactive `Playground`;
- controls for every public semantic parameter that a consumer can reasonably
  vary;
- separate use cases only for structurally important states, edge cases, and
  accessibility cases;
- shared addons for environment-wide concerns instead of repeating equivalent
  knobs in each use case;
- concise human-readable names for controls and values;
- imports through `package:carpenter/carpenter.dart` only.

The preferred component tree is `Playground`, `States`, `Edge cases`, and
`Accessibility`, omitting categories that add no useful coverage. Do not create
one story for every parameter combination. A developer must be able to explore
text, semantic role, prominence, size, optional content, curated icons, icon
position, execution phase, and other relevant public axes without editing Dart
source.

Use the controls supplied by the installed Widgetbook version. Prefer segmented
controls for small enums, dropdowns for larger enums and curated icon sets, text
or multiline inputs for strings, boolean controls for switches, and numeric
controls only for genuinely numeric public parameters. Optional values must be
explicitly switchable. Present semantic labels such as `Primary`, not Dart
implementation names such as `ActionColorRole.primary`. Keep labels consistent
across components and, where native grouping is unavailable, use clear ordered
labels instead of building a custom controls framework.

Theme mode, high contrast, text scale, viewport, semantics inspection, and
locale belong to global addons when supported by the installed version. A theme
addon must switch the actual Carpenter theme. Use one shared preview/app wrapper
for repeated theme and units setup.

Widgetbook is an external consumer of Carpenter. Code under `widgetbook/` must
not import `package:carpenter/src/...`, and Carpenter production APIs must not be
changed to force hover, focus, press, or other debug-only states. Real
interaction states are exercised through pointer, focus, and keyboard input; a
non-exported Widgetbook-side test harness may be used only where automated state
rendering genuinely requires it.

Any public visual API change must update its Playground. Any new semantic axis
that affects rendering must be exposed there when varying it is meaningful to a
consumer. A visual component is incomplete when it lacks a Playground, requires
source edits to explore key parameters, explodes variants into repetitive
stories, relies on Carpenter internals, or adds production debug API solely for
Widgetbook.

## 26. Static-analysis intent

The codebase is expected to move toward rules equivalent to:

### Foundation

```text
no_raw_color_in_component
no_raw_radius_in_component
no_raw_spacing_in_component
no_raw_duration_in_component
no_direct_palette_token_in_app
prefer_domain_role
no_global_color_role
```

### Components

```text
use_carpenter_text
use_carpenter_button
use_carpenter_icon
use_carpenter_input
use_carpenter_dialog
use_carpenter_menu
use_carpenter_progress
use_carpenter_page
use_carpenter_theme
```

### Architecture

```text
no_component_imports_upward
no_backend_type_in_public_api
no_repository_in_component
no_bloc_in_core_component
no_riverpod_in_core_component
no_drift_in_ui
no_widget_in_descriptor_model
prefer_controlled_component
prefer_stable_item_key
no_global_loading_bool_for_collection
```

### Accessibility

```text
icon_button_requires_semantic_label
interactive_component_requires_action
tooltip_cannot_replace_label
no_color_only_status
menu_item_requires_label
chart_requires_accessible_data
```

Even if a lint does not exist yet, do not deliberately write code that violates its intended architectural rule.

Do not disable an existing lint to make a task pass unless the task is explicitly about correcting the lint rule itself.

Automatic fixes must not guess semantic roles when the code does not provide enough evidence.

## 27. Generated and formatted code

Do not manually edit generated files.

Do not commit formatting noise across unrelated files.

Format changed Dart files using the repository's normal formatter.

Preserve deterministic ordering in generated output and public exports.

If code generation is involved, use the repository-defined generation command. Inspect project configuration instead of inventing a new command.

### 27.1. Carpenter package releases

Published release history is append-only. Never rewrite, merge, reword, or
otherwise alter an existing version section in `CHANGELOG.md`; describe new
work in a newly appended version section.

Every change to `carpenter_units` or `carpenter_mordant` requires a new package
version. Before Carpenter consumes that version, validate the package, complete
its release checks, and publish the exact version. Carpenter dependency
constraints must then reference the published version rather than relying on an
unreleased sibling checkout. Local overrides are allowed only for development
and verification before publication.

## 28. Verification before completion

Before reporting a coding task as complete:

1. Format changed source files.
2. Run the relevant analyzer.
3. Run focused tests for the changed area.
4. Run broader package tests when the change affects shared contracts or foundation code and the repository environment permits it.
5. Verify generated output is current when generation is involved.
6. Verify public exports when adding or moving public API.
7. Check that no backend/application type leaked into public signatures.
8. Check that layer direction remains valid.
9. Check keyboard and accessibility behaviour for interactive changes.
10. Check light/dark and relevant responsive states for visual changes.

Prefer repository-defined scripts when they exist.

Typical Flutter commands are only fallbacks:

```sh
dart format <changed files>
flutter analyze
flutter test
```

Do not claim a check passed if it was not run.

If a check cannot run because of environment or an unrelated repository failure, report that fact separately from the implementation result.

Do not hide unrelated pre-existing failures by changing unrelated code.

## 29. Work discipline

### 29.1. Before editing

Before changing code:

1. Read the target file.
2. Read directly related contracts, theme roles, and tests.
3. Check `lib/carpenter.dart` if public API may change.
4. Check for an existing abstraction before creating a new one.
5. Identify the architectural layer.
6. Identify whether the task requires a lower-level prerequisite.

Do not start by creating new abstractions from the task description alone.

### 29.2. During implementation

Make the smallest coherent change that satisfies the task and preserves architectural direction.

Prefer a vertical working slice over broad speculative scaffolding.

Do not fill unrelated placeholder files.

Do not implement future roadmap items merely because they are adjacent.

Do not rename unrelated public APIs.

Do not introduce a new dependency without a task-level reason.

Do not refactor working unrelated code for style consistency.

Do not silently broaden scope.

### 29.3. If the task reveals a missing prerequisite

Implement the minimum prerequisite required to make the requested slice coherent.

Do not continue recursively through every possible future dependency.

If the missing prerequisite would require a major public contract or architecture decision, avoid inventing a large permanent API. Keep the change narrow and report the decision point.

### 29.4. If architecture and existing code conflict

Prefer the accepted architecture for new code.

Preserve necessary compatibility at the boundary.

Do not spread the legacy pattern into new modules.

Do not perform unrelated cleanup unless it is necessary for the requested change.

## 30. Implementation order

The roadmap is planning information, not permission to implement everything.

The first architectural validation must be vertical:

```text
tokens + roles
    ↓
Button / Input / StatusIndicator / Text
    ↓
Overlay / Menu / Toast
    ↓
collection contracts
    ↓
Table
    ↓
ApplicationShell + AdaptiveRegion
    ↓
ListReport
    ↓
real application integration
```

The purpose of this order is to prove that the semantic foundation works through an actual page.

Do not begin by implementing every planned basic widget.

Do not equate number of implemented files with architectural progress.

For any individual task, follow the same principle: implement the lowest required contracts first, then prove them through the requested higher-level usage.

## 31. Roadmap scope guard

Broad priority groups are:

### P0: structural core

- domain-scoped roles;
- shape/size/spacing/density;
- typography;
- motion;
- elevation/layers;
- breakpoints/capabilities;
- theme access;
- token generation and validation;
- core basic controls;
- overlay/menu/dialog/toast infrastructure;
- core collection contracts;
- list/table/form/tree foundations;
- application shell;
- adaptive region;
- core page patterns;
- Widgetbook/golden/lint infrastructure.

### P1: enterprise core

- data-grid foundation;
- advanced property filtering;
- collection preferences;
- master-detail;
- split collections;
- worklists;
- create/edit flows;
- inline edit;
- undo;
- drag-and-drop;
- file input;
- command palette;
- activity/timeline;
- kanban;
- initial chart set.

### P2: analytics and workflows

- dashboard;
- analytical lists;
- wizard;
- search page;
- comparison;
- calendar/agenda/scheduler/Gantt;
- advanced chart interactions;
- configurable dashboard;
- offline/conflict presentation.

### P3: specialized subsystems

- topology;
- large graphs;
- maps;
- rich text;
- document editor;
- diagram/canvas;
- advanced spreadsheet;
- plugin marketplace;
- design-tool synchronization.

A task in a later priority may be implemented when explicitly requested.

Do not implement later-priority work speculatively while working on P0.

## 32. Do not overbuild

Avoid these failure modes:

- one enum for unrelated semantic domains;
- one mega-theme object with arbitrary maps;
- one component with dozens of boolean feature switches;
- one global loading flag for a complex collection;
- one table type expanded until it is also a spreadsheet;
- one generic `style` object that bypasses semantic roles;
- one `isMobile` branch copied across the codebase;
- one overlay implementation per popup component;
- one backend library becoming the public API;
- one local widget promoted to the design system without repeated use cases;
- one refactor touching the whole repository because a local task exposed an old pattern;
- one folder full of empty architectural promises being mistaken for completed functionality.

Prefer explicit semantic contracts and small composable mechanisms.

## 33. Definition of done for a public component

A public component is not considered mature merely because it renders.

For a stable component, the target criteria are:

- at least two independent real use cases;
- documented semantics;
- complete public states;
- keyboard contract;
- accessibility review;
- light theme;
- dark theme;
- high-contrast behaviour;
- responsive/adaptive behaviour where applicable;
- golden coverage;
- no backend types in public API;
- migration path from overlapping/legacy APIs;
- clear ownership.

For experimental work, not every stable criterion must already be satisfied, but missing criteria must not be concealed by presenting the API as finished.

## 34. Completion report

When finishing a task, report concisely:

- what changed;
- which architectural layer owns it;
- any public API change;
- tests/checks actually run;
- any known unresolved issue or prerequisite.

Do not claim completion by listing files alone.

Do not present speculative future roadmap work as part of the completed task.

# Final invariant

Every Carpenter change should strengthen this chain:

```text
primitive token
    ↓
domain-scoped semantic role
    ↓
component contract
    ↓
reusable behaviour
    ↓
data representation
    ↓
semantic screen region
    ↓
task-oriented pattern
    ↓
domain application
```

If a change makes the application depend more heavily on raw visual values, framework-specific state, backend-specific types, ad hoc responsive branches, or one-off widget composition, it is probably moving in the wrong direction.
