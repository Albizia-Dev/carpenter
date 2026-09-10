# Голдены реальных компоновок

Сценарии импортируют тот же код, что и Widgetbook, из
`lib/use_cases/samples/dsktp_layouts.dart` и
`lib/use_cases/samples/dsktp_collections.dart`. Описание источников, дефектов и
матрицы: `../../../docs/dsktp-layout-review.md`.

Onest Regular и SemiBold скопированы из `dsktp/assets/fonts/onest`.
Лицензия: `../../../test/goldens/fonts/OFL.txt` (SIL Open Font License 1.1).
Общие шрифты находятся в `../../../test/goldens/fonts`.
Шрифты загружаются локально через FontLoader. Для SVG используется
`vg.waitForPendingDecodes()`, чтобы эталон не сохранял пустые placeholders.

Проверка из каталога Widgetbook:

```sh
flutter test --no-pub test/goldens/dsktp_layouts_golden_test.dart test/goldens/dsktp_collections_golden_test.dart
```

Коллекции включают списки платежей и счетов, дерево папок, вложенные
раскрывающиеся секции аудита. Сохраняются также нижние части длинных списков
и состояние после закрытия секции. Сборка Widgetbook для этой проверки не нужна.
