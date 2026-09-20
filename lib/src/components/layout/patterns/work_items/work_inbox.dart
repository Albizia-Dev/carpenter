import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/input/input.dart';
import '../../../basic/progress.dart';
import '../../../basic/status_indicator.dart';
import '../../../basic/text.dart';
import '../../../behaviour/notice.dart';
import '../../../collections/definition_list.dart';
import '../../../collections/list_tile.dart';
import '../../master_detail.dart';
import '../../page_header.dart';
import '../../regions/primary_region.dart';

/// Caller-owned read phase. Refreshing preserves data; failed refresh is stale.
enum CarpenterWorkInboxPhase {
  /// The initial queue is loading without usable items.
  loading,

  /// Current queue data is ready.
  ready,

  /// Existing queue data remains visible while it refreshes.
  refreshing,

  /// No usable queue data could be loaded.
  failure,

  /// Existing data remains visible after a failed refresh.
  stale,
}

/// UI filter only; the application maps its identity into a domain query.
@immutable
final class CarpenterWorkInboxFilter {
  /// Creates a domain-neutral filter descriptor.
  const CarpenterWorkInboxFilter({required this.id, required this.label});

  /// Stable filter identity mapped by the application.
  final String id;

  /// Human-readable filter label.
  final String label;
}

/// Presentation data for one obligation, not a backend Task/DTO.
/// Dates and identities are already formatted by the host. [id] must identify
/// the obligation: different obligations may refer to the same task.
@immutable
final class CarpenterWorkInboxItem {
  /// Creates immutable presentation data for one obligation.
  const CarpenterWorkInboxItem({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.status,
    required this.reason,
    required this.nextAction,
    required this.creator,
    required this.assignee,
    this.deadline,
    this.requestedDeadline,
  });

  /// Stable obligation identity used for selection.
  final String id;

  /// Human-readable task or execution reference.
  final String reference;

  /// Primary obligation title.
  final String title;

  /// Supporting description shown in detail.
  final String description;

  /// Formatted current status.
  final String status;

  /// Explanation of why this obligation is in the queue.
  final String reason;

  /// Human-readable next step.
  final String nextAction;

  /// Formatted creator identity.
  final String creator;

  /// Formatted assignee identity.
  final String assignee;

  /// Optional formatted established deadline.
  final String? deadline;

  /// Optional formatted proposed deadline.
  final String? requestedDeadline;
}

/// Controlled personal-work queue with an adaptive detail region.
///
/// The host owns query, selection, loading, retry and mutation policies.
/// Only editor cursor/focus are local. Selecting a row opens a read-only detail;
/// [onOpenItem] optionally navigates to the real task, never executes its next
/// business action. Omit it until that route exists. Filters/search do not
/// pretend to filter the supplied data locally.
///
/// Requires bounded page height. Master list owns its scroll; the shared detail
/// region owns document scrolling and narrow-screen return/focus behaviour.
/// Rows support the underlying ListTile keyboard invocation. Search and filter
/// controls stay available after errors. All text uses Carpenter theme roles.
final class CarpenterWorkInbox extends StatefulWidget {
  /// Creates a controlled adaptive personal-work queue.
  const CarpenterWorkInbox({
    super.key,
    required this.items,
    required this.filters,
    required this.selectedFilter,
    required this.search,
    required this.selectedId,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSelectionChanged,
    required this.onRefresh,
    this.phase = CarpenterWorkInboxPhase.ready,
    this.errorMessage,
    this.preview = false,
    this.onOpenItem,
  });

  /// Obligations currently visible for the host-owned query.
  final List<CarpenterWorkInboxItem> items;

  /// Available host-defined filter descriptors.
  final List<CarpenterWorkInboxFilter> filters;

  /// Id of the currently selected filter.
  final String selectedFilter;

  /// Current host-owned search query.
  final String search;

  /// Id of the selected obligation, or null for list-only presentation.
  final String? selectedId;

  /// Reports search edits without filtering [items] locally.
  final ValueChanged<String> onSearchChanged;

  /// Reports selection of a host-defined filter id.
  final ValueChanged<String> onFilterChanged;

  /// Reports obligation selection and detail dismissal.
  final ValueChanged<String?> onSelectionChanged;

  /// Requests a refresh of the host-owned queue.
  final VoidCallback onRefresh;

  /// Optionally opens the selected obligation in its owning application.
  final ValueChanged<String>? onOpenItem;

  /// Current host-owned read phase.
  final CarpenterWorkInboxPhase phase;

  /// Optional explanation for failure or stale data.
  final String? errorMessage;

  /// Whether the queue displays demonstration rather than live data.
  final bool preview;

  @override
  /// Creates state for the local search editor and adaptive detail focus.
  State<CarpenterWorkInbox> createState() => _WorkInboxState();
}

final class _WorkInboxState extends State<CarpenterWorkInbox> {
  late final _search = TextEditingController(text: widget.search);

  @override
  void didUpdateWidget(CarpenterWorkInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_search.text != widget.search) {
      _search.value = TextEditingValue(
        text: widget.search,
        selection: TextSelection.collapsed(offset: widget.search.length),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final busy =
        widget.phase == CarpenterWorkInboxPhase.loading ||
        widget.phase == CarpenterWorkInboxPhase.refreshing;
    CarpenterWorkInboxItem? selected;
    for (final item in widget.items) {
      if (item.id == widget.selectedId) selected = item;
    }
    return ColoredBox(
      color: theme.surface.base,
      child: CarpenterPageRegion(
        semanticLabel: 'Моя работа',
        header: CarpenterPageHeader(
          title: 'Моя работа',
          subtitle: 'Задачи, в которых нужен ваш следующий шаг',
          status: widget.preview
              ? const CarpenterPageStatus(
                  label: 'Демонстрационные данные',
                  role: FeedbackColorRole.neutral,
                )
              : null,
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'refresh',
              label: 'Обновить',
              onInvoke: busy ? null : widget.onRefresh,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.phase == CarpenterWorkInboxPhase.failure ||
                widget.phase == CarpenterWorkInboxPhase.stale)
              Padding(padding: EdgeInsets.all(gap), child: _loadFailure()),
            Expanded(
              child: CarpenterMasterDetail(
                masterSemanticLabel: 'Очередь задач',
                detailSemanticLabel: 'Детали задачи',
                master: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CarpenterInput(
                            controller: _search,
                            label: 'Поиск в моей работе',
                            placeholder: 'Номер, название или сотрудник',
                            onChanged: widget.onSearchChanged,
                          ),
                          SizedBox(height: gap),
                          Wrap(
                            spacing: gap / 2,
                            runSpacing: gap / 2,
                            children: [
                              for (final filter in widget.filters)
                                CarpenterButton(
                                  label: filter.label,
                                  colorRole: filter.id == widget.selectedFilter
                                      ? ActionColorRole.primary
                                      : ActionColorRole.neutral,
                                  toggled: filter.id == widget.selectedFilter,
                                  onPressed: () =>
                                      widget.onFilterChanged(filter.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (busy)
                      const CarpenterProgress(
                        semanticLabel: 'Загрузка очереди',
                      ),
                    Expanded(
                      child: widget.items.isEmpty
                          ? _empty(gap, busy)
                          : ListView.separated(
                              key: const PageStorageKey('work-inbox-list'),
                              itemCount: widget.items.length,
                              separatorBuilder: (_, _) => SizedBox(
                                height: context.units(.0625.rem),
                                child: ColoredBox(color: theme.surface.subtle),
                              ),
                              itemBuilder: (context, index) {
                                final item = widget.items[index];
                                return CarpenterListTile(
                                  key: ValueKey(item.id),
                                  presentation: CarpenterListTilePresentation
                                      .collectionRow,
                                  selected: item.id == widget.selectedId,
                                  semanticLabel:
                                      '${item.reference}. ${item.title}. ${item.reason}',
                                  onInvoke: () =>
                                      widget.onSelectionChanged(item.id),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CarpenterText.caption(
                                        item.reference,
                                        colorRole: ContentColorRole.secondary,
                                      ),
                                      SizedBox(height: gap / 2),
                                      CarpenterText(
                                        item.title,
                                        emphasis: TypographyEmphasis.medium,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CarpenterText(
                                        item.reason,
                                        colorRole: ContentColorRole.secondary,
                                      ),
                                      SizedBox(height: gap / 2),
                                      CarpenterText.label(item.nextAction),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                detail: selected == null
                    ? null
                    : _detail(context, selected, gap),
                onDetailVisibilityChanged: (visible) {
                  if (!visible) widget.onSelectionChanged(null);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadFailure() => CarpenterNotice(
    tone: CarpenterNoticeTone.warning,
    title: widget.phase == CarpenterWorkInboxPhase.stale
        ? 'Показаны предыдущие данные'
        : 'Очередь не загрузилась',
    message: widget.errorMessage ?? 'Повторите попытку.',
    action: CarpenterActionDescriptor(
      id: 'retry',
      label: 'Повторить',
      onInvoke: widget.onRefresh,
    ),
  );

  Widget _empty(double gap, bool busy) {
    final failed = widget.phase == CarpenterWorkInboxPhase.failure;
    final filtered =
        widget.search.trim().isNotEmpty || widget.selectedFilter != 'all';
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: CarpenterText(
          busy
              ? 'Загружаем задачи…'
              : failed
              ? 'После повторной загрузки здесь появятся задачи.'
              : filtered
              ? 'По этим условиям задач нет. Измените поиск или фильтр.'
              : 'В очереди пока нет задач, требующих вашего действия.',
          colorRole: ContentColorRole.secondary,
        ),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    CarpenterWorkInboxItem item,
    double gap,
  ) {
    final fields = <(String, String)>[
      ('Создатель', item.creator),
      ('Исполнитель', item.assignee),
      if (item.deadline != null) ('Установленный срок', item.deadline!),
      if (item.requestedDeadline != null)
        ('Предложенный срок', item.requestedDeadline!),
    ];
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CarpenterButton(
              label: 'К списку задач',
              onPressed: () => widget.onSelectionChanged(null),
            ),
          ),
          SizedBox(height: gap),
          if (widget.phase == CarpenterWorkInboxPhase.refreshing) ...[
            const CarpenterProgress(semanticLabel: 'Обновление деталей'),
            SizedBox(height: gap),
          ],
          CarpenterText.caption(
            item.reference,
            colorRole: ContentColorRole.secondary,
          ),
          SizedBox(height: gap),
          CarpenterText.title(item.title),
          SizedBox(height: gap),
          CarpenterStatusIndicator(
            label: item.status,
            role: FeedbackColorRole.neutral,
          ),
          SizedBox(height: gap * 2),
          CarpenterText.label('Почему задача здесь'),
          SizedBox(height: gap / 2),
          CarpenterText(item.reason),
          SizedBox(height: gap),
          CarpenterText.label('Следующий шаг'),
          SizedBox(height: gap / 2),
          CarpenterText(item.nextAction),
          SizedBox(height: gap * 2),
          CarpenterDefinitionList<(String, String)>(
            items: fields,
            term: (field) => field.$1,
            valueBuilder: (_, field) => CarpenterText(field.$2),
          ),
          SizedBox(height: gap * 2),
          CarpenterText.label('Описание'),
          SizedBox(height: gap / 2),
          CarpenterText(item.description),
          if (widget.onOpenItem != null) ...[
            SizedBox(height: gap * 2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CarpenterButton.filled(
                label: 'Открыть карточку',
                onPressed: () => widget.onOpenItem!(item.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
