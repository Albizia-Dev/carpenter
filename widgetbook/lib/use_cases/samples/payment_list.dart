import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/demo_network.dart';
import '../../helpers/demo_payments.dart';
import '../../helpers/layout_viewport.dart';

enum _PaymentFilter { all, attention, completed }

enum _PaymentDetailTab { overview, allocations, history }

final paymentListSampleComponent = WidgetbookComponent(
  name: 'Payment List',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final pageSize = context.knobs.int.slider(
    label: 'Network · Page size',
    initialValue: 5,
    min: 3,
    max: 7,
  );
  final initialSelection = context.knobs.boolean(
    label: 'Selection · Open first payment',
    initialValue: true,
  );
  return layoutViewportPreview(
    context,
    offHeight: const Px(860),
    child: buildPaymentListSample(
      pageSize: pageSize,
      initialSelection: initialSelection,
    ),
  );
}

Widget buildPaymentListSample({
  int pageSize = 5,
  bool initialSelection = true,
}) =>
    _PaymentListSample(pageSize: pageSize, initialSelection: initialSelection);

final class _PaymentListSample extends StatefulWidget {
  const _PaymentListSample({
    required this.pageSize,
    required this.initialSelection,
  });

  final int pageSize;
  final bool initialSelection;

  @override
  State<_PaymentListSample> createState() => _PaymentListSampleState();
}

final class _PaymentListSampleState extends State<_PaymentListSample> {
  late DemoNetworkSource<DemoPayment> _source;
  final _search = TextEditingController();
  var _snapshot = CollectionSnapshot<DemoPayment>.initialLoading();
  DemoPayment? _selected;
  _PaymentFilter _filter = _PaymentFilter.all;
  _PaymentDetailTab _detailTab = _PaymentDetailTab.overview;
  String? _notice;
  var _request = 0;
  var _splitPosition = 0.38;

  @override
  void initState() {
    super.initState();
    _resetSource();
    _load(replace: true, selectFirst: widget.initialSelection);
  }

  @override
  void didUpdateWidget(_PaymentListSample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageSize != widget.pageSize) _load(replace: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DemoPayment> _applyFilter(List<DemoPayment> items) => switch (_filter) {
    _PaymentFilter.all => items,
    _PaymentFilter.attention =>
      items
          .where(
            (payment) =>
                payment.status == DemoPaymentStatus.review ||
                payment.status == DemoPaymentStatus.rejected,
          )
          .toList(growable: false),
    _PaymentFilter.completed =>
      items
          .where(
            (payment) =>
                payment.status == DemoPaymentStatus.matched ||
                payment.status == DemoPaymentStatus.posted,
          )
          .toList(growable: false),
  };

  void _resetSource() {
    _source = DemoNetworkSource<DemoPayment>(
      records: _applyFilter(demoPayments),
      searchText: (payment) => payment.searchableText,
    );
  }

  Future<void> _load({required bool replace, bool selectFirst = false}) async {
    final request = ++_request;
    final previous = replace ? _snapshot : _snapshot.beginLoadingMore();
    setState(() {
      _snapshot = replace ? _snapshot.beginRefresh() : previous;
      _notice = null;
    });
    try {
      final page = await _source.fetch(
        query: _search.text,
        cursor: replace
            ? null
            : (_snapshot.pageInfo as CollectionCursorPageInfo).nextCursor,
        limit: widget.pageSize,
      );
      if (!mounted || request != _request) return;
      final loaded = replace ? page.items : [..._snapshot.items, ...page.items];
      setState(() {
        _snapshot = CollectionSnapshot<DemoPayment>(
          items: loaded,
          loadPhase: CollectionLoadPhase.ready,
          contentState: loaded.isEmpty
              ? CollectionContentState.emptyResult
              : CollectionContentState.content,
          pageInfo: CollectionCursorPageInfo(
            itemCount: loaded.length,
            nextCursor: page.nextCursor,
          ),
        );
        if (selectFirst && loaded.isNotEmpty) _selected = loaded.first;
        if (_selected != null &&
            !loaded.any((payment) => payment.id == _selected!.id)) {
          _selected = null;
        }
      });
    } on DemoNetworkFailure catch (failure) {
      if (!mounted || request != _request) return;
      setState(
        () => _snapshot = _snapshot.withLoadFailure(
          CollectionFailure(error: failure, message: failure.message),
        ),
      );
    }
  }

  void _changeFilter(_PaymentFilter value) {
    setState(() {
      _filter = value;
      _selected = null;
      _resetSource();
    });
    _load(replace: true);
  }

  void _changeSelection(CollectionSelection<String> selection) {
    final id = selection.selectedKeys.firstOrNull;
    setState(() {
      _selected = id == null
          ? null
          : _snapshot.items.firstWhere((payment) => payment.id == id);
      _detailTab = _PaymentDetailTab.overview;
      _notice = null;
    });
  }

  void _showNotice(String message) => setState(() => _notice = message);

  @override
  Widget build(BuildContext context) => CarpenterMasterDetailPage<DemoPayment>(
    title: 'Платежи',
    subtitle: 'Казначейство · Банковские операции за 25–26 августа',
    semanticLabel: 'Список платежей с деталями',
    selectedValue: _selected,
    onDetailClosed: () => setState(() => _selected = null),
    splitPosition: _splitPosition,
    onSplitPositionChanged: (value) => setState(() => _splitPosition = value),
    primaryActions: [
      CarpenterActionDescriptor(
        id: 'new-payment',
        label: 'Новый платёж',
        icon: Icons.add,
        colorRole: ActionColorRole.primary,
        onInvoke: () => _showNotice('Открыта форма нового платежа'),
      ),
    ],
    secondaryActions: [
      CarpenterActionDescriptor(
        id: 'refresh-payments',
        label: 'Обновить',
        icon: Icons.refresh,
        onInvoke: () => _load(replace: true),
      ),
    ],
    master: _buildMaster(),
    detailBuilder: (context, payment) => _buildDetail(payment),
  );

  Widget _buildMaster() => Builder(
    builder: (context) {
      final theme = CarpenterTheme.of(context);
      final gap = context.units(theme.spacing.medium);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterInput(
            controller: _search,
            placeholder: 'Документ, плательщик, назначение, ИНН',
            semanticLabel: 'Поиск платежей',
            leadingIcon: Icons.search,
            size: FieldSize.small,
            onChanged: (_) => _load(replace: true),
          ),
          SizedBox(height: gap),
          CarpenterTabs<_PaymentFilter>(
            value: _filter,
            onChanged: _changeFilter,
            semanticLabel: 'Фильтр платежей',
            tabs: const [
              CarpenterTab(value: _PaymentFilter.all, label: 'Все'),
              CarpenterTab(
                value: _PaymentFilter.attention,
                label: 'Требуют внимания',
              ),
              CarpenterTab(
                value: _PaymentFilter.completed,
                label: 'Обработаны',
              ),
            ],
          ),
          SizedBox(height: gap),
          Expanded(
            child: CarpenterDataList<DemoPayment, String>(
              semanticLabel: 'Платежи',
              snapshot: _snapshot,
              itemKey: (payment) => payment.id,
              itemSemanticLabel: (payment) =>
                  '${payment.documentNumber}, ${payment.counterparty}, ${payment.signedAmount}',
              itemBuilder: (context, payment) =>
                  _PaymentListContent(payment: payment),
              selection: CollectionSelection<String>.single(_selected?.id),
              onSelectionChanged: _changeSelection,
              onLoadMore: () => _load(replace: false),
              retryAction: CarpenterActionDescriptor(
                id: 'retry-payments',
                label: 'Повторить',
                onInvoke: () => _load(replace: true),
              ),
              messages: const CarpenterDataListMessages(
                initialLoading: 'Загружаем платежи',
                refreshing: 'Обновляем платежи',
                loadingMore: 'Загружаем следующую страницу',
                emptyResult: 'По запросу ничего не найдено',
                initialError: 'Не удалось загрузить платежи',
                refreshError: 'Обновление не удалось, показаны старые данные',
                loadMore: 'Показать ещё',
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildDetail(DemoPayment payment) => Builder(
    builder: (context) {
      final theme = CarpenterTheme.of(context);
      final gap = context.units(theme.spacing.layoutSection);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterCard(
            semanticLabel: 'Основные сведения о платеже',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: context.units(theme.spacing.small),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CarpenterText.title(
                      payment.signedAmount,
                      emphasis: TypographyEmphasis.strong,
                    ),
                    CarpenterStatusIndicator(
                      label: demoPaymentStatusLabel(payment.status),
                      role: demoPaymentStatusRole(payment.status),
                    ),
                  ],
                ),
                SizedBox(height: context.units(theme.spacing.small)),
                CarpenterText.body(
                  '${payment.documentNumber} · ${payment.bookedAt}',
                  colorRole: ContentColorRole.secondary,
                ),
                SizedBox(height: gap),
                CarpenterToolbar(
                  semanticLabel: 'Действия над платежом',
                  overflowLabel: 'Ещё',
                  items: [
                    CarpenterToolbarItem(
                      priority: CarpenterToolbarPriority.critical,
                      prominence: ActionProminence.high,
                      action: CarpenterActionDescriptor(
                        id: 'allocate-${payment.id}',
                        label: 'Распределить',
                        icon: Icons.call_split,
                        colorRole: ActionColorRole.primary,
                        onInvoke: () => _showNotice(
                          'Открыто распределение ${payment.documentNumber}',
                        ),
                      ),
                    ),
                    CarpenterToolbarItem(
                      action: CarpenterActionDescriptor(
                        id: 'match-${payment.id}',
                        label: 'Сопоставить',
                        icon: Icons.link,
                        onInvoke: () => _showNotice(
                          'Запущено сопоставление ${payment.documentNumber}',
                        ),
                      ),
                    ),
                    CarpenterToolbarItem(
                      priority: CarpenterToolbarPriority.overflow,
                      action: CarpenterActionDescriptor(
                        id: 'download-${payment.id}',
                        label: 'Скачать подтверждение',
                        icon: Icons.download,
                        onInvoke: () => _showNotice(
                          'Подтверждение подготовлено к скачиванию',
                        ),
                      ),
                    ),
                    CarpenterToolbarItem(
                      priority: CarpenterToolbarPriority.overflow,
                      action: CarpenterActionDescriptor(
                        id: 'reject-${payment.id}',
                        label: 'Отклонить',
                        icon: Icons.block,
                        colorRole: ActionColorRole.danger,
                        onInvoke: () => _showNotice(
                          '${payment.documentNumber} отправлен на отклонение',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          CarpenterTabs<_PaymentDetailTab>(
            value: _detailTab,
            onChanged: (value) => setState(() => _detailTab = value),
            semanticLabel: 'Раздел платежа',
            tabs: const [
              CarpenterTab(value: _PaymentDetailTab.overview, label: 'Обзор'),
              CarpenterTab(
                value: _PaymentDetailTab.allocations,
                label: 'Распределение',
              ),
              CarpenterTab(value: _PaymentDetailTab.history, label: 'История'),
            ],
          ),
          SizedBox(height: gap),
          if (_notice != null) ...[
            CarpenterStatusIndicator(
              label: _notice!,
              role: FeedbackColorRole.info,
            ),
            SizedBox(height: gap),
          ],
          switch (_detailTab) {
            _PaymentDetailTab.overview => _PaymentOverview(
              payment: payment,
              onLinkInvoked: _showNotice,
            ),
            _PaymentDetailTab.allocations => _PaymentAllocations(
              payment: payment,
              onLinkInvoked: _showNotice,
            ),
            _PaymentDetailTab.history => _PaymentHistory(payment: payment),
          },
        ],
      );
    },
  );
}

final class _PaymentListContent extends StatelessWidget {
  const _PaymentListContent({required this.payment});

  final DemoPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterText.label(
                payment.counterparty,
                emphasis: TypographyEmphasis.strong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: gap),
              CarpenterText.caption(
                '${payment.documentNumber} · ${payment.bookedAt}',
                colorRole: ContentColorRole.secondary,
              ),
              SizedBox(height: gap),
              CarpenterText.body(
                payment.purpose,
                colorRole: ContentColorRole.secondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: gap),
              CarpenterStatusIndicator(
                label: demoPaymentStatusLabel(payment.status),
                role: demoPaymentStatusRole(payment.status),
              ),
            ],
          ),
        ),
        SizedBox(width: context.units(theme.spacing.medium)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CarpenterText.label(
              payment.signedAmount,
              emphasis: TypographyEmphasis.strong,
            ),
            SizedBox(height: gap),
            CarpenterText.caption(
              payment.direction == DemoPaymentDirection.incoming
                  ? 'Поступление'
                  : 'Списание',
              colorRole: ContentColorRole.secondary,
            ),
          ],
        ),
      ],
    );
  }
}

final class _DefinitionValue {
  const _DefinitionValue(this.term, this.value, {this.target});

  final String term;
  final String value;
  final String? target;
}

final class _PaymentOverview extends StatelessWidget {
  const _PaymentOverview({required this.payment, required this.onLinkInvoked});

  final DemoPayment payment;
  final ValueChanged<String> onLinkInvoked;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    final details = [
      _DefinitionValue(
        'Юридическое лицо',
        payment.legalEntity,
        target: 'Открыто юридическое лицо ${payment.legalEntity}',
      ),
      _DefinitionValue(
        'Наш счёт',
        '${payment.accountName}\n${payment.accountNumber}',
        target: 'Открыт счёт ${payment.accountName}',
      ),
      _DefinitionValue(
        payment.direction == DemoPaymentDirection.incoming
            ? 'Плательщик'
            : 'Получатель',
        '${payment.counterparty}\n${payment.counterpartyInn}',
        target: 'Открыт контрагент ${payment.counterparty}',
      ),
      _DefinitionValue(
        'Счёт контрагента',
        '${payment.counterpartyAccount}\n${payment.counterpartyBank}\n${payment.counterpartyBic}',
        target: 'Открыт счёт контрагента ${payment.counterpartyAccount}',
      ),
      _DefinitionValue('Назначение', payment.purpose),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterText.title('Реквизиты', emphasis: TypographyEmphasis.strong),
        SizedBox(height: context.units(theme.spacing.medium)),
        CarpenterDefinitionList<_DefinitionValue>(
          semanticLabel: 'Реквизиты платежа',
          items: details,
          term: (item) => item.term,
          valueBuilder: (context, item) => item.target == null
              ? CarpenterText.body(item.value)
              : CarpenterLink(
                  label: item.value,
                  semanticLabel: '${item.term}: ${item.value}',
                  icon: Icons.open_in_new,
                  onInvoke: () => onLinkInvoked(item.target!),
                ),
        ),
        SizedBox(height: gap),
        CarpenterCard(
          semanticLabel: 'Идентификаторы банковской операции',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CarpenterText.label(
                'Банковские идентификаторы',
                emphasis: TypographyEmphasis.strong,
              ),
              SizedBox(height: context.units(theme.spacing.small)),
              CarpenterText.caption(
                'Carpenter ID: ${payment.id}\nИсточник: bank-statement-2026-08-26.xml',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _PaymentAllocations extends StatelessWidget {
  const _PaymentAllocations({
    required this.payment,
    required this.onLinkInvoked,
  });

  final DemoPayment payment;
  final ValueChanged<String> onLinkInvoked;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    if (payment.allocations.isEmpty) {
      return CarpenterCard(
        semanticLabel: 'Распределение отсутствует',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CarpenterText.title(
              'Платёж пока не распределён',
              emphasis: TypographyEmphasis.strong,
            ),
            SizedBox(height: context.units(theme.spacing.small)),
            const CarpenterText.body(
              'Выберите договор, счёт или другой объект учёта.',
              colorRole: ContentColorRole.secondary,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterText.title(
          'Связанные объекты',
          emphasis: TypographyEmphasis.strong,
        ),
        SizedBox(height: context.units(theme.spacing.medium)),
        CarpenterDefinitionList<DemoPaymentAllocation>(
          semanticLabel: 'Распределение платежа',
          items: payment.allocations,
          term: (allocation) => allocation.kind,
          valueBuilder: (context, allocation) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterLink(
                label: allocation.object,
                icon: Icons.open_in_new,
                onInvoke: () =>
                    onLinkInvoked('Открыт объект ${allocation.object}'),
              ),
              SizedBox(height: context.units(theme.spacing.small)),
              CarpenterText.body(
                '${allocation.amount} · ${allocation.state}',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payment});

  final DemoPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CarpenterText.title(
          'История обработки',
          emphasis: TypographyEmphasis.strong,
        ),
        SizedBox(height: context.units(theme.spacing.medium)),
        CarpenterCard(
          padded: false,
          semanticLabel: 'История платежа',
          child: CarpenterDefinitionList<DemoPaymentEvent>(
            items: payment.events,
            semanticLabel: 'События платежа',
            term: (event) => event.time,
            valueBuilder: (context, event) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarpenterText.body(
                  event.title,
                  emphasis: TypographyEmphasis.medium,
                ),
                SizedBox(height: context.units(theme.spacing.small)),
                CarpenterText.caption(
                  event.actor,
                  colorRole: ContentColorRole.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
