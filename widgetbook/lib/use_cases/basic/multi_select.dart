import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../helpers/preview.dart';

final multiSelectComponent = WidgetbookComponent(
  name: 'MultiSelect',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final entity = context.knobs.object.dropdown(
          label: 'Сущности',
          options: ['Проектировщики', 'Проекты', 'Платежи'],
        );
        final state = context.knobs.object.dropdown(
          label: 'Результаты',
          options: OptionsLoadState.values,
          labelBuilder: (value) => value.name,
        );
        final availability = context.knobs.object.dropdown(
          label: 'Доступность',
          options: FieldAvailability.values,
          labelBuilder: (value) => value.name,
        );
        return preview(
          _Preview(
            key: ValueKey(entity),
            entity: entity,
            state: state,
            availability: availability,
          ),
        );
      },
    ),
  ],
);

class _Preview extends StatefulWidget {
  const _Preview({
    super.key,
    required this.entity,
    required this.state,
    required this.availability,
  });
  final String entity;
  final OptionsLoadState state;
  final FieldAvailability availability;
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  String query = '';
  List<CarpenterOption<int>> selected = [];
  @override
  Widget build(BuildContext context) {
    final options = List.generate(500, (i) {
      final label = switch (widget.entity) {
        'Проектировщики' => 'Проектировщик ${i + 1} · Отдел ${i % 12 + 1}',
        'Проекты' => 'Проект № ${i + 1} · Жилой квартал ${i % 25 + 1}',
        _ => 'Платёж № ${i + 1} · ООО «Север» · ${(i + 1) * 1000} ₽',
      };
      return CarpenterOption(id: i, value: i, label: label);
    });
    return CarpenterMultiSelect<int>(
      label: widget.entity,
      placeholder: 'Поиск по названию или номеру',
      removeLabel: 'Удалить',
      loadingText: 'Поиск…',
      emptyText: 'Ничего не найдено',
      failedText: 'Не удалось загрузить результаты',
      values: selected,
      suggestions: options
          .where(
            (option) =>
                option.label.toLowerCase().contains(query.toLowerCase()),
          )
          .toList(),
      loadState: widget.state,
      availability: widget.availability,
      onQueryChanged: (value) => setState(() => query = value),
      onChanged: (value) => setState(() => selected = value),
    );
  }
}
