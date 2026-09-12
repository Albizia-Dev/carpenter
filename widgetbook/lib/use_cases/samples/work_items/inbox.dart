import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../helpers/layout_viewport.dart';

import 'inbox_fixtures.g.dart';
export 'inbox_fixtures.g.dart';

final workInboxComponent = WidgetbookComponent(
  name: 'Моя работа',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: WorkInboxScene(
          phase: context.knobs.object.dropdown(
            label: 'Загрузка данных',
            options: CarpenterWorkInboxPhase.values,
            labelBuilder: (value) => switch (value) {
              CarpenterWorkInboxPhase.loading => 'Загрузка',
              CarpenterWorkInboxPhase.ready => 'Готово',
              CarpenterWorkInboxPhase.refreshing => 'Обновление',
              CarpenterWorkInboxPhase.failure => 'Ошибка',
              CarpenterWorkInboxPhase.stale => 'Предыдущие данные',
            },
          ),
          empty: context.knobs.boolean(label: 'Пустая очередь'),
          preview: context.knobs.boolean(
            label: 'Демонстрационные данные',
            initialValue: true,
          ),
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'States · Перенос срока',
      builder: (context) => layoutViewportPreview(
        context,
        child: WorkInboxScene(
          initialSelection: workInboxScenarioEntries['deadline'],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'States · Ошибка обновления',
      builder: (context) => layoutViewportPreview(
        context,
        child: WorkInboxScene(
          phase: CarpenterWorkInboxPhase.stale,
          initialSelection: workInboxScenarioEntries['accept'],
        ),
      ),
    ),
  ],
);

/// Interactive host for the public component; only synthetic UI state lives here.
class WorkInboxScene extends StatefulWidget {
  const WorkInboxScene({
    super.key,
    this.phase = CarpenterWorkInboxPhase.ready,
    this.empty = false,
    this.preview = true,
    this.initialSelection,
  });
  final CarpenterWorkInboxPhase phase;
  final bool empty;
  final bool preview;
  final String? initialSelection;
  @override
  State<WorkInboxScene> createState() => _SceneState();
}

class _SceneState extends State<WorkInboxScene> {
  String _search = '';
  String _filter = 'all';
  late String? _selection = widget.initialSelection;
  CarpenterWorkInboxPhase? _retryPhase;

  @override
  void didUpdateWidget(WorkInboxScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _retryPhase = null;
  }

  @override
  Widget build(BuildContext context) {
    final phase = _retryPhase ?? widget.phase;
    final items =
        widget.empty ||
            phase == CarpenterWorkInboxPhase.loading ||
            phase == CarpenterWorkInboxPhase.failure
        ? <CarpenterWorkInboxItem>[]
        : workInboxItems
              .where(
                (item) =>
                    (_filter == 'all' || workInboxKinds[item.id] == _filter) &&
                    [
                      item.reference,
                      item.title,
                      item.description,
                      item.creator,
                      item.assignee,
                    ].any(
                      (value) => value.toLowerCase().contains(
                        _search.trim().toLowerCase(),
                      ),
                    ),
              )
              .toList();
    return CarpenterWorkInbox(
      items: items,
      filters: const [
        CarpenterWorkInboxFilter(id: 'all', label: 'Все'),
        CarpenterWorkInboxFilter(id: 'zodo', label: 'ЗОДО'),
        CarpenterWorkInboxFilter(id: 'rsp', label: 'РСП'),
      ],
      selectedFilter: _filter,
      search: _search,
      selectedId: _selection,
      phase: phase,
      preview: widget.preview,
      errorMessage:
          'Не удалось связаться с сервером. Вы можете повторить загрузку.',
      onSearchChanged: (value) => setState(() {
        _search = value;
        _selection = null;
      }),
      onFilterChanged: (value) => setState(() {
        _filter = value;
        _selection = null;
      }),
      onSelectionChanged: (value) => setState(() => _selection = value),
      onRefresh: () =>
          setState(() => _retryPhase = CarpenterWorkInboxPhase.ready),
    );
  }
}
