import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/layout_viewport.dart';

enum _ReconciliationView { create, linked }

enum _ObjectType { project, order }

final nestedCompositionComponent = WidgetbookComponent(
  name: 'Nested composition',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) => layoutViewportPreview(
  context,
  offHeight: const Rem(55),
  child: const _NestedCompositionPreview(),
);

const _descriptor = CarpenterPageDescriptor(
  id: CarpenterPageId('samples.nested-composition'),
  title: 'Распределение платежей',
  kind: CarpenterPageKind.operation,
);

final class _NestedCompositionPreview extends StatefulWidget {
  const _NestedCompositionPreview();

  @override
  State<_NestedCompositionPreview> createState() =>
      _NestedCompositionPreviewState();
}

final class _NestedCompositionPreviewState
    extends State<_NestedCompositionPreview> {
  final _objectSearch = TextEditingController();
  final _paymentSearch = TextEditingController();

  _ReconciliationView _view = _ReconciliationView.create;
  _ObjectType _objectType = _ObjectType.project;
  CollectionSelection<String> _objectSelection =
      CollectionSelection<String>.multiple();
  CollectionSelection<String> _paymentSelection =
      CollectionSelection<String>.multiple();

  @override
  void dispose() {
    _objectSearch.dispose();
    _paymentSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objects = _filter(_objects, _objectSearch.text);
    final payments = _filter(_payments, _paymentSearch.text);
    final canLink = !_objectSelection.isEmpty && !_paymentSelection.isEmpty;

    return CarpenterOperationPage(
      descriptor: _descriptor,
      subtitle: 'Сопоставьте объект и платёж, не покидая рабочую поверхность',
      primaryActions: [
        CarpenterActionDescriptor(
          id: 'refresh',
          label: 'Обновить',
          onInvoke: () {},
        ),
      ],
      navigation: CarpenterTabs<_ReconciliationView>(
        value: _view,
        tabs: const [
          CarpenterTab(
            value: _ReconciliationView.create,
            label: 'Создать связь',
          ),
          CarpenterTab(
            value: _ReconciliationView.linked,
            label: 'Уже связанные',
          ),
        ],
        onChanged: (value) => setState(() => _view = value),
      ),
      attention: _view == _ReconciliationView.linked
          ? const CarpenterNotice(
              title: 'Показаны только активные связи',
              message:
                  'Вернитесь в режим создания, чтобы сопоставить новую пару.',
              tone: CarpenterNoticeTone.info,
            )
          : null,
      body: CarpenterOperationPair(
        primary: CarpenterPageSection(
          id: const CarpenterPageSectionId('reconciliation.objects'),
          title: 'Распределить на',
          description: '${objects.length} доступных объектов',
          role: CarpenterPageSectionRole.operation,
          fillAvailable: true,
          navigation: CarpenterTabs<_ObjectType>(
            value: _objectType,
            tabs: const [
              CarpenterTab(value: _ObjectType.project, label: 'Проекты'),
              CarpenterTab(value: _ObjectType.order, label: 'Заказы'),
            ],
            onChanged: (value) => setState(() => _objectType = value),
          ),
          toolbar: CarpenterFilterBar(
            searchController: _objectSearch,
            searchLabel: 'Поиск объектов',
            searchPlaceholder: 'Номер, название или контрагент',
            onSearchChanged: (_) => setState(() {}),
          ),
          child: CarpenterPageSection(
            id: const CarpenterPageSectionId(
              'reconciliation.objects.collection',
            ),
            title: 'Доступные объекты',
            role: CarpenterPageSectionRole.collection,
            fillAvailable: true,
            child: CarpenterDataList<_OperationItem, String>(
              snapshot: CollectionSnapshot(items: objects),
              itemKey: (item) => item.id,
              itemSemanticLabel: (item) => item.title,
              selection: _objectSelection,
              onSelectionChanged: (value) =>
                  setState(() => _objectSelection = value),
              itemBuilder: (context, item) => CarpenterListTile(
                title: CarpenterText.label(
                  item.title,
                  emphasis: TypographyEmphasis.strong,
                ),
                subtitle: CarpenterText.caption(
                  item.subtitle,
                  colorRole: ContentColorRole.secondary,
                ),
                trailing: CarpenterStatusIndicator(
                  label: item.status,
                  role: item.feedbackRole,
                ),
              ),
            ),
          ),
        ),
        secondary: CarpenterPageSection(
          id: const CarpenterPageSectionId('reconciliation.payments'),
          title: 'Платежи',
          description: '${payments.length} платежей подходят под фильтр',
          role: CarpenterPageSectionRole.operation,
          fillAvailable: true,
          toolbar: CarpenterFilterBar(
            searchController: _paymentSearch,
            searchLabel: 'Поиск платежей',
            searchPlaceholder: 'Сумма, документ или контрагент',
            onSearchChanged: (_) => setState(() {}),
          ),
          child: CarpenterPageSection(
            id: const CarpenterPageSectionId(
              'reconciliation.payments.collection',
            ),
            title: 'Доступные платежи',
            role: CarpenterPageSectionRole.collection,
            fillAvailable: true,
            child: CarpenterDataList<_OperationItem, String>(
              snapshot: CollectionSnapshot(items: payments),
              itemKey: (item) => item.id,
              itemSemanticLabel: (item) => item.title,
              selection: _paymentSelection,
              onSelectionChanged: (value) =>
                  setState(() => _paymentSelection = value),
              itemBuilder: (context, item) => CarpenterListTile(
                title: CarpenterText.label(
                  item.title,
                  emphasis: TypographyEmphasis.strong,
                ),
                subtitle: CarpenterText.caption(
                  item.subtitle,
                  colorRole: ContentColorRole.secondary,
                ),
                trailing: CarpenterStatusIndicator(
                  label: item.status,
                  role: item.feedbackRole,
                ),
              ),
            ),
          ),
        ),
      ),
      footer: CarpenterToolbar(
        semanticLabel: 'Действия сопоставления',
        items: [
          CarpenterToolbarItem(
            group: CarpenterToolbarGroup.secondary,
            action: CarpenterActionDescriptor(
              id: 'clear-selection',
              label: 'Очистить выбор',
              onInvoke: canLink
                  ? () => setState(() {
                      _objectSelection = CollectionSelection<String>.multiple();
                      _paymentSelection =
                          CollectionSelection<String>.multiple();
                    })
                  : null,
            ),
          ),
          CarpenterToolbarItem(
            group: CarpenterToolbarGroup.primary,
            prominence: ActionProminence.high,
            action: CarpenterActionDescriptor(
              id: 'link',
              label: 'Установить связь',
              onInvoke: canLink ? () {} : null,
            ),
          ),
        ],
      ),
    );
  }
}

List<_OperationItem> _filter(List<_OperationItem> source, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return source;
  return source
      .where(
        (item) =>
            '${item.title} ${item.subtitle}'.toLowerCase().contains(normalized),
      )
      .toList(growable: false);
}

final class _OperationItem {
  const _OperationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.feedbackRole,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final FeedbackColorRole feedbackRole;
}

const _objects = <_OperationItem>[
  _OperationItem(
    id: 'project-104',
    title: '№104 · Демо-объект 25',
    subtitle: 'ООО «Ромашка» · 180 000 ₽ к распределению',
    status: 'Открыт',
    feedbackRole: FeedbackColorRole.info,
  ),
  _OperationItem(
    id: 'project-107',
    title: '№107 · Северный корпус',
    subtitle: 'ООО «Контур» · 92 400 ₽ к распределению',
    status: 'Частично',
    feedbackRole: FeedbackColorRole.warning,
  ),
  _OperationItem(
    id: 'project-110',
    title: '№110 · Реконструкция БК',
    subtitle: 'АО «Пример» · 310 000 ₽ к распределению',
    status: 'Открыт',
    feedbackRole: FeedbackColorRole.info,
  ),
];

const _payments = <_OperationItem>[
  _OperationItem(
    id: 'payment-81',
    title: '+120 000 ₽ · №814',
    subtitle: 'ООО «Ромашка» · 08.09.2026 · Основной счёт',
    status: 'Входящий',
    feedbackRole: FeedbackColorRole.success,
  ),
  _OperationItem(
    id: 'payment-82',
    title: '+60 000 ₽ · №815',
    subtitle: 'ООО «Ромашка» · 08.09.2026 · Основной счёт',
    status: 'Входящий',
    feedbackRole: FeedbackColorRole.success,
  ),
  _OperationItem(
    id: 'payment-83',
    title: '−24 500 ₽ · №816',
    subtitle: 'ООО «Поставщик» · 09.09.2026 · Основной счёт',
    status: 'Исходящий',
    feedbackRole: FeedbackColorRole.warning,
  ),
];
