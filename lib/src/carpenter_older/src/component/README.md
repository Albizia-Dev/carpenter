# Carpenter component tree

Carpenter - это не UI Kit, не тема и не набор готовых кнопок. Carpenter - это
visual runtime: среда исполнения визуального языка приложения.

Flutter дает runtime для дерева `Widget`. Carpenter дает runtime для визуального
поведения компонентов: цвет, типографику, размеры, радиусы, motion, density,
состояния и семантические роли.

## Главная цепочка runtime host

```text
CarpenterApp
├─ CarpenterConfig
│  └─ Carpenter
│     └─ CarpenterScope
│        └─ BuildContext.face
│           └─ CarpenterFace
│              └─ Component
├─ CarpenterRuntime
│  ├─ CarpenterCoreRuntime
│  ├─ CarpenterRouterRuntime
│  ├─ CarpenterHotkeyRuntime
│  └─ custom typed capabilities
├─ CarpenterShell[]
│  ├─ CarpenterRouterShell
│  ├─ CarpenterHotkeyShell
│  ├─ CarpenterFrameShell
│  └─ custom app shells
├─ CarpenterModule[]
│  ├─ module shells
│  └─ module routes
└─ CarpenterRouteRenderer
   └─ Scope -> Shell -> ... -> Page
```

`CarpenterApp` - runtime host приложения. Он поднимает `WidgetsApp`, создает или
принимает `Carpenter`, кладет его в `CarpenterScope`, компилирует shell-и и
модули, валидирует typed dependencies и рендерит текущее route tree.

Shell-и работают как middleware:

```dart
CarpenterApp(
  shells: [
    CarpenterRouterShell(navigation: navigation),
    CarpenterHotkeyShell(commands: commands),
    CarpenterFrameShell(),
  ],
  modules: [
    CrmModule(),
    WarehouseModule(),
  ],
)
```

Каждый shell объявляет `requires` и `provides`. Shell-и и модули не должны
зависеть от concrete shell instances. Они читают capabilities через typed
runtime registry:

```dart
final router = context.runtime.router;
final hotkeys = context.runtime.hotkeys;
final auth = context.runtime.read<AuthRuntime>();
```

Navigation не является обязанностью Carpenter. `yx_navigation` хранит и меняет
дерево `RouteNode`, а Carpenter только преобразует текущую active chain в
виджеты:

```text
RouteNodeStateManager
└─ RouteNode(root)
   └─ RouteNode(workspace)
      └─ RouteNode(module)
         └─ RouteNode(page)

CarpenterRouteRenderer
└─ RootScope
   └─ RootShell
      └─ WorkspaceScope
         └─ WorkspaceShell
            └─ ModuleScope
               └─ ModuleShell
                  └─ Page
```

`CarpenterConfig` - декларация входных данных. Он ничего не вычисляет сам:
`color`, `type`, `dimension`, `brightness`, `platform`, `locale`. Legacy
`primary`, `accent`, `rem`, `density` остаются коротким путем для дефолтного
runtime.

`Carpenter` - runtime. Он собирается из `CarpenterConfig` и вычисляет остальное:
primitive palette, semantic colors, typography registry, dimension registry и
motion.

`CarpenterFace` - единственное лицо runtime для компонентов. Компонент не должен
знать про `Carpenter`, палитру, тему, Material или платформу напрямую.

```dart
final face = context.face;
```

Не нужно дробить публичный API на плоские расширения:

```dart
context.colors
context.text
context.radius
context.scale
```

Все это должно оставаться за фасадом `Face`.

## База Flutter

```text
Widget (package:flutter/widgets.dart)
├─ StatelessWidget
├─ StatefulWidget
├─ ProxyWidget
│  └─ InheritedWidget
├─ ParentDataWidget
└─ RenderObjectWidget
   ├─ SingleChildRenderObjectWidget
   └─ MultiChildRenderObjectWidget
```

## База Carpenter от widgets.dart

Это дерево не означает глубокое Dart-наследование. В Flutter публичные
компоненты должны оставаться неглубокими: обычно `StatelessWidget` или
`StatefulWidget`. Общая логика живет в runtime, `Face`, контролах, scope,
builders и controllers.

```text
Widget
├─ StatelessWidget
│  └─ CarpenterApp
│     ├─ WidgetsApp
│     ├─ CarpenterScope
│     ├─ CarpenterRuntimeScope
│     ├─ CarpenterShell pipeline
│     └─ CarpenterRouteRenderer
│
├─ InheritedWidget
│  └─ CarpenterScope
│     └─ exposes visual runtime through BuildContext.face
│  └─ CarpenterRuntimeScope
│     └─ exposes typed app runtime through BuildContext.runtime
│
├─ StatelessWidget
│  ├─ face-only components
│  │  ├─ Text
│  │  ├─ Icon
│  │  ├─ Avatar
│  │  ├─ Tag
│  │  ├─ Loader / Spin
│  │  ├─ Progress
│  │  ├─ FilePreview
│  │  ├─ Card
│  │  ├─ DefinitionList
│  │  └─ List
│  │
│  └─ composed controls
│     ├─ Button
│     └─ Link
│
├─ StatefulWidget
│  ├─ CarpenterControl
│  │  └─ shared interactive behavior
│  │     ├─ enabled
│  │     ├─ hovered
│  │     ├─ focused
│  │     ├─ pressed
│  │     ├─ semantics
│  │     ├─ keyboard activation
│  │     └─ pointer gestures
│  │
│  ├─ value controls
│  │  ├─ Checkbox
│  │  ├─ Switch
│  │  ├─ Radio
│  │  ├─ SegmentedRadio
│  │  └─ Slider
│  │
│  ├─ fields
│  │  ├─ Input
│  │  ├─ Select
│  │  ├─ DropdownMenu
│  │  ├─ Calendar input
│  │  └─ Contenteditable
│  │
│  ├─ overlays
│  │  ├─ Overlay
│  │  ├─ Popup
│  │  └─ Dialog / Modal
│  │
│  ├─ composite navigation
│  │  ├─ Tabs
│  │  ├─ Pagination
│  │  └─ Calendar
│  │
│  ├─ data views
│  │  └─ Table
│  │
│  └─ behavior-only
│     └─ Hotkey
│        ├─ CarpenterHotkeyScope
│        ├─ CarpenterHotkeyCommand
│        ├─ CarpenterHotkeyController
│        └─ CarpenterHotkeyDisplay
│
├─ ParentDataWidget
│  └─ slots for composite components
│     ├─ Card header, body, footer
│     ├─ Dialog / Modal header, body, footer
│     ├─ Tabs list, tab, panel
│     └─ Table column
│
└─ RenderObjectWidget
   ├─ SingleChildRenderObjectWidget
   │  ├─ custom measured Input / Contenteditable
   │  └─ custom Overlay / Popup positioning
   └─ MultiChildRenderObjectWidget
      ├─ custom Table layout
      ├─ custom SegmentedRadio layout
      └─ custom Calendar grid layout
```

## Дерево компонентов

Компоненты максимально тупые. Они принимают props, читают `Face` и строят
виджеты. Они не вычисляют палитру, не знают про OKLCH, не ходят в primitive
palette, не зависят от Material и не принимают решений уровня runtime.

```text
Component
├─ Primitive
│  ├─ Text
│  ├─ Icon
│  ├─ Avatar
│  ├─ Tag
│  ├─ Loader / Spin
│  ├─ Progress
│  └─ FilePreview
│
├─ Surface
│  ├─ Card
│  ├─ Overlay
│  ├─ Popup
│  └─ Dialog / Modal
│
├─ Action
│  ├─ Button
│  └─ Link
│
├─ ValueControl
│  ├─ Checkbox
│  ├─ Switch
│  ├─ Radio
│  ├─ SegmentedRadio
│  └─ Slider
│
├─ Field
│  ├─ Input
│  ├─ Select
│  ├─ DropdownMenu
│  ├─ Calendar input
│  └─ Contenteditable
│
├─ Content
│  ├─ DefinitionList
│  ├─ List
│  └─ Table
│
├─ Navigation
│  ├─ Tabs
│  ├─ Pagination
│  └─ Calendar
│
└─ Utility
   └─ Hotkey
      ├─ HotkeyScope
      ├─ HotkeyCommand
      ├─ HotkeyController
      └─ HotkeyDisplay
```

## Цвет

Цвет имеет два слоя, и оба слоя dynamic.

Первый слой - primitive palette. Это сырье runtime, а не основной API
компонентов. Названия шкал и шагов не фиксированы.

```text
primary
accent
neutral
brand
chart.revenue
editor.selection
```

Шаги могут быть любыми:

```text
50 100 200 300 400 500 600 700 800 900 950
soft solid contrast
low normal high
```

Шкалу можно:

- сгенерировать из seed через OKLCH;
- передать целиком;
- передать частично, а недостающее догенерировать;
- переопределить отдельные шаги.

Второй слой - semantic colors. Только этот слой используют компоненты Carpenter.
Semantic roles тоже dynamic и расширяемы.

```text
face.color('surface.base')
face.color('text.primary')
face.color('border.focus')
face.color('action.primary')
face.color('status.danger')
face.color('chart.revenue.up')
```

Компонент не должен писать:

```dart
face.color.palette('primary')('600')
```

Компонент должен писать:

```dart
face.color('action.primary')
```

OKLCH и `okcolor` являются implementation detail генерации палитры. Они не
должны становиться публичной частью Carpenter.

## Типографика

Типографика является dynamic registry. Роли не фиксированы: можно использовать
дефолтные `body`, `body.strong`, `label`, `label.strong`, `caption`, `title`,
а можно добавить любые свои роли:

```text
face.type('display.hero')
face.type('code.inline')
face.type('table.header')
face.type('control.label')
```

`CarpenterTypeConfig` принимает font family, fallback, package, generated scale
и partial overrides.

## Размерности

`rem` - базовая единица системы. Все размеры компонента должны вычисляться через
`Face`.

Компонент не должен писать:

```dart
const EdgeInsets.all(16)
BorderRadius.circular(12)
```

Компонент должен писать в духе:

```dart
EdgeInsets.all(face.space('1'))
BorderRadius.circular(face.radius('control'))
SizedBox.square(dimension: face.size('avatar.hero'))
```

Размерности являются dynamic registry:

```text
face.space('gutter.tight')
face.radius('card.outer')
face.size('control.switch.width')
face.dimension('layout.sidebar')
```

`s/m/l` не являются моделью Carpenter. Это могут быть только user-defined roles,
если конкретному приложению так удобно.

## Роль CarpenterControl

`CarpenterControl` - не родительский класс для всех интерактивных компонентов, а
поведенческий primitive. Его задача - собрать общую механику интерактива:
semantics, focus, hover, pressed, pointer gestures, keyboard activation и
enabled state.

Например:

```text
Button extends StatelessWidget
└─ build
   └─ CarpenterControl
      └─ builder(context, controlState)
         └─ uses context.face
```

Так Button остается простым компонентом, а интерактивная механика не
дублируется.

## Правила реализации

- Публичный компонент наследуется от `StatelessWidget`, если вся его логика
  выводится из props и `Face`.
- Публичный компонент наследуется от `StatefulWidget`, если он хранит focus,
  hover, pressed, opened, selected, editing, validation или animation state.
- Компонент читает только `context.face`.
- Компонент использует только semantic colors, а не primitive palette.
- Компонент использует `face.color('...')`, `face.type('...')`,
  `face.space('...')`, `face.radius('...')`, `face.size('...')`,
  `face.dimension('...')`, `face.motion`, а не голые числа.
- Интерактивные элементы используют `CarpenterControl` для общей
  pointer/focus/keyboard/semantics логики.
- Составные компоненты могут иметь controllers и внутренние scopes, но они не
  должны ломать внешний принцип: дочерние части тоже читают визуальный язык
  через `Face`.
- `RenderObjectWidget` нужен только там, где обычных primitives из
  `widgets.dart` недостаточно: кастомное измерение, позиционирование или layout.
