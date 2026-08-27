# Carpenter UI System

## Архитектурная спецификация компонентной UI-платформы для Flutter

**Статус:** базовая архитектура v1
**Дата:** 23 августа 2026 года
**Целевая среда:** Flutter для desktop, web и mobile
**Основной формат токенов:** DTCG Design Tokens
**Основное цветовое пространство:** OKLCH

---

# 0. Назначение документа

Carpenter должен быть не очередной библиотекой, в которой человечество в сто сорок седьмой раз реализовало кнопку, поле ввода и карточку с немного другим радиусом.

Его задача шире:

1. Задать единый язык визуальных, интерактивных и компоновочных решений.
2. Ограничить произвольную стилизацию там, где она разрушает системность.
3. Разделить базовые компоненты, переиспользуемое поведение, представления данных, визуализацию, экранные регионы и типовые страницы.
4. Предоставить UI-контракты, не зависящие от Bloc, Cubit, Riverpod, Drift, REST, GraphQL и конкретной доменной модели.
5. Одинаково хорошо работать на desktop, web и mobile.
6. Позволять заменять низкоуровневые движки таблиц, графиков, форм и drag-and-drop без изменения публичного Carpenter API.
7. Генерировать палитры, роли, темы, документацию и тестовые отчёты из единого набора design tokens.
8. Уменьшать количество архитектурных велосипедов, а не только гарантировать, что у всех велосипедов одинаково закруглены педали.

В качестве методологических ориентиров используются:

* **Intercom Full Stack Design System:** одинаковые атомы ещё не создают одинаковый продукт.
* **GitLab Pajamas:** foundations, components, behaviour/directives, patterns, objects и data visualization являются разными уровнями системы.
* **AWS Cloudscape:** table, cards и split view выбираются исходя из пользовательской задачи и структуры данных.
* **SAP Fiori:** generic layouts отделяются от типовых floorplans рабочих страниц.
* **Elastic UI:** визуализация данных рассматривается как самостоятельная система.
* **Gravity UI:** компонентная библиотека расширяется отдельными системами таблиц, форм, навигации, графиков, dashboard-компоновки и других крупных областей.

В документе используются нормативные слова:

* **ОБЯЗАН**: требование архитектуры.
* **СЛЕДУЕТ**: рекомендуемое решение, от которого допустимо отступить с обоснованием.
* **МОЖЕТ**: разрешённый вариант.

---

# 1. Главная модель Carpenter

```text
foundation
    язык системы:
    токены, роли, темы, размеры, состояния, действия

basic
    компонент с одним локальным UI-смыслом

behaviour
    переиспользуемое взаимодействие или механизм состояния

collections
    представление и редактирование структурированных данных

dataviz
    визуальное представление количественных, временных
    и связных данных

layout
    семантические регионы экрана и их адаптация

layout/patterns
    готовые способы решать пользовательские задачи
    и строить типовые страницы

application/domain
    бизнес-сущности, use cases, маршрутизация,
    разрешения и данные
```

## 1.1. Направление зависимостей

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
patterns
    ↓
application
```

Допустимы зависимости вниз. Зависимости вверх запрещены.

Примеры:

* `CarpenterButton` может использовать action theme из `foundation`.
* `CarpenterTable` может использовать `CarpenterCheckbox`, selection behaviour и collection contracts.
* `CarpenterListReport` может использовать table, filter bar, page header и pagination.
* `CarpenterButton` не может импортировать `CarpenterTable`.
* `CarpenterTable` не может импортировать `PaymentsCubit`.
* `foundation` не может знать, что такое платёж, договор или пользователь.

## 1.2. Что Carpenter не делает

Carpenter не является:

* доменной моделью;
* ORM;
* слоем доступа к данным;
* transport client;
* dependency injection container;
* state-management framework;
* универсальным layout DSL из `Row`, `Column`, `Padding` и `Gap`;
* хранилищем произвольных цветов, размеров и радиусов;
* попыткой скрыть весь Flutter за собственными абстракциями.

Carpenter не содержит `Payment`, `Contract`, `Conversation`, `User` или `Task`.

Он предоставляет способы единообразно представить объект:

```text
ObjectHeader
DefinitionList
AttributeEditor
ObjectPage
CollectionView
ActivityFeed
SearchResult
DetailRegion
```

Доменные сущности остаются на уровне приложения.

---

# 2. Архитектурные принципы

## 2.1. Controlled-first

Публичные компоненты по умолчанию работают по модели:

```text
state in
events out
```

```dart
CarpenterSelect<PaymentStatus>(
  value: state.status,
  options: statuses,
  onChanged: cubit.statusChanged,
);
```

Компонент не должен тайно владеть значимым состоянием, которое невозможно:

* восстановить;
* сериализовать;
* положить в URL;
* сохранить между сессиями;
* протестировать;
* синхронизировать с другими представлениями.

Внутри компонента остаются эфемерные состояния:

```text
hover
focus
pressed
animation progress
pointer capture
drag preview geometry
overlay position
tooltip visibility
```

Наружу выносятся:

```text
selected entity
filters
search
sorting
pagination
form data
dirty state
workflow step
expanded tree nodes, если они сохраняются
loading/error/freshness
permissions
mutations
```

## 2.2. Один локальный смысл на basic-компонент

Basic-компонент может быть составным, но у него должна быть одна функция.

```text
Button          запускает действие
Select          выбирает значение
StatusIndicator показывает состояние
Card            оформляет один смысловой блок
TextArea        редактирует многострочный текст
```

`ButtonWithDropdownAndPaginationAndStatus` не является basic-компонентом. Это уже маленькая административная единица со своим бюджетом.

## 2.3. Поведение отделяется от представления

Selection, drag-and-drop, resize, disclosure, inline edit, undo и clipboard не должны принадлежать одной таблице или одному списку.

```text
SelectionController
    Table
    List
    Tree
    Kanban
    Gallery

DragAndDrop
    Kanban
    Tree
    Table
    Dashboard
    FileInput

Resizable
    SplitView
    Drawer
    DataGrid
    DashboardPanel
```

## 2.4. Роль отделяется от физического значения

Компонент запрашивает не:

```dart
Color(0xFFCC3352)
```

а:

```text
action.danger.high.background.rest
```

Тема разрешает семантическую роль в конкретный цвет.

## 2.5. Семантика отделяется от визуальной выраженности

`danger` означает смысл действия.
`normal`, `ghost`, `outlined`, `low` или `high` означает визуальную громкость.

```dart
colorRole: ActionColorRole.danger,
prominence: ActionProminence.low,
```

Удаление строки в таблице может быть опасным действием с низкой визуальной выраженностью. Красная залитая кнопка в каждой строке не делает систему безопаснее. Она делает её похожей на приборную панель горящего реактора.

## 2.6. Адаптация определяется назначением региона

Одинаковая ширина экрана не означает одинаковое преобразование разных областей.

```text
inspector:
    desktop -> правая панель
    mobile  -> bottom sheet

master-detail detail:
    desktop -> соседняя колонка
    mobile  -> отдельный полноэкранный маршрут

navigation:
    desktop -> sidebar / rail
    mobile  -> drawer / bottom navigation

page actions:
    desktop -> header / toolbar
    mobile  -> bottom actions + overflow
```

## 2.7. Движки заменяемы

Публичный API Carpenter не должен выпускать наружу:

```text
PlutoColumn
FlSpot
GraphicMark
CartesianSeries
ReactiveForm
FormControl
DriftTable
AsyncValue
WidgetRef
DropRegion
```

Внешняя библиотека является реализацией адаптера, а не семантическим API Carpenter.

## 2.8. Чем выше уровень, тем больше конвенций

Basic-компоненты ограничены.

Collections определяют устойчивые модели данных и взаимодействия.

Patterns имеют право сказать:

* где находятся действия;
* как расположены фильтры;
* куда открываются детали;
* что происходит на mobile;
* какие состояния обязательны;
* как работает keyboard navigation.

Иначе вся система снова заканчивается следующим:

```dart
Scaffold(
  body: WhateverTheDeveloperFeltLikeToday(),
);
```

---

# 3. Рекомендуемая структура workspace

```text
packages/
├── carpenter/
│   ├── lib/
│   │   ├── carpenter.dart
│   │   └── src/
│   │       ├── foundation/
│   │       ├── components/
│   │       │   ├── basic/
│   │       │   ├── behaviour/
│   │       │   ├── collections/
│   │       │   ├── dataviz/
│   │       │   └── layout/
│   │       │       ├── regions/
│   │       │       └── patterns/
│   │       └── internal/
│   └── test/
│
├── carpenter_tokens/
├── carpenter_codegen/
├── carpenter_lints/
├── carpenter_bloc/
├── carpenter_riverpod/
├── carpenter_charts_fl/
├── carpenter_charts_graphic/
├── carpenter_charts_syncfusion/
├── carpenter_native/
├── carpenter_test/
├── example/
└── widgetbook/
```

## 3.1. Ответственности пакетов

| Пакет                | Ответственность                                               |
| -------------------- | ------------------------------------------------------------- |
| `carpenter`          | Семантический UI API, компоненты, layout и patterns           |
| `carpenter_tokens`   | Runtime-модель токенов и сгенерированные темы                 |
| `carpenter_codegen`  | Компилятор токенов, Dart-код, отчёты и документация           |
| `carpenter_lints`    | Архитектурные lint rules и quick fixes                        |
| `carpenter_bloc`     | Необязательные адаптеры state/event contracts к Bloc и Cubit  |
| `carpenter_riverpod` | Необязательные адаптеры к providers, notifiers и `AsyncValue` |
| `carpenter_charts_*` | Взаимозаменяемые реализации dataviz API                       |
| `carpenter_native`   | Native drag-and-drop, clipboard, file dialogs                 |
| `carpenter_test`     | Golden harness, test themes, fixtures, a11y helpers           |
| `widgetbook`         | Живой каталог компонентов, состояний и patterns               |

## 3.2. Внутренняя структура foundation

```text
foundation/
├── accessibility/
├── actions/
│   ├── action.dart
│   ├── action_id.dart
│   ├── action_registry.dart
│   ├── action_scope.dart
│   ├── action_state.dart
│   └── command.dart
│
├── roles/
│   ├── color/
│   │   ├── action_color_role.dart
│   │   ├── content_color_role.dart
│   │   ├── layout_surface_role.dart
│   │   ├── layout_border_role.dart
│   │   ├── field_color_role.dart
│   │   ├── feedback_color_role.dart
│   │   ├── navigation_color_role.dart
│   │   ├── selection_color_role.dart
│   │   ├── focus_color_role.dart
│   │   └── dataviz_color_role.dart
│   ├── density/
│   ├── elevation/
│   ├── layer/
│   ├── motion/
│   ├── opacity/
│   ├── shape/
│   ├── size/
│   ├── spacing/
│   └── typography/
│
├── state/
│   ├── async_state.dart
│   ├── data_freshness.dart
│   ├── interaction_state.dart
│   └── mutation_state.dart
│
├── theme/
├── breakpoints/
├── capabilities/
└── generated/
```

## 3.3. Почему dataviz лучше отдельной категорией

Графики можно физически держать в `collections/charts`, чтобы не ломать раннее дерево проекта. Концептуально их лучше выделить:

* у них собственная палитра;
* собственные accessibility-требования;
* axes, legends, annotations и selection;
* отдельная responsive simplification;
* разные backend-движки;
* собственная документация выбора типа визуализации.

Pajamas и Elastic также рассматривают data visualization как самостоятельную область системы.

---

# 4. Иерархия design tokens

## 4.1. Пять уровней

```text
1. primitive tokens
   физические значения:
   OKLCH, размеры, duration, font family

2. semantic foundation tokens
   палитры, spacing scale, typography scale

3. domain role tokens
   action, layout, content, field, feedback,
   navigation, selection, focus, dataviz

4. component tokens
   исключения, принадлежащие конкретному компоненту

5. runtime resolved theme
   Flutter Color, TextStyle, EdgeInsets,
   ShapeBorder, WidgetStateProperty
```

Пример:

```text
palette.brand.600
    ↓
action.primary.high.background.rest
    ↓
CarpenterActionTheme
    ↓
CarpenterButton
```

Component token создаётся только тогда, когда значение невозможно честно выразить через domain role.

Нежелательный путь:

```text
button.primary.background.hovered.dark.compact.special
```

Предпочтительный путь:

```text
action.primary.high.background.hovered
```

---

# 5. Цветовые роли

## 5.1. Роли действий

Исходный enum следует переименовать:

```dart
enum ActionColorRole {
  neutral,
  primary,
  utility,
  danger,
  warning,
  success,
  info,
}
```

Причины:

* тип enum в Dart называется в единственном числе;
* `ColorRoles` не сообщает область применения;
* значения описывают именно семантику действий.

Для временной совместимости:

```dart
@Deprecated(
  'Use ActionColorRole. '
  'ColorRoles will be removed in Carpenter 2.0.',
)
typedef ColorRoles = ActionColorRole;
```

### Семантика

| Роль      | Назначение                                                 |
| --------- | ---------------------------------------------------------- |
| `neutral` | Обычное действие без статусного или брендового акцента     |
| `success` | Подтвердить, принять, одобрить, завершить положительно     |
| `danger`  | Разрушительное, необратимое или рискованное действие       |
| `info`    | Действие вокруг информационного контекста; применять редко |
| `warning` | Действие, требующее осторожности                           |
| `primary` | Основная брендовая цветовая семья действий                 |
| `utility` | Дополнительная утилитарная семья действий                  |

`primary` означает цветовую семью, а не главность действия.

Главность задаётся отдельно:

```dart
enum ActionProminence {
  normal,
  ghost,
  outlined,
  low,
  high,
}
```

Допустимые комбинации:

```dart
ActionColorRole.primary + ActionProminence.high
ActionColorRole.danger  + ActionProminence.low
ActionColorRole.neutral + ActionProminence.normal
```

## 5.2. Визуальные слоты действия

```dart
enum ActionColorSlot {
  background,
  foreground,
  icon,
  border,
  focusRing,
  stateLayer,
}
```

Слот является частью theme resolver, а не публичным параметром `CarpenterButton`.

## 5.3. Состояния действия

Стандартные состояния берутся из Flutter `WidgetState`:

```text
hovered
focused
pressed
dragged
selected
disabled
error
```

Flutter определяет `WidgetState` как общую, не ограниченную Material модель интерактивных состояний и предоставляет `WidgetStateProperty` для разрешения значений по набору состояний.

Состояние выполнения операции задаётся отдельно:

```dart
enum ActionExecutionPhase {
  idle,
  running,
  succeeded,
  failed,
}
```

`running` не следует добавлять в универсальный widget state: это состояние операции, а не любого контрола.

## 5.4. Полный ключ разрешения action color

```text
ActionColorRole
    × ActionProminence
    × ActionColorSlot
    × Set<WidgetState>
    × brightness
    × contrast mode
```

## 5.5. Action theme

```dart
@immutable
final class ActionProminenceColors {
  const ActionProminenceColors({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.border,
    required this.focusRing,
    required this.stateLayer,
  });

  final WidgetStateProperty<Color> background;
  final WidgetStateProperty<Color> foreground;
  final WidgetStateProperty<Color> icon;
  final WidgetStateProperty<Color> border;
  final WidgetStateProperty<Color> focusRing;
  final WidgetStateProperty<Color> stateLayer;
}

@immutable
final class ActionColorSet {
  const ActionColorSet({
    required this.normal,
    required this.high,
    required this.low,
    required this.ghost,
    required this.outlined,
  });

  final ActionProminenceColors normal;
  final ActionProminenceColors high;
  final ActionProminenceColors low;
  final ActionProminenceColors ghost;
  final ActionProminenceColors outlined;
}

@immutable
final class CarpenterActionThemeData {
  const CarpenterActionThemeData({
    required this.neutral,
    required this.success,
    required this.danger,
    required this.info,
    required this.warning,
    required this.primary,
    required this.utility,
  });

  final ActionColorSet neutral;
  final ActionColorSet success;
  final ActionColorSet danger;
  final ActionColorSet info;
  final ActionColorSet warning;
  final ActionColorSet primary;
  final ActionColorSet utility;
}
```

## 5.6. Правила действий

1. `danger` не обязан быть `high`.
2. В одном локальном scope обычно должна быть одна high-prominence action.
3. `utility` применяется только при документированной семантике.
4. `success`, `warning` и `info` не используются как декоративное конфетти.
5. Disabled action сохраняет смысловую роль, но разрешается disabled-state палитрой.
6. Loading action сохраняет форму и содержание; выполнение показывается
   токенизированной фоновой анимацией.
7. Цвет не является единственным носителем смысла.

---

# 6. Layout color roles

Action и layout не используют общий enum.

## 6.1. Поверхности

```dart
enum LayoutSurfaceRole {
  canvas,
  surface,
  sunken,
  raised,
  floating,
  overlay,
  scrim,
}
```

| Роль       | Назначение                                |
| ---------- | ----------------------------------------- |
| `canvas`   | Нижний фон приложения или рабочей области |
| `surface`  | Обычная содержательная поверхность        |
| `sunken`   | Утопленная вложенная область              |
| `raised`   | Приподнятый блок, card или sticky panel   |
| `floating` | Menu, tooltip, popover                    |
| `overlay`  | Modal, flyout, drawer                     |
| `scrim`    | Полупрозрачный слой под modal             |

## 6.2. Границы

```dart
enum LayoutBorderRole {
  separator,
  subtle,
  regular,
  strong,
  emphasis,
}
```

## 6.3. Регионы

```dart
enum LayoutRegionRole {
  application,
  header,
  navigation,
  primary,
  secondary,
  auxiliary,
  detail,
  footer,
  notification,
}
```

Регион выбирает не один цвет, а набор:

```dart
@immutable
final class LayoutRegionColors {
  const LayoutRegionColors({
    required this.background,
    required this.foreground,
    required this.mutedForeground,
    required this.border,
    required this.divider,
  });

  final Color background;
  final Color foreground;
  final Color mutedForeground;
  final Color border;
  final Color divider;
}
```

---

# 7. Остальные цветовые семейства

## 7.1. Content

```dart
enum ContentColorRole {
  primary,
  secondary,
  muted,
  disabled,
  inverse,
  link,
  visitedLink,
  code,
}
```

Статусные тексты не должны превращаться в `ContentColorRole.danger`. Они используют feedback/status theme, поскольку их contrast-пара зависит от контейнера.

## 7.2. Fields

```dart
enum FieldColorRole {
  neutral,
  success,
  warning,
  danger,
}

enum FieldColorSlot {
  background,
  foreground,
  label,
  placeholder,
  border,
  icon,
  caret,
  selection,
  focusRing,
  supportingText,
}

enum FieldAvailability {
  editable,
  readOnly,
  disabled,
}
```

Полный ключ:

```text
FieldColorRole
    × FieldAvailability
    × FieldColorSlot
    × Set<WidgetState>
```

## 7.3. Feedback

```dart
enum FeedbackColorRole {
  neutral,
  info,
  success,
  warning,
  danger,
}
```

Feedback применяется к:

```text
Alert
Toast
Banner
StatusIndicator
InlineValidation
Notification
```

Названия похожи на action roles, но значения и contrast-пары независимы.

## 7.4. Navigation

```dart
enum NavigationColorRole {
  neutral,
  primary,
  accent,
}

enum NavigationState {
  rest,
  hovered,
  pressed,
  current,
  selected,
  disabled,
}
```

`current` означает текущий маршрут.
`selected` означает пользовательский выбор.

## 7.5. Selection

```dart
enum SelectionColorRole {
  primary,
  accent,
  neutral,
}
```

Слоты:

```text
background
foreground
border
handle
range
dropTarget
```

## 7.6. Focus

```dart
enum FocusColorRole {
  standard,
  inverse,
  danger,
}
```

Focus является accessibility-механизмом и не должен автоматически наследовать цвет текущей кнопки.

## 7.7. Dataviz

```dart
sealed class DatavizColorRole {
  const DatavizColorRole();
}

final class CategoricalSeriesRole extends DatavizColorRole {
  const CategoricalSeriesRole(this.index);
  final int index;
}

final class SequentialScaleRole extends DatavizColorRole {
  const SequentialScaleRole(this.position);
  final double position;
}

final class DivergingScaleRole extends DatavizColorRole {
  const DivergingScaleRole(this.position);
  final double position;
}

enum SemanticSeriesRole {
  neutral,
  info,
  success,
  warning,
  danger,
}

enum ChartStructuralColorRole {
  axis,
  grid,
  label,
  annotation,
  referenceLine,
  selection,
  hover,
  background,
}
```

Dataviz palette обязана обеспечивать:

* различимость соседних серий;
* разницу не только hue, но и lightness/chroma;
* светлую и тёмную версии;
* fallback markers/patterns;
* доступное текстовое или табличное представление.

## 7.8. Сводная матрица

| Семейство  | Что выражает                   | Не выражает       |
| ---------- | ------------------------------ | ----------------- |
| Action     | Смысл и выраженность команды   | Фон страницы      |
| Layout     | Глубину, поверхность и регион  | Статус операции   |
| Content    | Иерархию читаемого содержимого | Validation        |
| Field      | Части и состояние поля         | Цвет chart series |
| Feedback   | Сообщение и статус             | Главность кнопки  |
| Navigation | Current/selected navigation    | Domain status     |
| Selection  | Выбор, range и drop target     | Brand action      |
| Focus      | Keyboard focus                 | Hover             |
| Dataviz    | Серии, шкалы, chart structure  | UI-команды        |

---

# 8. Нецветовые роли

## 8.1. Shape и radius

Семантическая форма:

```dart
enum ShapeRole {
  flat,
  rounded,
  circular,
}
```

Физическая шкала:

```dart
enum RadiusToken {
  none,
  xs,
  sm,
  md,
  lg,
  xl,
  full,
}
```

Компонент обычно принимает `ShapeRole`, а theme resolver выбирает физический radius.

```text
Button:
    rounded

Avatar:
    circular

ButtonGroup:
    first  -> rounded on start
    middle -> flat
    last   -> rounded on end
```

## 8.2. Размеры

Нельзя одним `SizeRole.small` описывать всю вселенную.

```dart
enum ControlSize {
  xsmall,
  small,
  medium,
  large,
  xlarge,
}

enum IconSize {
  xsmall,
  small,
  medium,
  large,
  xlarge,
  display,
}

enum AvatarSize {
  xsmall,
  small,
  medium,
  large,
  xlarge,
}

enum FieldSize {
  small,
  medium,
  large,
}

enum RowSize {
  compact,
  regular,
  spacious,
}

enum ChartSize {
  sparkline,
  compact,
  regular,
  expanded,
}
```

Они могут ссылаться на общие primitive tokens, но имеют разный semantic mapping.

## 8.3. Spacing

Primitive scale:

```text
space.0
space.1
space.2
space.3
...
```

Domain roles:

```dart
enum ControlSpacingRole {
  iconGap,
  contentPaddingInline,
  contentPaddingBlock,
}

enum LayoutSpacingRole {
  pageGutter,
  regionGap,
  sectionGap,
  panelPadding,
}

enum CollectionSpacingRole {
  rowGap,
  groupGap,
  cellPaddingInline,
  cellPaddingBlock,
}
```

Публичный `CarpenterGap(13)` не нужен. Иначе библиотека сама выдаёт разработчику оружие, от которого пыталась защитить проект.

## 8.4. Density

```dart
enum CarpenterDensity {
  compact,
  comfortable,
  spacious,
}
```

Density является общей preference, но mapping domain-specific.

```text
compact:
    table row     32
    button        28
    field         30
    menu item     28

comfortable:
    table row     40
    button        36
    field         38
    menu item     36
```

Нельзя просто умножить все размеры на `0.8`: typography, touch targets и visual rhythm не знают о нашей любви к арифметике.

## 8.5. Typography

```dart
enum TypographyRole {
  display,
  headline,
  title,
  body,
  label,
  caption,
  code,
  numeric,
}

enum TypographyEmphasis {
  regular,
  medium,
  strong,
}

enum TypographyScale {
  small,
  medium,
  large,
}
```

```dart
CarpenterText(
  role: TypographyRole.body,
  emphasis: TypographyEmphasis.strong,
  scale: TypographyScale.medium,
  colorRole: ContentColorRole.primary,
);
```

Не создавать:

```text
bodyStrongMutedSmallDanger
```

## 8.6. Motion

```dart
enum MotionDurationRole {
  instant,
  fast,
  regular,
  slow,
  deliberate,
}

enum MotionCurveRole {
  standard,
  enter,
  exit,
  emphasized,
  linear,
}

enum MotionPatternRole {
  fade,
  expand,
  collapse,
  slide,
  reorder,
  overlay,
  navigation,
  feedback,
}
```

Reduced motion может:

* убрать spatial movement;
* заменить slide на fade;
* сократить duration;
* оставить progress animation, если она несёт информацию.

## 8.7. Elevation и layer

```dart
enum ElevationRole {
  base,
  raised,
  floating,
  overlay,
  modal,
}

enum LayerRole {
  content,
  sticky,
  navigation,
  dropdown,
  popover,
  flyout,
  modal,
  notification,
  toast,
  tooltip,
}
```

Elevation описывает визуальную глубину.

Layer описывает порядок наложения.

`zIndex: 999999` не является архитектурной стратегией, сколько бы веб-индустрия ни пыталась доказать обратное.

## 8.8. Breakpoints и capabilities

```dart
enum ViewportClass {
  compact,
  medium,
  expanded,
  wide,
}
```

```dart
@immutable
final class InputCapabilities {
  const InputCapabilities({
    required this.hasTouch,
    required this.hasMouse,
    required this.hasPrecisePointer,
    required this.supportsHover,
    required this.hasHardwareKeyboard,
  });

  final bool hasTouch;
  final bool hasMouse;
  final bool hasPrecisePointer;
  final bool supportsHover;
  final bool hasHardwareKeyboard;
}
```

Решение не должно строиться только на `Platform.isWindows`.

## 8.9. Accessibility foundation

Foundation должен предоставлять:

```text
reducedMotion
highContrast
textScale
boldText
screenReaderSemantics
minimumInteractiveTarget
focusVisibility
semanticAnnouncements
```

---

# 9. Theme architecture

## 9.1. Domain-scoped theme

```dart
@immutable
final class CarpenterThemeData {
  const CarpenterThemeData({
    required this.actions,
    required this.layout,
    required this.content,
    required this.fields,
    required this.feedback,
    required this.navigation,
    required this.selection,
    required this.focus,
    required this.dataviz,
    required this.shapes,
    required this.sizes,
    required this.spacing,
    required this.typography,
    required this.motion,
    required this.elevation,
  });

  final CarpenterActionThemeData actions;
  final CarpenterLayoutThemeData layout;
  final CarpenterContentThemeData content;
  final CarpenterFieldThemeData fields;
  final CarpenterFeedbackThemeData feedback;
  final CarpenterNavigationThemeData navigation;
  final CarpenterSelectionThemeData selection;
  final CarpenterFocusThemeData focus;
  final CarpenterDatavizThemeData dataviz;

  final CarpenterShapeThemeData shapes;
  final CarpenterSizeThemeData sizes;
  final CarpenterSpacingThemeData spacing;
  final CarpenterTypographyThemeData typography;
  final CarpenterMotionThemeData motion;
  final CarpenterElevationThemeData elevation;
}
```

Каждая область:

* immutable;
* имеет `copyWith`;
* имеет `lerp`;
* валидируется;
* может генерироваться;
* документируется отдельно.

## 9.2. Интеграция с Flutter

Практичная первая версия:

1. Domain theme classes реализуются через `ThemeExtension`.
2. Доступ скрывается за `CarpenterTheme.of(context)`.
3. Компоненты не вызывают напрямую `Theme.of(context).extension<T>()`.
4. В будущем backing store можно заменить собственным `InheritedTheme`.

Flutter `ThemeExtension` предназначен для добавления custom theme values в `ThemeData` и поддерживает интерполяцию через `lerp`.

```dart
final actionTheme = CarpenterTheme.of(context).actions;
```

## 9.3. Component theme

Component theme содержит только специфичные параметры.

```dart
@immutable
final class CarpenterButtonThemeData {
  const CarpenterButtonThemeData({
    required this.minInlineSize,
    required this.preserveLabelWidthWhileBusy,
    required this.defaultIconAlignment,
  });

  final double minInlineSize;
  final bool preserveLabelWidthWhileBusy;
  final IconAlignment defaultIconAlignment;
}
```

Цвета по-прежнему приходят из action theme.

## 9.4. Локальные scopes

```dart
CarpenterDensityScope(
  density: CarpenterDensity.compact,
  child: table,
);
```

```dart
CarpenterRegionTheme(
  role: LayoutRegionRole.navigation,
  child: sidebar,
);
```

Произвольный локальный raw-color override должен быть escape hatch, а не стандартным API.

---

# 10. Генерация палитр в OKLCH

## 10.1. Почему OKLCH

OKLCH задаёт:

```text
L — воспринимаемую светлоту
C — chroma
h — hue
```

Он удобнее HSL/RGB для системных палитр, поскольку изменение `L` лучше соответствует воспринимаемому изменению светлоты.

Это не означает, что любой набор OKLCH-чисел автоматически:

* доступен;
* попадает в sRGB;
* эстетически согласован;
* обладает достаточным контрастом;
* различим при нарушениях цветового восприятия.

CSS Color 4 стандартизирует Oklab и OKLCH как цветовые пространства для web-представления.

## 10.2. Канонический формат токенов

Каноническим source of truth следует сделать **DTCG Design Tokens 2025.10 JSON**.

Color module DTCG поддерживает `oklch`, `oklab`, `srgb`, `display-p3` и другие пространства.

YAML может остаться authoring layer:

```text
tokens.yaml
    ↓
canonical.tokens.json
    ↓
DTCG validation
    ↓
generated Dart / CSS / docs / reports
```

Нельзя позволять YAML и JSON независимо определять одни и те же токены.

## 10.3. Seed model

```yaml
palette:
  brand:
    seed:
      colorSpace: oklch
      components: [0.62, 0.18, 288]
      alpha: 1
    pivot: 500
    gamut: srgb

  neutral:
    seed:
      colorSpace: oklch
      components: [0.62, 0.025, 260]
      alpha: 1
    pivot: 500
    gamut: srgb
```

```dart
@immutable
final class PaletteSeed {
  const PaletteSeed({
    required this.id,
    required this.lightness,
    required this.chroma,
    required this.hue,
    required this.pivot,
    required this.gamut,
    required this.chromaCurve,
  });

  final String id;
  final double lightness;
  final double chroma;
  final double hue;
  final int pivot;
  final TargetGamut gamut;
  final ChromaCurve chromaCurve;
}
```

## 10.4. Tonal scale

Рекомендуемый набор stops:

```text
0
50
100
200
300
400
500
600
700
800
900
950
1000
```

Стартовые lightness targets:

| Stop |     L |
| ---: | ----: |
|    0 | 0.995 |
|   50 | 0.970 |
|  100 | 0.940 |
|  200 | 0.880 |
|  300 | 0.800 |
|  400 | 0.700 |
|  500 | 0.600 |
|  600 | 0.520 |
|  700 | 0.440 |
|  800 | 0.350 |
|  900 | 0.260 |
|  950 | 0.180 |
| 1000 | 0.100 |

Это стартовая кривая, а не священное писание.

## 10.5. Chroma curve

Постоянная chroma на всех уровнях ломает gamut около белого и чёрного.

Стартовая модель:

```text
normalized = clamp(
  (L - Lmin) / (Lmax - Lmin),
  0,
  1
)

envelope = sin(pi * normalized) ^ gamma

Ctarget =
  Cseed
  * envelope
  / envelope(Lpivot)
```

Затем:

```text
Ctarget = min(
  Ctarget,
  CmaxInTargetGamut(L, h)
)
```

Генератор должен позволять per-palette overrides, потому что разные hue по-разному упираются в sRGB gamut.

## 10.6. Gamut mapping

Нельзя просто clamp-ить RGB channels. Это меняет hue и воспринимаемую светлоту.

Рекомендуемый порядок:

1. Построить OKLCH.
2. Проверить target gamut.
3. Уменьшать chroma с сохранением `L` и `h`.
4. При необходимости использовать perceptual gamut mapping.
5. Сохранить diagnostic:

    * исходную chroma;
    * итоговую chroma;
    * Delta E;
    * причину коррекции.

Color.js поддерживает множество цветовых пространств, преобразования, Delta E, contrast и gamut mapping, поэтому является сильным кандидатом для build-time color engine.

## 10.7. Нейтральные палитры

Нейтраль не обязана иметь `C = 0`.

```text
neutral:
    C = 0.000..0.030
    hue = brand-adjacent или отдельный cool/warm seed
```

Минимальный набор:

```text
neutral
brand
accent
success
warning
danger
info
```

Отдельно:

```text
dataviz categorical
dataviz sequential
dataviz diverging
```

## 10.8. Dark theme

Dark theme не является `palette.reversed`.

```text
light action.primary.high.background -> brand.600
dark  action.primary.high.background -> brand.400
```

Для dark theme часто требуется:

* снижать chroma больших поверхностей;
* увеличивать chroma небольших indicators;
* избегать чистого белого для обычного текста;
* отдельно проверять borders;
* отдельно проверять focus;
* не применять случайный `withOpacity` внутри компонентов.

## 10.9. Contrast validation

Проверяются пары:

```text
foreground / background
icon / background
border / adjacent surface
focus ring / surrounding colors
selected foreground / selected background
chart label / chart background
```

WCAG 2.2 задаёт нормативные критерии контраста для текста и meaningful non-text elements. Для обычного текста базовый порог составляет 4.5:1, для крупного текста 3:1; controls и meaningful graphics также требуют достаточной различимости.

Более новые contrast-модели можно использовать как дополнительный diagnostic, но не как единственную нормативную проверку.

## 10.10. Генерируемые файлы

```text
generated/
├── palettes.g.dart
├── action_theme.g.dart
├── layout_theme.g.dart
├── content_theme.g.dart
├── field_theme.g.dart
├── feedback_theme.g.dart
├── navigation_theme.g.dart
├── dataviz_theme.g.dart
├── tokens_manifest.g.dart
├── token_docs.md
├── token_report.json
└── contrast_report.json
```

`token_report.json` включает:

* unresolved aliases;
* cycles;
* missing dark values;
* out-of-gamut corrections;
* contrast failures;
* unused tokens;
* duplicate semantic values;
* component tokens, которые можно свернуть в общие roles.

## 10.11. Рекомендуемый toolchain

```text
DTCG JSON
    ↓
Terrazzo validation / lint / build
    ↓
custom Carpenter plugin
    ↓
Color.js OKLCH / gamut / Delta E
    ↓
Dart theme classes
CSS preview
docs
reports
```

Terrazzo принимает DTCG-токены, предоставляет CLI для build/lint/check и расширяется plugins. Style Dictionary является зрелой альтернативой с custom transforms и output formats.

Полностью Dart-вариант тоже возможен:

```text
yaml / json
    ↓
carpenter_codegen
    ├── parser
    ├── alias resolver
    ├── OKLab / OKLCH math
    ├── gamut mapper
    ├── validator
    └── Dart emitter
```

Но тогда нужно самостоятельно тестировать:

* conversion matrices;
* transfer functions;
* gamut mapping;
* Delta E;
* contrast;
* DTCG compatibility.

Пакет `oklch` на pub.dev сейчас сам предупреждает о несовпадении результатов с референсной реализацией. Делать его фундаментом темы рискованно. `material_color_utilities` предоставляет HCT/Material color utilities, но HCT не следует незаметно подменять OKLCH.

---

# 11. Actions и commands

## 11.1. Общая модель действия

Одно действие может быть представлено:

```text
Button
MenuItem
ContextMenuItem
ToolbarItem
OverflowItem
MobileBottomAction
CommandPaletteItem
KeyboardShortcut
```

Поэтому нужен общий descriptor.

```dart
@immutable
final class CarpenterAction {
  const CarpenterAction({
    required this.id,
    required this.label,
    required this.onInvoke,
    this.description,
    this.icon,
    this.shortcut,
    this.colorRole = ActionColorRole.neutral,
    this.prominence = ActionProminence.low,
    this.priority = ActionPriority.normal,
    this.kind = ActionKind.command,
    this.enabled = true,
    this.visible = true,
    this.selected = false,
    this.phase = ActionExecutionPhase.idle,
  });

  final CarpenterActionId id;
  final String label;
  final String? description;
  final CarpenterIconData? icon;
  final ShortcutActivator? shortcut;

  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ActionPriority priority;
  final ActionKind kind;

  final bool enabled;
  final bool visible;
  final bool selected;
  final ActionExecutionPhase phase;

  final FutureOr<void> Function() onInvoke;
}
```

```dart
enum ActionPriority {
  essential,
  normal,
  overflow,
}

enum ActionKind {
  command,
  toggle,
  navigation,
  submit,
  cancel,
}
```

`priority` влияет на placement.
`prominence` влияет на appearance.

## 11.2. Action registry

```dart
CarpenterActionRegistry(
  actions: [
    saveAction,
    deleteAction,
    openSearchAction,
  ],
  child: application,
);
```

Registry обеспечивает:

* command palette;
* global shortcuts;
* action discovery;
* disabled explanations;
* stable action id;
* instrumentation;
* adaptive rendering;
* shortcut conflict detection.

Flutter уже предоставляет `Actions`, `Intents` и `Shortcuts`, разделяющие описание команды, её реализацию и keyboard binding. Carpenter должен строить registry поверх них, а не писать ещё один диспетчер клавиатуры с человеческим лицом.

## 11.3. Side effects

```text
user invokes action
    ↓
Cubit / Bloc / Notifier
    ↓
state change + one-shot effect
    ↓
page adapter
    ↓
router / toaster / dialog controller
```

Carpenter не показывает success toast автоматически после любого `Future`: он не знает, что операция означает и завершена ли она бизнес-семантически.

---

# 12. Bloc, Cubit, Riverpod и Drift

## 12.1. Граница ответственности

```text
Carpenter
    rendering
    interaction contracts
    UI events

Bloc / Cubit
    feature state
    workflows
    mutations

Riverpod
    dependency composition
    lifecycle
    shared reactive dependencies

Repository
    domain-facing data access

Drift
    persistence
    SQL
    local reactive streams
```

Неправильно:

```dart
CarpenterTable(
  provider: paymentsProvider,
);
```

```dart
CarpenterForm(
  bloc: paymentBloc,
);
```

Правильно:

```dart
CarpenterTable<Payment, PaymentId>(
  state: state.table,
  onEvent: cubit.handleTableEvent,
);
```

## 12.2. Cubit и Bloc

Cubit подходит для командного API:

```text
setSearch
setSort
select
refresh
openDetails
```

Bloc предпочтительнее для процессов, где важны:

* последовательность событий;
* cancellation;
* restartable/droppable обработка;
* concurrency;
* audit;
* сложные transitions.

Примеры:

```text
upload
approval workflow
wizard
save pipeline
synchronization
authentication
drag transaction
```

`flutter_bloc` предоставляет единый widget API вокруг Bloc и Cubit, включая builders, listeners и selectors.

## 12.3. Riverpod как composition layer

Рекомендуемое распределение:

```text
Riverpod:
    repositories
    service construction
    feature factories
    lifecycle
    application-scoped streams

Bloc / Cubit:
    page state
    user events
    workflow
    mutations
```

```dart
final paymentsCubitProvider =
    Provider.autoDispose<PaymentsCubit>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final cubit = PaymentsCubit(repository);

  ref.onDispose(cubit.close);

  return cubit;
});
```

Riverpod поддерживает composition, provider lifecycle и reactive dependency graph; adapter при этом не должен протекать в Carpenter components.

Не обязательно использовать оба инструмента в каждой feature.

`ref.watch`, `BlocBuilder`, `StreamBuilder` и `setState` в одном `build()` не являются мультпарадигмальной архитектурой. Это просто место происшествия.

## 12.4. Drift ниже repository

```text
Drift query
    ↓
Repository
    ↓
Cubit / Bloc / Notifier
    ↓
immutable view state
    ↓
Carpenter
```

Drift предоставляет typed reactive persistence и query streams, но UI не должен импортировать generated tables или statements.

## 12.5. Async state

```dart
sealed class CarpenterAsyncState<T> {
  const CarpenterAsyncState();
}

final class Initial<T> extends CarpenterAsyncState<T> {
  const Initial();
}

final class Loading<T> extends CarpenterAsyncState<T> {
  const Loading({this.previous});

  final T? previous;
}

final class Ready<T> extends CarpenterAsyncState<T> {
  const Ready(
    this.value, {
    this.freshness = DataFreshness.fresh,
  });

  final T value;
  final DataFreshness freshness;
}

final class Failed<T> extends CarpenterAsyncState<T> {
  const Failed(
    this.error, {
    this.previous,
  });

  final Object error;
  final T? previous;
}
```

```dart
enum DataFreshness {
  fresh,
  stale,
  syncing,
  offline,
  conflicted,
}
```

При refresh не следует скрывать previous data, если она ещё пригодна.

## 12.6. Mutation state

Один `bool isLoading` недостаточен.

```dart
@immutable
final class MutationState<K> {
  const MutationState({
    this.creating = const {},
    this.updating = const {},
    this.deleting = const {},
    this.failures = const {},
  });

  final Set<K> creating;
  final Set<K> updating;
  final Set<K> deleting;
  final Map<K, Object> failures;
}
```

Страница может одновременно:

* подгружать следующую страницу;
* сохранять одну строку;
* удалять другую;
* обновлять summary;
* загружать detail.

## 12.7. One-shot effects

Навигация, dialog и toast не должны жить вечным bool в state.

```dart
sealed class PaymentsEffect {
  const PaymentsEffect();
}

final class ShowPaymentSaved extends PaymentsEffect {}

final class NavigateToPayment extends PaymentsEffect {
  const NavigateToPayment(this.id);

  final PaymentId id;
}
```

Effect обрабатывается listener-ом.

---

# 13. Общие collection contracts

## 13.1. Query

```dart
@immutable
final class CarpenterCollectionQuery<F, S> {
  const CarpenterCollectionQuery({
    this.search = '',
    required this.filter,
    required this.sort,
    this.pageSize = 50,
    this.cursor,
  });

  final String search;
  final F filter;
  final List<S> sort;
  final int pageSize;
  final Object? cursor;
}
```

Carpenter query является UI-моделью.

Repository преобразует её в domain query.

Drift repository преобразует domain query в SQL.

## 13.2. Snapshot

```dart
@immutable
final class CarpenterCollectionSnapshot<T, K> {
  const CarpenterCollectionSnapshot({
    required this.items,
    required this.keyOf,
    this.totalCount,
    this.nextCursor,
    this.previousCursor,
    this.freshness = DataFreshness.fresh,
    this.revision,
  });

  final List<T> items;
  final K Function(T) keyOf;
  final int? totalCount;
  final Object? nextCursor;
  final Object? previousCursor;
  final DataFreshness freshness;
  final Object? revision;
}
```

## 13.3. Load phases

```dart
enum CollectionLoadPhase {
  initial,
  initialLoading,
  ready,
  refreshing,
  loadingMore,
  empty,
  zeroResults,
  failed,
}
```

Различия:

```text
empty:
    данных действительно нет
    recovery: создать / импортировать

zeroResults:
    данные есть, но query ничего не нашёл
    recovery: изменить / сбросить фильтры

failed:
    данные получить не удалось
    recovery: повторить / открыть diagnostics /
              использовать stale data
```

Cloudscape также разделяет empty, no-match и error states и рассматривает table, cards и split view как разные представления коллекции ресурсов.

## 13.4. Selection

```dart
enum SelectionMode {
  none,
  single,
  multiple,
}

@immutable
final class CarpenterSelectionState<K> {
  const CarpenterSelectionState({
    required this.mode,
    this.selected = const {},
    this.anchor,
    this.allMatchingSelected = false,
    this.excludedFromAll = const {},
  });

  final SelectionMode mode;
  final Set<K> selected;
  final K? anchor;
  final bool allMatchingSelected;
  final Set<K> excludedFromAll;
}
```

`allMatchingSelected` нужен для server-side bulk selection.

## 13.5. Events

```dart
sealed class CarpenterCollectionEvent<K, F, S> {
  const CarpenterCollectionEvent();
}

final class SearchChanged<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {
  const SearchChanged(this.value);

  final String value;
}

final class FilterChanged<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {
  const FilterChanged(this.value);

  final F value;
}

final class SortChanged<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {
  const SortChanged(this.value);

  final List<S> value;
}

final class SelectionChanged<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {
  const SelectionChanged(this.value);

  final CarpenterSelectionState<K> value;
}

final class ItemActivated<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {
  const ItemActivated(this.key);

  final K key;
}

final class RefreshRequested<K, F, S>
    extends CarpenterCollectionEvent<K, F, S> {}
```

Для простых компонентов остаются обычные callbacks. Event union нужен compound components и page patterns, а не каждой кнопке.

## 13.6. Pagination

Поддерживаются:

```text
offset pagination
cursor pagination
keyset pagination
progressive loading
unknown total
live updates
position restoration
```

API не должен предполагать, что `pageNumber` существует всегда.

## 13.7. Drift streams

```dart
Stream<List<Payment>> watchPayments(
  PaymentQuery query,
);
```

При изменении query необходимы:

* cancellation старой подписки;
* debounce для text search;
* immediate update для discrete filters;
* query deduplication;
* защита от late results;
* transaction-consistent projections.

## 13.8. Optimistic UI

Item-level state:

```text
pendingCreate
pendingUpdate
pendingDelete
conflicted
failed
```

Удалённая optimistic row может:

1. исчезнуть;
2. породить toast с Undo;
3. вернуться на прежнее место при failure;
4. сохранить stable key.

---

# 14. Basic-компоненты

## 14.1. Общий шаблон спецификации

Каждый компонент документируется по структуре:

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
Adaptive behavior
Composition
Theming
Test matrix
```

## 14.2. Button

### Ответственность

Запускает действие.

Не используется как семантическая ссылка и не заменяет выбор значения.

```dart
CarpenterButton(
  label: 'Сохранить',
  icon: CarpenterIcons.save,
  action: saveAction,
  size: ControlSize.medium,
  shape: ShapeRole.rounded,
);
```

Без action descriptor:

```dart
CarpenterButton(
  label: 'Сохранить',
  onPressed: save,
  colorRole: ActionColorRole.primary,
  prominence: ActionProminence.high,
  busy: state.saving,
);
```

### Возможности

* label;
* leading/trailing icon;
* busy;
* selected/toggle;
* full-width;
* semantic label;
* shortcut hint;
* tooltip для icon-only;
* async invocation guard;
* minimum target;
* focus/hover/pressed;
* role/prominence.

### Не должно быть в обычном API

```text
backgroundColor
hoverColor
borderColor
padding
height
borderRadius
textStyle
```

Они заменяются roles, size и shape.

## 14.3. IconButton

```dart
CarpenterIconButton(
  icon: CarpenterIcons.close,
  semanticLabel: 'Закрыть',
  onPressed: close,
);
```

Icon-only action обязана иметь semantic label.

## 14.4. ButtonGroup

Отвечает за:

* объединение границ;
* first/middle/last shape;
* общий размер;
* keyboard traversal;
* group semantics;
* horizontal/vertical presentation;
* overflow policy.

## 14.5. SplitButton

```dart
CarpenterSplitButton(
  primaryAction: createDefault,
  alternativeActions: [
    createInvoice,
    createReceipt,
  ],
);
```

Primary segment выполняет default action. Secondary раскрывает альтернативы.

## 14.6. SegmentedControl

Выбирает один режим из малого числа вариантов.

```dart
CarpenterSegmentedControl<ViewMode>(
  value: state.viewMode,
  items: const [
    Segment(
      value: ViewMode.table,
      label: 'Таблица',
    ),
    Segment(
      value: ViewMode.cards,
      label: 'Карточки',
    ),
  ],
  onChanged: cubit.setViewMode,
);
```

Не используется для набора команд.

## 14.7. Link

```dart
CarpenterLink(
  label: 'Открыть договор',
  destination: route,
  external: false,
);
```

Link имеет navigation semantics. Button имеет action semantics.

## 14.8. Text, Code, KeyboardKey

```dart
CarpenterText(...)
CarpenterCode(...)
CarpenterKeyboardKey(...)
```

`CarpenterCode` задаёт monospace, selection, copy и overflow policy.

`CarpenterKeyboardKey` представляет shortcut hint, но не обрабатывает shortcut.

## 14.9. Avatar и AvatarGroup

Avatar:

* image;
* initials fallback;
* entity label;
* presence;
* shape;
* status ring;
* loading/error fallback.

AvatarGroup:

* max visible;
* overlap;
* overflow count;
* accessible aggregate label;
* popover со скрытыми участниками.

## 14.10. Badge, Tag, Token, StatusIndicator

| Компонент         | Смысл                             |
| ----------------- | --------------------------------- |
| `Badge`           | Короткая метаинформация или count |
| `Tag`             | Классификация                     |
| `Token`           | Интерактивное выбранное значение  |
| `StatusIndicator` | Состояние сущности или процесса   |

## 14.11. Card

```dart
CarpenterCard(
  header: ...,
  child: ...,
  footer: ...,
  action: openAction,
  selected: false,
);
```

Card является контейнером одного смыслового блока, а не способом добавить padding ко всей странице.

## 14.12. Input family

Общий field shell:

```text
label
required marker
control
prefix/suffix
supporting text
validation
counter
```

```dart
CarpenterInput(
  value: value,
  onChanged: onChanged,
  label: 'Название',
  placeholder: 'Введите название',
  supportingText: 'До 200 символов',
  validation: FieldValidationState.valid,
  clearable: true,
  availability: FieldAvailability.editable,
);
```

Семейство:

```text
Input
SearchInput
TextArea
PasswordInput
NumberInput
DateInput
TimeInput
DateRangeInput
FileInput
```

## 14.13. Select family

```text
Select          одно значение из закрытого набора
MultiSelect     несколько значений
ComboBox        значение + поиск/ввод
Autosuggest     текст с предложениями
Cascader        иерархический выбор
```

Dropdown menu с командами не является Select.

## 14.14. Checkbox, Radio, Switch

```text
Checkbox:
    независимое boolean
    multi-selection

Radio:
    один вариант из группы

Switch:
    немедленно применяемое on/off состояние
```

## 14.15. Slider и RangeSlider

Поддерживаются:

* min/max;
* step;
* marks;
* keyboard;
* formatted value;
* optional input coupling;
* accessibility value.

## 14.16. Calendar

`Calendar` в basic выбирает дату или диапазон.

Полноценный event calendar принадлежит collections.

## 14.17. FileInput

```dart
CarpenterFileInput(
  files: state.files,
  accept: const ['application/pdf'],
  multiple: true,
  onFilesSelected: cubit.addFiles,
);
```

Слои:

```text
FileInput          presentation
DragAndDrop        behaviour
file_selector      native dialog
Upload Bloc        workflow
```

## 14.18. Полный каталог basic

```text
avatar
avatar_group
badge
button
button_group
calendar
card
checkbox
code
combo_box
date_input
date_range_input
divider
file_input
icon
icon_button
input
keyboard_key
link
meter
multi_select
number_input
password_input
progress
radio
radio_group
range_slider
rating
search_input
segmented_control
select
slider
split_button
status_indicator
switch
tag
text
text_area
time_input
toggle_button
token
```

---

# 15. Behaviour

## 15.1. Overlay foundation

Общий механизм для:

```text
tooltip
popover
dropdown
context menu
autosuggest
date picker
flyout
dialog
toast
```

Он отвечает за:

* anchor;
* positioning;
* collision;
* flip/shift;
* safe area;
* focus;
* dismiss outside;
* Escape;
* restoration;
* semantics;
* layer ordering;
* nested overlays.

Flutter `OverlayPortal` позволяет рендерить overlay child в `Overlay` и при этом сохранять доступ к inherited dependencies исходного subtree. Его следует использовать как низкоуровневый фундамент, закрытый Carpenter API.

## 15.2. Tooltip

* Короткая supplementary information.
* Не содержит interactive content.
* Не заменяет label.
* Показывается по hover и keyboard focus.
* Не используется для критической информации.

## 15.3. Popover

Используется для:

* preview;
* small settings;
* contextual details;
* inline help;
* quick actions.

Popover может быть интерактивным и обязан управлять focus.

## 15.4. Menu, Dropdown, ContextMenu

```dart
sealed class CarpenterMenuEntry {
  const CarpenterMenuEntry();
}

final class MenuAction extends CarpenterMenuEntry {
  const MenuAction(this.action);

  final CarpenterAction action;
}

final class MenuSeparator extends CarpenterMenuEntry {
  const MenuSeparator();
}

final class MenuSubmenu extends CarpenterMenuEntry {
  const MenuSubmenu({
    required this.label,
    required this.children,
  });

  final String label;
  final List<CarpenterMenuEntry> children;
}
```

Menu поддерживает:

* arrows;
* Home/End;
* typeahead;
* disabled reason;
* shortcut hints;
* nested menu;
* checked entries;
* destructive role;
* screen-reader semantics.

## 15.5. Dialog

Dialog используется для:

* обязательного решения;
* короткой формы;
* критической информации;
* существенного подтверждения.

```dart
CarpenterDialog(
  title: ...,
  content: ...,
  actions: ...,
  dismissPolicy: DialogDismissPolicy.explicit,
);
```

Dialog не является стандартным ответом на любую задачу. Для сложного create/edit лучше page или flyout. Для обратимого удаления часто лучше Undo.

## 15.6. Flyout, Drawer и Sheet

```dart
CarpenterFlyout(
  child: inspector,
  presentation: FlyoutPresentation.auto,
  modal: false,
  resizable: true,
);
```

Presentation:

```text
side panel
bottom panel
bottom sheet
overlay drawer
full screen
```

Выбирается semantic region policy, а не локальным `if (isMobile)`.

## 15.7. Alert, Banner, Toast, Notification

| Механизм       |               Lifetime | Контекст                        |
| -------------- | ---------------------: | ------------------------------- |
| `Alert`        | Пока актуален контекст | Внутри страницы или формы       |
| `Banner`       |                  Долго | Уровень страницы или приложения |
| `Toast`        |                 Кратко | Результат действия              |
| `Notification` |               Хранится | Центр уведомлений и история     |

## 15.8. Toaster

Toast не вставляет себя в Overlay.

Нужны:

```text
CarpenterToast
CarpenterToasterController
CarpenterToastRegion
```

```dart
toaster.show(
  CarpenterToast(
    id: const ToastId('payment.deleted'),
    role: FeedbackColorRole.neutral,
    message: 'Платёж удалён',
    action: undoAction,
    timeout: const Duration(seconds: 6),
  ),
);
```

Controller отвечает за:

* очередь;
* deduplication;
* update/replace;
* priority;
* timeout;
* pause on hover/focus;
* dismiss;
* Undo;
* max visible.

Region отвечает за:

* placement;
* safe area;
* stacking;
* animation;
* mobile/desktop presentation;
* screen-reader live region.

## 15.9. Disclosure

Один механизм раскрытия используется в:

```text
Accordion
TreeNode
ExpandableRow
CollapsiblePanel
FormSection
```

## 15.10. Selection

Поддерживается:

* click/tap;
* checkbox;
* Ctrl/Cmd toggle;
* Shift range;
* keyboard range;
* select all loaded;
* select all matching;
* disabled items;
* restoration.

## 15.11. Drag-and-drop

```dart
CarpenterDragScope<T>
CarpenterDraggable<T>
CarpenterDropTarget<T>
```

```dart
@immutable
final class CarpenterDragPayload<T> {
  const CarpenterDragPayload({
    required this.type,
    required this.value,
    required this.allowedOperations,
  });

  final String type;
  final T value;
  final Set<DragOperation> allowedOperations;
}
```

Поддерживаются:

* internal reorder;
* cross-collection move/copy/link;
* native file drag;
* preview;
* drop indicator;
* auto-scroll;
* keyboard alternative;
* async commit/rollback;
* touch long-press.

## 15.12. Reorderable

Reorder изменяет порядок внутри набора. Drag-and-drop может перемещать между контейнерами.

## 15.13. Resizable и Splitter

Требования:

* pointer;
* keyboard resize;
* min/max;
* snap points;
* collapse;
* double-click reset;
* persisted size;
* accessible value.

## 15.14. InlineEdit

```dart
CarpenterInlineEdit<T>(
  value: value,
  displayBuilder: ...,
  editorBuilder: ...,
  onCommit: ...,
  onCancel: ...,
);
```

Поддерживаются:

* Enter/Tab commit;
* Escape cancel;
* async validation;
* busy;
* optimistic value;
* conflict/error;
* stable layout.

## 15.15. Clipboard

```text
CarpenterCopyable
CarpenterPasteTarget
```

Rich/native clipboard реализуется адаптером. Простой text copy может использовать Flutter services.

## 15.16. Undo

```dart
CarpenterUndoScope(
  controller: undoController,
  child: application,
);
```

```dart
undoController.push(
  UndoableOperation(
    label: 'Удаление платежа',
    undo: restore,
    redo: deleteAgain,
  ),
);
```

Toast только представляет доступную операцию Undo.

## 15.17. Loading

Разделять:

```text
Progress     известная степень
Loader       неизвестная длительность
Skeleton     ожидаемая форма content
Busy         блокировка региона или контрола
Refresh      повторная загрузка существующих данных
```

## 15.18. Virtualization

Virtualization используется:

```text
List
Table
DataGrid
Tree
Kanban
Timeline
Calendar
```

Нужны:

* stable keys;
* variable extents;
* cache policy;
* anchor restoration;
* pinned regions;
* two-dimensional virtualization.

## 15.19. CommandPalette

```dart
CarpenterCommandPalette(
  registry: actionRegistry,
  query: state.query,
  onQueryChanged: cubit.setQuery,
);
```

Поддерживаются:

* global/scoped commands;
* fuzzy search;
* recent commands;
* categories;
* disabled reasons;
* shortcuts;
* nested flow;
* async results.

## 15.20. Полный каталог behaviour

```text
alert
anchored_overlay
banner
busy
clipboard
collapse
command_palette
context_menu
dialog
dismissible
drag_and_drop
dropdown
expandable
flyout
focus_trap
inline_edit
loader
menu
overlay
popover
progressive_load
refresh
reorderable
resizable
selection
skeleton
swipe_actions
toast
toaster
tooltip
undo
virtualization
```

---

# 16. Collections

## 16.1. ListView и DataList

`ListView` является общим списком.

`DataList` имеет структурированную строку:

```text
leading
title
description
metadata
status
actions
selection
expanded details
```

## 16.2. Table

Table предназначена для сравнения одинаковых attributes множества объектов.

```dart
CarpenterTable<Payment, PaymentId>(
  state: state.table,
  columns: [
    CarpenterColumn(
      id: const ColumnId('number'),
      label: 'Номер',
      value: (payment) => payment.number,
      sortable: true,
      width: const ColumnWidth.flex(1),
    ),
    CarpenterColumn(
      id: const ColumnId('amount'),
      label: 'Сумма',
      value: (payment) => payment.amount,
      alignment: Alignment.centerRight,
    ),
  ],
  keyOf: (payment) => payment.id,
  onEvent: cubit.handleTableEvent,
);
```

Table поддерживает:

* client/server sorting;
* multi-sort;
* selection;
* bulk actions;
* row actions;
* keyboard activation;
* column visibility;
* ordering;
* resizing;
* sticky header;
* pinned columns;
* expandable rows;
* inline editing;
* density;
* pagination;
* progressive loading;
* initial/loading/refreshing/empty/zero/error;
* responsive column priority;
* accessible caption и headers.

Cloudscape рекомендует table, когда пользователю нужно сканировать и сравнивать одинаковые attributes большого числа ресурсов; cards подходят для более визуальных и неоднородных данных, а split view — для быстрого просмотра деталей без потери коллекции.

## 16.3. DataGrid

DataGrid предназначен для spreadsheet-like работы:

```text
cell focus
arrow navigation
range selection
copy/paste
editing
fill
pinned rows/columns
grouped columns
aggregation
two-dimensional virtualization
```

Это отдельный компонент, а не `Table` с ещё двадцатью bool.

## 16.4. CardCollection

```dart
CarpenterCardCollection<T, K>(
  state: state,
  cardBuilder: ...,
  selection: selection,
  layout: CardCollectionLayout.adaptive,
);
```

Это полноценная collection с selection, pagination, states и responsive layout.

## 16.5. TreeView

```dart
CarpenterTreeView<Node, NodeId>(
  roots: roots,
  childrenOf: repository.childrenOf,
  keyOf: (node) => node.id,
  expanded: state.expanded,
  selection: state.selection,
  onEvent: cubit.handleTreeEvent,
);
```

Поддерживается:

* lazy children;
* selection;
* checkbox;
* search;
* reveal path;
* keyboard;
* drag/reorder;
* actions;
* badges/status;
* virtualized flattened projection;
* loading/errors per node.

## 16.6. TreeTable

Иерархия плюс columns. Отдельный компонент.

## 16.7. DefinitionList

```text
ИНН            1234567890
КПП            123456789
Статус         Активен
```

Поддерживает:

* responsive label/value layout;
* copy;
* status;
* inline edit;
* empty values;
* grouping.

## 16.8. AttributeEditor

```dart
CarpenterAttributeEditor<Attribute>(
  items: state.attributes,
  onAdd: cubit.addAttribute,
  onRemove: cubit.removeAttribute,
  onChanged: cubit.changeAttribute,
);
```

## 16.9. Form

Form относится к collections, потому что представляет структурированный объект из полей и групп.

```dart
CarpenterForm(
  sections: [
    CarpenterFormSection(
      title: 'Основное',
      fields: fields,
    ),
  ],
  state: state.form,
  onEvent: cubit.handleFormEvent,
);
```

Form отвечает за:

* sections;
* groups;
* validation summary;
* dirty state;
* read-only;
* conditional fields;
* field dependencies;
* focus first error;
* responsive labels;
* save/reset.

Form не делает HTTP или SQL.

## 16.10. FilterBar

```dart
CarpenterFilterBar<F>(
  value: state.filter,
  search: state.search,
  definitions: filterDefinitions,
  savedSets: state.savedFilters,
  onEvent: cubit.handleFilterEvent,
);
```

Содержит:

* search;
* common filters;
* advanced filters;
* applied tokens;
* clear/reset;
* saved sets;
* result count;
* view preferences.

## 16.11. PropertyFilter

Advanced query builder:

```text
property
operator
value
AND/OR
group
```

Поддерживает:

* typed values;
* autocomplete;
* relative dates;
* ranges;
* serialization;
* validation;
* human-readable summary.

## 16.12. CollectionPreferences

```dart
CarpenterCollectionPreferences(
  density: state.density,
  visibleColumns: state.columns,
  columnOrder: state.columnOrder,
  pageSize: state.pageSize,
  viewMode: state.viewMode,
);
```

Это presentation preferences, а не business filters.

## 16.13. Tabs, Accordion, Breadcrumbs, Stepper

```text
Tabs:
    sibling views

Accordion:
    disclosure sections

Breadcrumbs:
    ordered hierarchy/path

Stepper:
    state of ordered process

Wizard:
    page-level workflow
```

## 16.14. Timeline, ActivityFeed, Comments, LogView

| Компонент      | Смысл                             |
| -------------- | --------------------------------- |
| `Timeline`     | События на временной оси          |
| `ActivityFeed` | Actor + action + object + context |
| `Comments`     | Conversation/thread               |
| `LogView`      | Технический поток записей         |

## 16.15. Kanban

```dart
CarpenterKanban<Item, ItemId, GroupId>(
  groups: state.groups,
  items: state.items,
  groupOf: groupOf,
  keyOf: keyOf,
  selection: state.selection,
  onEvent: cubit.handleKanbanEvent,
);
```

Поддерживает:

* columns;
* counts;
* collapsed groups;
* per-column loading;
* drag between groups;
* reorder;
* selection;
* WIP indicator;
* virtualization;
* swimlanes как extension.

## 16.16. Calendar, Agenda, Scheduler, Gantt

```text
CalendarView:
    month/week/day events

Agenda:
    последовательный список

Scheduler:
    resources × time

PlanningBoard:
    milestones/tasks

GanttView:
    duration + dependencies
```

## 16.17. Comparison

```dart
CarpenterComparison<T>(
  items: selected,
  attributes: definitions,
  highlightDifferences: true,
);
```

Поддерживает:

* sticky attribute column;
* differences only;
* missing values;
* mobile pairwise fallback.

## 16.18. DashboardPanel

```dart
CarpenterDashboardPanel(
  title: 'Выручка',
  actions: actions,
  child: chart,
  movable: true,
  resizable: true,
);
```

Panel является building block. Dashboard является page pattern.

## 16.19. Полный каталог collections

```text
accordion
activity_feed
agenda
attribute_editor
breadcrumbs
bulk_selector
calendar_view
card_collection
carousel
comments
comparison
data_grid
data_list
definition_list
filter_bar
form
form_section
gallery
gantt_view
grouped_collection
kanban
key_value_list
list_view
log_view
notification_list
pagination
planning_board
property_filter
saved_filters
scheduler
search_results
sorting
stepper
table
tabs
timeline
token_group
transfer_list
tree_table
tree_view
```

---

# 17. Data visualization

## 17.1. Общий контракт

```dart
@immutable
final class CarpenterChartSpec {
  const CarpenterChartSpec({
    required this.title,
    required this.description,
    required this.series,
    this.axes = const [],
    this.annotations = const [],
    this.legend,
    this.interaction = const ChartInteractionPolicy(),
  });

  final String title;
  final String description;
  final List<CarpenterChartSeries> series;
  final List<CarpenterChartAxis> axes;
  final List<CarpenterChartAnnotation> annotations;
  final CarpenterChartLegend? legend;
  final ChartInteractionPolicy interaction;
}
```

Backend-specific типы наружу не выпускаются.

## 17.2. Составные части

```text
ChartTitle
ChartDescription
ChartPlot
ChartSeries
ChartAxis
ChartGrid
ChartLegend
ChartTooltip
ChartCrosshair
ChartAnnotation
ChartThreshold
ChartReferenceLine
ChartBrush
ChartZoom
ChartNavigator
ChartSelection
ChartAccessibleData
```

## 17.3. Interaction

```dart
@immutable
final class ChartInteractionPolicy {
  const ChartInteractionPolicy({
    this.hover = true,
    this.focus = true,
    this.select = false,
    this.multiSelect = false,
    this.brush = false,
    this.zoom = false,
    this.pan = false,
    this.drillDown = false,
  });

  final bool hover;
  final bool focus;
  final bool select;
  final bool multiSelect;
  final bool brush;
  final bool zoom;
  final bool pan;
  final bool drillDown;
}
```

## 17.4. Accessibility

Каждый график обязан иметь:

* title;
* description;
* textual summary;
* keyboard navigation, если интерактивен;
* non-color distinction;
* accessible data table или list;
* semantic announcements;
* reduced-motion variant.

## 17.5. Типы графиков

| Тип            | Основное применение                 |
| -------------- | ----------------------------------- |
| `Metric`       | Одно ключевое значение              |
| `Sparkline`    | Компактная тенденция                |
| `Line`         | Время и непрерывные изменения       |
| `Area`         | Magnitude и накопление              |
| `Bar`          | Сравнение категорий                 |
| `Histogram`    | Распределение                       |
| `Scatter`      | Связь двух числовых переменных      |
| `BoxPlot`      | Quartiles и outliers                |
| `Heatmap`      | Матрица интенсивности               |
| `Pie/Donut`    | Небольшое число частей целого       |
| `Treemap`      | Иерархическое part-to-whole         |
| `Waterfall`    | Вклад изменений в итог              |
| `Bullet`       | Actual, target, qualitative ranges  |
| `Gauge`        | Позиция внутри известного диапазона |
| `Funnel`       | Стадии и drop-off                   |
| `Sankey`       | Потоки                              |
| `NetworkGraph` | Общие связи                         |
| `Topology`     | Инфраструктурные связи              |

## 17.6. Pie и donut

Используются только для небольшого числа различимых частей.

Не использовать для:

* точного сравнения близких значений;
* десятков slices;
* отрицательных значений;
* категорий без ясной part-to-whole семантики.

Bar chart обычно честнее.

## 17.7. Responsive simplification

При уменьшении пространства график может:

1. Сократить ticks.
2. Свернуть legend.
3. Скрыть secondary grid.
4. Перейти к horizontal bars.
5. Показать summary и scrollable plot.
6. Перенести detail в bottom sheet.
7. Скрыть второстепенные series.
8. Превратиться в metric/sparkline.
9. Предоставить таблицу отдельно.

## 17.8. Backend adapter

```dart
abstract interface class CarpenterChartRenderer {
  Widget buildChart(
    BuildContext context,
    CarpenterChartSpec spec,
    CarpenterChartState state,
    ValueChanged<CarpenterChartEvent> onEvent,
  );
}
```

Адаптеры:

```text
carpenter_charts_fl
carpenter_charts_graphic
carpenter_charts_syncfusion
```

---

# 18. Layout и экранные регионы

## 18.1. ApplicationShell

```dart
CarpenterApplicationShell(
  header: appHeader,
  navigation: navigationRegion,
  body: primaryRegion,
  auxiliary: auxiliaryRegion,
  notifications: notificationRegion,
  toasts: toastRegion,
  overlays: overlayRegion,
);
```

Отвечает за:

* общую геометрию;
* safe areas;
* persistent regions;
* focus boundaries;
* layer ordering;
* global shortcuts;
* overlay/toast hosts;
* adaptive policy;
* restoration scopes.

Cloudscape `AppLayout` аналогично объединяет content, navigation, tools и secondary panels в единую page shell.

## 18.2. Регионы

```dart
enum CarpenterRegionRole {
  primary,
  navigation,
  secondary,
  auxiliary,
  detail,
  tools,
  notifications,
  toasts,
  overlay,
}
```

### PrimaryRegion

Главная задача страницы.

### NavigationRegion

Глобальная или локальная навигация.

### SecondaryRegion

Второй равноправный рабочий контекст.

### AuxiliaryRegion

Дополнительный контекст:

```text
inspector
help
metadata
AI assistant
preview
contextual filters
```

### DetailRegion

Детали выбранного объекта.

### ToolsRegion

Инструменты редактора, canvas или сложной рабочей области.

### NotificationRegion

Долгоживущие уведомления.

### ToastRegion

Краткоживущий feedback.

### OverlayRegion

Menus, dialogs, popovers и modal barriers.

## 18.3. AdaptiveRegion

```dart
CarpenterAdaptiveRegion(
  role: CarpenterRegionRole.auxiliary,
  policy: CarpenterAdaptiveRegionPolicy.inspector,
  child: inspector,
);
```

```dart
@immutable
final class CarpenterAdaptiveRegionPolicy {
  const CarpenterAdaptiveRegionPolicy({
    required this.wide,
    required this.medium,
    required this.compact,
  });

  final RegionPresentation wide;
  final RegionPresentation medium;
  final RegionPresentation compact;
}
```

Возможные presentations:

```text
inlineStart
inlineEnd
sidePanel
bottomPanel
bottomSheet
overlayDrawer
fullScreen
route
hidden
```

Решение принимает сочетание:

```text
region role
available geometry
input capabilities
content minimum size
navigation state
user preference
```

## 18.4. SplitView

```dart
CarpenterSplitView(
  primary: master,
  secondary: detail,
  direction: CarpenterSplitDirection.auto,
  resizable: true,
  initialRatio: .64,
  minPrimaryExtent: 360,
  minSecondaryExtent: 320,
  collapsePolicy: SplitCollapsePolicy.secondaryFirst,
);
```

SplitView знает геометрию, но не selection.

## 18.5. MasterDetail

```dart
CarpenterMasterDetail<PaymentId>(
  selectedId: state.selectedId,
  master: paymentList,
  detail: state.selectedId == null
      ? const CarpenterNoSelectionState()
      : paymentDetail,
  onCloseDetail: cubit.clearSelection,
);
```

Правила:

* desktop: side-by-side;
* compact: detail обычно full-screen state/route;
* back возвращает к master;
* scroll и selection сохраняются;
* detail loading не блокирует master.

## 18.6. SplitCollection

```text
collection
+
быстрый preview/details выбранного item
```

Подходит для:

* triage;
* monitoring;
* почты;
* логов;
* быстрого просмотра карточек.

Не заменяет ObjectPage.

## 18.7. PageHeader

```dart
CarpenterPageHeader(
  breadcrumbs: breadcrumbs,
  title: title,
  subtitle: subtitle,
  status: status,
  metadata: metadata,
  actions: actions,
);
```

Поддерживает:

* responsive action overflow;
* title wrapping;
* sticky/condensed state;
* object identity;
* status;
* selection mode replacement.

## 18.8. Toolbar

```dart
CarpenterToolbar(
  groups: [
    CarpenterActionGroup(...),
    CarpenterActionGroup(...),
  ],
  overflowPolicy:
      CarpenterActionOverflowPolicy.automatic,
);
```

Toolbar управляет:

* groups;
* separators;
* priorities;
* keyboard traversal;
* overflow;
* compact presentation;
* toggle state;
* tooltips;
* density.

## 18.9. Navigation

Одна navigation model имеет разные presentations:

```text
SidebarNavigation
NavigationRail
NavigationBar
NavigationDrawer
TabNavigation
```

```dart
CarpenterNavigationModel(
  destinations: destinations,
  selectedId: routeId,
  onSelect: router.go,
);
```

Descriptor не должен хранить произвольные widgets.

## 18.10. Action overflow

```text
wide desktop:
    essential + normal visible
    overflow hidden in menu

narrow desktop:
    essential visible
    normal + overflow in menu

mobile:
    finalizing primary -> bottom action
    contextual -> app bar
    remaining -> overflow
```

## 18.11. FullScreenWorkspace

```dart
CarpenterFullScreenWorkspace(
  tools: toolsRegion,
  canvas: primary,
  inspector: auxiliary,
  statusBar: footer,
);
```

Для:

```text
editor
diagram
canvas
terminal
map
large data editor
```

---

# 19. Patterns и типовые страницы

Pattern решает пользовательскую задачу и имеет право быть opinionated.

## 19.1. HeaderActions

```text
PageHeader
    title
    status
    metadata
    primary actions
    secondary actions
    overflow
```

Правила:

* одна high-prominence action;
* destructive action не является default focus без причины;
* actions группируются по смыслу;
* mobile placement определяется priority;
* selection mode может заменить обычные actions bulk actions.

## 19.2. CollectionPage

```text
PageHeader
CollectionToolbar
Search
Filters
ViewPreferences
CollectionView
Pagination / ProgressiveLoad
Optional DetailRegion
```

## 19.3. ListReport

Используется, когда пользователь:

* ищет объекты;
* фильтрует;
* сортирует;
* сравнивает атрибуты;
* выполняет действия;
* переходит к деталям.

## 19.4. Worklist

Используется для очереди работы:

```text
согласования
модерация
входящие
ошибки обработки
платежи к проверке
```

Особенности:

* status buckets;
* ownership;
* next item;
* age/SLA;
* bulk processing;
* keyboard-first workflow.

## 19.5. ObjectPage

```text
ObjectHeader
Status
PrimaryActions
SummaryAttributes
Sections
RelatedCollections
History
OptionalAuxiliaryRegion
```

Подходит для сущности с:

* устойчивой identity;
* несколькими sections;
* собственными actions;
* отдельным route;
* глубоким workflow.

## 19.6. DetailPage

Облегчённая страница объекта для detail region или короткого route.

## 19.7. TabbedDetail

```text
Общее
Документы
Платежи
История
```

Критические summary/status остаются видимыми.

## 19.8. FormPage

```text
PageHeader
ErrorSummary
FormSections
StickyFooterActions
UnsavedChangesHandling
```

Поддерживает:

* dirty guard;
* async validation;
* save progress;
* server errors;
* focus first invalid;
* draft;
* autosave;
* read-only.

## 19.9. CreatePage

Дополнительно:

* defaults;
* duplicate/template;
* idempotency;
* post-create navigation;
* recoverable draft.

## 19.10. EditPage

Дополнительно:

* original snapshot;
* dirty diff;
* optimistic concurrency;
* reload latest;
* discard;
* field-level server errors;
* audit metadata.

## 19.11. WizardPage

Используется для действительно сложного последовательного процесса.

```text
steps
current step
validation
optional steps
review
finish
save/resume
```

Форма из трёх полей не становится лучше от того, что её размазали по четырём экранам.

## 19.12. Dashboard

Отвечает на вопросы:

```text
что происходит?
где проблема?
что требует внимания?
```

Содержит:

* metrics;
* charts;
* status summaries;
* work queues;
* filters/time range;
* drill-down;
* configurable panels.

Различать:

```text
static dashboard
configurable dashboard
```

## 19.13. AnalyticalList

```text
filters
KPIs
charts
table/list
selection
drill-down
actions
```

Пользователь не только наблюдает, но исследует набор сущностей и действует над ним.

## 19.14. SearchPage

```text
query
scope
facets
filters
sort
results
snippets
preview
history
zero results
```

## 19.15. SettingsPage

```text
section navigation
search
groups
fields
save semantics
restart markers
danger zone
```

Instant settings и explicit-save settings должны быть визуально различимы.

## 19.16. ComparisonPage

```text
objects horizontally
attributes vertically
difference highlighting
missing values
actions
```

## 19.17. FullScreenTask

Для editor/canvas/terminal/diagram.

Сохраняет:

* exit;
* save state;
* command palette;
* shortcuts;
* tools;
* inspector;
* status bar.

## 19.18. InitialPage

```text
выберите организацию
откройте проект
найдите документ
создайте первый объект
```

## 19.19. Empty, zero, error

### Empty

```text
Объектов ещё нет.
[Создать]
```

### ZeroResults

```text
По текущим фильтрам ничего не найдено.
[Сбросить фильтры]
```

### Error

```text
Не удалось загрузить платежи.
[Повторить]
[Диагностика]
```

## 19.20. Offline и conflict

Offline state показывает:

* cached data;
* freshness;
* queued mutations;
* unavailable actions;
* retry;
* conflicts.

Conflict state показывает:

* local version;
* remote version;
* diff;
* reload;
* overwrite, если допустимо;
* manual merge.

## 19.21. Destructive flow

Предпочтение:

1. Reversible action + Undo.
2. Confirmation для необратимого действия.
3. Typed confirmation только для критического.
4. Progress и partial results для bulk destructive operation.

## 19.22. Полный каталог patterns

```text
analytical_list
collection_page
comparison_page
create_page
dashboard
detail_page
edit_page
form_page
full_screen_task
header_actions
footer_actions
initial_page
list_report
master_detail_page
object_page
onboarding
overview_page
search_page
settings_page
split_collection
tabbed_detail
wizard_page
worklist

states/
  conflict_state
  empty_state
  error_state
  no_selection_state
  offline_state
  partial_error_state
  permission_state
  stale_state
  zero_results
```

---

# 20. Готовые библиотеки

Список проверен на 23 августа 2026 года. Версии не следует вшивать в архитектурный документ: перед pinning проверяются changelog, SDK constraints и license.

Главное правило:

```text
заимствовать rendering engine
и platform integration

не выпускать типы движка
в публичный Carpenter API
```

## 20.1. State и data

### flutter_bloc

* Использовать в application/features.
* Cubit для командного state API.
* Bloc для сложных event-driven workflows.
* Не добавлять в core Carpenter.

### Riverpod

* Composition.
* Dependency lifecycle.
* Repositories.
* Feature factories.
* Shared reactive data.
* Не добавлять в core.

### Drift

* Typed persistence.
* Reactive local streams.
* Transactions.
* Migrations.
* Offline cache.
* Только под repository.

### Freezed

* Immutable state.
* Sealed events.
* `copyWith`.
* Полезен приложению и adapters.
* Не должен быть обязательным для пользователя Carpenter.

### Reactive Forms

* Сложные nested forms.
* Form arrays.
* Validation streams.
* Хороший кандидат на form adapter.
* `FormControl` и `FormGroup` не выпускаются наружу.

## 20.2. Tables и scrolling

### two_dimensional_scrollables

Официальный Flutter package предоставляет lazy `TableView` и `TreeView`, двухмерный scroll и возможности pinned rows/columns.

**Вердикт:** предпочтительный низкоуровневый фундамент собственного Table/Tree/DataGrid. Carpenter добавляет semantics, query, selection, sorting, filtering и preferences.

### PlutoGrid

**Вердикт:** опциональный backend DataGrid.

Хорош для:

* editing;
* keyboard navigation;
* filtering;
* sorting;
* grid-like interaction.

Его types и state model должны быть изолированы.

### Syncfusion DataGrid

Поддерживает большой набор enterprise grid-возможностей. Требует явного решения по коммерческой либо подходящей Community license.

### data_table_2

Допустим как временный backend умеренно сложной Material-like table.

Не следует строить вокруг него долгосрочный cross-platform DataGrid API.

### infinite_scroll_pagination

Хороший helper progressive loading.

Query, stale data и load states остаются Carpenter contracts.

### super_sliver_list

Использовать после benchmark, если стандартный sliver действительно становится проблемой.

## 20.3. Overlay и feedback

### OverlayPortal

Предпочтительный Flutter foundation.

Поверх него пишутся:

```text
CarpenterOverlayController
CarpenterAnchoredOverlay
collision policy
focus policy
dismiss policy
layer ownership
```

### flutter_portal

Допустим, если встроенного `OverlayPortal` недостаточно для конкретной composition.

### toastification

Может быть временной реализацией или источником идей.

Core всё равно должен владеть:

```text
ToastDescriptor
ToasterController
ToastRegion
```

### skeletonizer

Хороший internal rendering helper для skeleton states.

## 20.4. Native integration

### super_drag_and_drop

Сильный кандидат для native cross-application drag-and-drop.

Публичная документация пакета всё ещё предупреждает об экспериментальном статусе, поэтому необходимы adapter isolation, pinning и regression tests.

### super_clipboard

Кандидат для rich/native clipboard.

### file_selector

Официальный Flutter plugin для системного выбора файлов.

## 20.5. Charts

### fl_chart

Хороший open-source backend для P0/P1:

```text
line
bar
pie
scatter
radar
```

Требуется Carpenter-слой theme, semantics, selection и accessibility.

### graphic

Подходит для declarative grammar-of-graphics подхода и более сложной композиции.

### Syncfusion Charts

Сильный enterprise backend при приемлемой license.

### GraphView

Допустим для небольших network graphs. Большая topology потребует отдельной архитектуры.

## 20.6. Documentation и QA

### Widgetbook

Обязательный кандидат для живого каталога компонентов и use cases. Он позволяет собирать component catalog и проверять состояния изолированно.

### Alchemist

Хороший golden-test harness для state matrices.

### accessibility_tools

Полезен в development/test environment для поиска типичных accessibility-проблем. Не заменяет semantic tests и screen-reader review.

## 20.7. Code generation и lint

### build_runner

Для:

* theme classes;
* token accessors;
* manifests;
* documentation index;
* generated adapters.

### source_gen

Для генерации вокруг Dart annotations и source model.

### custom_lint

Основа `carpenter_lints`.

### Theme Tailor

Может сократить boilerplate `ThemeExtension`, но не заменяет semantic role architecture.

## 20.8. Что писать самим

| Область                       | Решение                                      |
| ----------------------------- | -------------------------------------------- |
| Domain-scoped role model      | Писать                                       |
| Action descriptors и registry | Писать поверх Flutter Actions                |
| Token compiler contract       | Писать                                       |
| OKLCH generation policy       | Писать, используя Color.js                   |
| Theme resolution              | Писать                                       |
| Toaster controller/region     | Писать                                       |
| AdaptiveRegion                | Писать                                       |
| Collection contracts          | Писать                                       |
| Page patterns                 | Писать                                       |
| Accessibility policies        | Писать                                       |
| Table viewport                | Использовать two-dimensional engine          |
| Native drag                   | Обернуть super_drag_and_drop                 |
| Clipboard                     | Flutter services + super_clipboard adapter   |
| Files                         | Обернуть file_selector                       |
| Charts                        | Backend adapters                             |
| DataGrid                      | PlutoGrid/Syncfusion adapter                 |
| Forms                         | Carpenter contracts + Reactive Forms adapter |
| Catalog                       | Widgetbook                                   |
| Golden                        | Alchemist                                    |
| Lints                         | custom_lint                                  |

---

# 21. Testing и quality gates

## 21.1. Token compiler

Обязательны:

* schema validation;
* alias resolution;
* cycle detection;
* missing tokens;
* duplicate output names;
* deterministic generation;
* stable sorting;
* no NaN/Infinity;
* source locations в diagnostics.

## 21.2. Palette tests

* Monotonic lightness.
* Target gamut.
* No unintended hue jumps.
* Neutral chroma limits.
* Stable seed output.
* Contrast pairs.
* Focus ring.
* Dark theme.
* High contrast.
* Delta E report.
* Color-vision simulation для categorical palettes.

## 21.3. Widget tests

Для интерактивных компонентов:

```text
pointer
touch
keyboard
focus
disabled
readOnly
selected
error
loading
semantics
callbacks
restoration
```

## 21.4. Golden matrix

```text
brightness:
    light
    dark

contrast:
    standard
    high

density:
    compact
    comfortable
    spacious

text scale:
    1.0
    1.3
    2.0

direction:
    LTR
    RTL

width:
    compact
    medium
    wide

state:
    rest
    hover
    focus
    pressed
    selected
    disabled
    loading
    error
```

Не нужен полный Cartesian product для каждого компонента. Нужен pairwise набор и отдельные критические combinations.

## 21.5. Content stress

Проверять:

* пустой текст;
* длинный текст;
* длинное слово;
* кириллицу;
* латиницу;
* цифры;
* RTL;
* emoji;
* 200% text scale;
* missing image;
* slow loading;
* duplicate items;
* 0/1/1000 items.

## 21.6. Keyboard contracts

```text
Tab / Shift+Tab
Enter / Space
Arrow keys
Home / End
PageUp / PageDown
Escape
Context menu key
Ctrl/Cmd+A
Ctrl/Cmd+C
Ctrl/Cmd+V
Delete
documented shortcuts
```

## 21.7. Performance

Benchmark:

* first layout;
* scroll frame time;
* rebuild count;
* memory;
* 1k/10k/100k data models;
* table resize;
* tree expand;
* drag session;
* large chart;
* theme switch;
* token lookup.

---

# 22. Carpenter lints

## 22.1. Foundation

```text
no_raw_color_in_component
no_raw_radius_in_component
no_raw_spacing_in_component
no_raw_duration_in_component
no_direct_palette_token_in_app
prefer_domain_role
no_global_color_role
```

## 22.2. Components

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

## 22.3. Architecture

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

## 22.4. Accessibility

```text
icon_button_requires_semantic_label
interactive_component_requires_action
tooltip_cannot_replace_label
no_color_only_status
menu_item_requires_label
chart_requires_accessible_data
```

## 22.5. Quick fixes

```text
Text -> CarpenterText
IconButton -> CarpenterIconButton
MaterialStateProperty -> WidgetStateProperty
showDialog -> CarpenterDialogController
```

Автоматический fix не должен угадывать semantic role без достаточной уверенности.

---

# 23. Публичный API

## 23.1. Barrel exports

```dart
library carpenter;

export 'src/foundation/actions/action.dart';
export 'src/foundation/theme/carpenter_theme.dart';
export 'src/components/basic/button.dart';
export 'src/components/collections/table.dart';
export 'src/components/layout/patterns/list_report.dart';
```

`src/internal` не экспортируется.

## 23.2. Именование

* Enum в единственном числе.
* State object заканчивается на `State`.
* Event: `SearchChanged`, `RefreshRequested`.
* Callback: `onChanged`, `onPressed`, `onEvent`.
* Descriptor не называется controller.
* Controller предоставляет imperative API.
* Policy описывает правила выбора.
* Adapter соединяет Carpenter с внешней библиотекой.
* Renderer реализует backend.

## 23.3. Constructors

```dart
CarpenterProgress.determinate(...)
CarpenterProgress.indeterminate(...)
CarpenterButton.toggle(...)
```

Не создавать:

```dart
CarpenterButton.red()
CarpenterButton.blue()
```

## 23.4. Escape hatches

Допустимы:

```text
itemBuilder
cellBuilder
emptyBuilder
overlayBuilder
formatter
renderer
```

Не нужно давать `style: dynamic` в каждом компоненте.

## 23.5. Stability

```text
experimental
beta
stable
deprecated
```

Stable API следует semantic versioning.

Token names также являются API.

---

# 24. Governance

## 24.1. Жизненный цикл компонента

```text
1. Локальная реализация
2. Сбор повторяющихся use cases
3. Проверка существующих abstractions
4. RFC
5. Semantic API review
6. Accessibility review
7. Prototype
8. Production use минимум в двух контекстах
9. Documentation + tests
10. Stable inclusion
```

Не каждый локальный widget должен немедленно стать компонентом design system.

## 24.2. RFC

```text
problem
user tasks
existing solutions
why composition is insufficient
proposed semantics
states/events
adaptive behavior
accessibility
token needs
backend choice
migration
alternatives
```

## 24.3. ADR

```text
ADR-001 Domain-scoped color roles
ADR-002 Controlled-first components
ADR-003 DTCG token source
ADR-004 OKLCH generation
ADR-005 Chart renderer adapters
ADR-006 Riverpod composition
ADR-007 Drift behind repositories
ADR-008 Adaptive semantic regions
ADR-009 No public layout primitives
```

## 24.4. Stable component criteria

* Два независимых production use cases.
* Документированная семантика.
* Все public states.
* Keyboard contract.
* Accessibility review.
* Light/dark/high contrast.
* Responsive behavior.
* Golden tests.
* Нет backend types.
* Migration path.
* Owner.

---

# 25. Roadmap

## P0. Несущая система

Foundation:

```text
domain-scoped roles
shape/size/spacing/density
typography
motion
elevation/layers
breakpoints/capabilities
theme access
DTCG compiler
OKLCH palette generator
contrast reports
```

Basic:

```text
Text
Icon
Button
IconButton
ButtonGroup
SplitButton
Link
Input
TextArea
Select
Checkbox
Radio
RadioGroup
Switch
Avatar
Badge
StatusIndicator
Card
Divider
Progress
```

Behaviour:

```text
Overlay
Tooltip
Popover
Menu
Dropdown
Dialog
Flyout
Alert
Toast
Toaster
Loader
Skeleton
Selection
Disclosure
Resizable
```

Collections:

```text
ListView
DataList
Table
DefinitionList
Form
TreeView
CardCollection
Tabs
Accordion
Breadcrumbs
Pagination
FilterBar
```

Layout:

```text
ApplicationShell
PageHeader
Toolbar
AdaptiveRegion
SplitView
```

Patterns:

```text
HeaderActions
CollectionPage
ListReport
ObjectPage
FormPage
Empty
ZeroResults
Error
```

Infrastructure:

```text
Widgetbook
golden matrix
custom lints
```

## P1. Enterprise-ядро

```text
DataGrid foundation
PropertyFilter
CollectionPreferences
MasterDetail
SplitCollection
Worklist
Create/Edit
InlineEdit
Undo
Drag-and-drop
FileInput
CommandPalette
ActivityFeed
Timeline
Kanban
Metric
Sparkline
Line
Bar
Area
```

## P2. Analytics и workflows

```text
Dashboard
AnalyticalList
Wizard
SearchPage
Comparison
CalendarView
Agenda
Scheduler
Gantt
advanced charts
chart selection
zoom
brush
configurable dashboard
offline/conflict
```

## P3. Специализированные подсистемы

```text
Topology
large graph
maps
rich text
document editor
diagram/canvas
advanced spreadsheet
plugin marketplace
Figma synchronization
```

## 25.1. Первый вертикальный срез

```text
tokens + roles
    ↓
Button / Input / Status / Text
    ↓
Overlay / Menu / Toast
    ↓
Collection contracts
    ↓
Table
    ↓
ApplicationShell + AdaptiveRegion
    ↓
ListReport
    ↓
реальная PaymentsPage
```

Не начинать с реализации пятидесяти basic widgets. Архитектуру надо проверить на настоящей странице сверху вниз.

---

# 26. Эталонная интеграция

## 26.1. Repository

```dart
abstract interface class PaymentsRepository {
  Stream<PaymentPage> watchPage(PaymentQuery query);

  Future<void> delete(PaymentId id);

  Future<void> restore(Payment payment);
}
```

Drift implementation остаётся ниже этого интерфейса.

## 26.2. Cubit

```dart
final class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit(this.repository)
      : super(PaymentsState.initial()) {
    _subscribe(state.query);
  }

  final PaymentsRepository repository;

  StreamSubscription<PaymentPage>? _subscription;

  void setSearch(String value) {
    final query = state.query.copyWith(
      search: value,
      cursor: null,
    );

    emit(state.copyWith(query: query));
    _subscribe(query);
  }

  void setSelection(
    CarpenterSelectionState<PaymentId> selection,
  ) {
    emit(state.copyWith(selection: selection));
  }

  void open(PaymentId id) {
    emit(state.copyWith(selectedId: id));
  }

  void _subscribe(PaymentQuery query) {
    _subscription?.cancel();

    emit(
      state.copyWith(
        collection: Loading(
          previous: state.collection.valueOrNull,
        ),
      ),
    );

    _subscription = repository.watchPage(query).listen(
      (page) {
        emit(
          state.copyWith(
            collection: Ready(page),
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            collection: Failed(
              error,
              previous: state.collection.valueOrNull,
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
```

## 26.3. Riverpod composition

```dart
final paymentsRepositoryProvider =
    Provider<PaymentsRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return DriftPaymentsRepository(database);
});

final paymentsCubitProvider =
    Provider.autoDispose<PaymentsCubit>((ref) {
  final repository =
      ref.watch(paymentsRepositoryProvider);

  final cubit = PaymentsCubit(repository);

  ref.onDispose(cubit.close);

  return cubit;
});
```

## 26.4. Page

```dart
final class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final cubit = ref.watch(paymentsCubitProvider);

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<
          PaymentsCubit,
          PaymentsState
        >(
        builder: (context, state) {
          return CarpenterListReport<
              Payment,
              PaymentId
            >(
            header: CarpenterPageHeader(
              title: 'Платежи',
              actions: [
                CarpenterAction(
                  id: const CarpenterActionId(
                    'payments.create',
                  ),
                  label: 'Создать',
                  icon: CarpenterIcons.add,
                  colorRole:
                      ActionColorRole.primary,
                  prominence:
                      ActionProminence.high,
                  onInvoke: () =>
                      context.go('/payments/new'),
                ),
              ],
            ),
            query:
                state.query.toCarpenterQuery(),
            collection:
                state.collection.map(
              (page) =>
                  page.toCarpenterSnapshot(),
            ),
            selection: state.selection,
            table: CarpenterTable(
              columns: paymentColumns,
              keyOf: (payment) => payment.id,
            ),
            detail: CarpenterAdaptiveRegion(
              role:
                  CarpenterRegionRole.detail,
              policy:
                  CarpenterRegionPolicies
                      .masterDetail,
              child: state.selectedId == null
                  ? const CarpenterNoSelectionState()
                  : PaymentDetails(
                      id: state.selectedId!,
                    ),
            ),
            onEvent: (event) {
              switch (event) {
                case CarpenterSearchChanged(
                    :final value
                  ):
                  cubit.setSearch(value);

                case CarpenterSelectionChanged(
                    :final value
                  ):
                  cubit.setSelection(value);

                case CarpenterItemActivated(
                    :final key
                  ):
                  cubit.open(key);

                default:
                  break;
              }
            },
          );
        },
      ),
    );
  }
}
```

Распределение ответственности:

```text
Carpenter:
    rendering
    focus
    keyboard
    adaptive regions
    UI events

Cubit:
    query
    selection
    subscriptions
    mutations

Riverpod:
    dependencies
    lifecycle

Drift:
    persistence
    reactive query
```

---

# 27. Итоговый каталог

```text
lib/
├── carpenter.dart
├── foundation/
│   ├── accessibility/
│   ├── actions/
│   ├── breakpoints/
│   ├── capabilities/
│   ├── generated/
│   ├── roles/
│   │   ├── color/
│   │   ├── density/
│   │   ├── elevation/
│   │   ├── layer/
│   │   ├── motion/
│   │   ├── opacity/
│   │   ├── shape/
│   │   ├── size/
│   │   ├── spacing/
│   │   └── typography/
│   ├── state/
│   └── theme/
│
├── components/
│   ├── basic/
│   ├── behaviour/
│   ├── collections/
│   ├── dataviz/
│   └── layout/
│       ├── regions/
│       └── patterns/
│
└── internal/
    ├── diagnostics/
    ├── geometry/
    ├── rendering/
    └── utilities/
```

---

# 28. Ключевые решения

1. `ColorRoles` переименовывается в `ActionColorRole`.
2. Action, layout, content, field, feedback, navigation, selection, focus и dataviz получают отдельные семейства.
3. Цветовая роль, prominence, slot и state являются разными осями.
4. Carpenter controlled-first.
5. Bloc, Cubit, Riverpod и Drift не входят в core.
6. Riverpod используется для composition/lifecycle.
7. Bloc/Cubit используются для feature state и workflows.
8. Drift находится под repository.
9. Layout primitives не являются целью Carpenter.
10. Semantic regions адаптируются по назначению.
11. Toast состоит из descriptor, controller и region.
12. Table, DataGrid, Tree и charts имеют backend-neutral API.
13. DTCG JSON является canonical token format.
14. YAML является authoring layer.
15. OKLCH генерируется build-time с gamut mapping.
16. Components не принимают произвольные цвета, радиусы и размеры в стандартном API.
17. Patterns являются частью design system.
18. Accessibility и keyboard входят в definition of done.
19. Внешние библиотеки изолируются adapters.
20. Новый stable component появляется после нескольких реальных use cases.

---

# 29. Источники

## Design systems

* [Gravity UI Libraries](https://gravity-ui.com/libraries)
* [GitLab Pajamas: Navigating the design system](https://design.gitlab.com/get-started/navigating-pajamas/)
* [GitLab Pajamas: Objects](https://design.gitlab.com/objects/overview/)
* [AWS Cloudscape: View resources](https://cloudscape.design/patterns/resource-management/view/)
* [AWS Cloudscape: App layout](https://cloudscape.design/components/app-layout/)
* [Intercom: The Full Stack Design System](https://www.intercom.com/blog/the-full-stack-design-system/)
* [SAP Fiori Design Web](https://experience.sap.com/fiori-design-web/)
* [Elastic UI: Data visualization](https://eui.elastic.co/docs/dataviz/)
* [PatternFly: Usage and behavior](https://www.patternfly.org/design-foundations/usage-and-behavior/)
* [GitHub Primer](https://primer.style/product/)
* [Atlassian Design System](https://atlassian.design/)
* [Palantir Blueprint](https://blueprintjs.com/docs/)
* [VMware Clarity](https://clarity.design/)
* [IBM Carbon](https://carbondesignsystem.com/)

## Tokens и цвет

* [DTCG Format Module 2025.10](https://www.designtokens.org/tr/2025.10/format/)
* [DTCG Color Module 2025.10](https://www.designtokens.org/tr/2025.10/color/)
* [CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/)
* [Oklab by Björn Ottosson](https://bottosson.github.io/posts/oklab/)
* [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
* [Terrazzo](https://terrazzo.app/docs/)
* [Style Dictionary](https://styledictionary.com/)
* [Color.js](https://colorjs.io/)
* [Culori](https://culorijs.org/)

## Flutter

* [WidgetState](https://api.flutter.dev/flutter/widgets/WidgetState.html)
* [OverlayPortal](https://api.flutter.dev/flutter/widgets/OverlayPortal-class.html)
* [Actions](https://api.flutter.dev/flutter/widgets/Actions-class.html)
* [Shortcuts](https://api.flutter.dev/flutter/widgets/Shortcuts-class.html)
* [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)

## State и data

* [Bloc](https://bloclibrary.dev/)
* [flutter_bloc](https://pub.dev/packages/flutter_bloc)
* [Riverpod](https://riverpod.dev/)
* [Drift](https://drift.simonbinder.eu/)
* [Freezed](https://pub.dev/packages/freezed)
* [Reactive Forms](https://pub.dev/packages/reactive_forms)

## Rendering engines

* [two_dimensional_scrollables](https://pub.dev/packages/two_dimensional_scrollables)
* [PlutoGrid](https://pub.dev/packages/pluto_grid)
* [Syncfusion DataGrid](https://pub.dev/packages/syncfusion_flutter_datagrid)
* [super_drag_and_drop](https://pub.dev/packages/super_drag_and_drop)
* [super_clipboard](https://pub.dev/packages/super_clipboard)
* [file_selector](https://pub.dev/packages/file_selector)
* [fl_chart](https://pub.dev/packages/fl_chart)
* [graphic](https://pub.dev/packages/graphic)
* [Syncfusion Charts](https://pub.dev/packages/syncfusion_flutter_charts)

## Tooling и QA

* [Widgetbook](https://pub.dev/packages/widgetbook)
* [Alchemist](https://pub.dev/packages/alchemist)
* [accessibility_tools](https://pub.dev/packages/accessibility_tools)
* [custom_lint](https://pub.dev/packages/custom_lint)
* [build_runner](https://pub.dev/packages/build_runner)
* [source_gen](https://pub.dev/packages/source_gen)
* [Theme Tailor](https://pub.dev/packages/theme_tailor)

---

# 30. Итоговая формула

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

Carpenter становится полезным не тогда, когда у него появляется собственная версия каждого Flutter widget.

Он становится полезным, когда приложение перестаёт заново изобретать:

```text
как выглядит действие
как выражается состояние
как работает selection
как показывается коллекция
как открываются детали
как адаптируется дополнительный регион
как устроена рабочая страница
как система сообщает об ошибке
как пользователь восстанавливается после ошибки
```

Именно это отделяет UI-платформу от склада кнопок с одинаково закруглёнными углами.
