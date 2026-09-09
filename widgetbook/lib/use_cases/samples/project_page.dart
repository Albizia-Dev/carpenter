import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/layout_viewport.dart';

enum _ProjectTab { overview, documents, relations, finance }

enum _DocumentStage { common, design, working }

final projectPageSampleComponent = WidgetbookComponent(
  name: 'Project page',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _projectPage)],
);

Widget _projectPage(BuildContext context) {
  return layoutViewportPreview(
    context,
    offHeight: const Rem(90),
    child: const _ProjectPageSample(),
  );
}

final class _ProjectPageSample extends StatefulWidget {
  const _ProjectPageSample();

  @override
  State<_ProjectPageSample> createState() => _ProjectPageSampleState();
}

final class _ProjectPageSampleState extends State<_ProjectPageSample> {
  final _search = TextEditingController();
  final _documentWidths = <String, LengthUnit>{};
  final _projectValues = <String, String>{
    'name': 'Демо-объект 25',
    'customer': 'ООО «Ромашка»',
    'designCode': '22-12',
    'workingCode': '',
    'objectType': 'Линейный объект',
  };
  final _drafts = <String, String>{};

  _ProjectTab _tab = _ProjectTab.overview;
  _DocumentStage _stage = _DocumentStage.design;
  Set<Object> _expanded = {'electrical', 'structures'};
  String? _editingField;
  String? _editError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _projectValues['name']!;
    final customer = _projectValues['customer']!;
    final designCode = _projectValues['designCode']!;
    return CarpenterObjectPage(
      title: '№104. $name',
      subtitle: '$customer · стадия П $designCode',
      status: const CarpenterPageStatus(
        label: 'На согласовании',
        role: FeedbackColorRole.info,
      ),
      primaryActions: [
        CarpenterActionDescriptor(
          id: 'project.edit',
          label: 'Редактировать',
          icon: GravityIcons.pencil,
          onInvoke: () => _beginEdit('name', showOverview: true),
        ),
      ],
      secondaryActions: [
        CarpenterActionDescriptor(
          id: 'project.more',
          label: 'Ещё действия',
          icon: GravityIcons.ellipsis,
          onInvoke: () {},
        ),
      ],
      primaryContent: CarpenterPageBody(
        semanticLabel: 'Разделы проекта',
        children: [
          CarpenterTabs<_ProjectTab>(
            value: _tab,
            onChanged: (value) => setState(() => _tab = value),
            tabs: const [
              CarpenterTab<_ProjectTab>(
                value: _ProjectTab.overview,
                label: 'Обзор',
              ),
              CarpenterTab<_ProjectTab>(
                value: _ProjectTab.documents,
                label: 'Документы',
              ),
              CarpenterTab<_ProjectTab>(
                value: _ProjectTab.relations,
                label: 'Связи',
              ),
              CarpenterTab<_ProjectTab>(
                value: _ProjectTab.finance,
                label: 'Финансы',
              ),
            ],
          ),
          _tabContent(),
        ],
      ),
      semanticLabel: 'Демонстрационная страница проекта',
    );
  }

  void _beginEdit(String key, {bool showOverview = false}) {
    setState(() {
      if (showOverview) _tab = _ProjectTab.overview;
      _editingField = key;
      _drafts[key] = _projectValues[key] ?? '';
      _editError = null;
    });
  }

  void _changeDraft(String key, String value) {
    setState(() {
      _drafts[key] = value;
      _editError = null;
    });
  }

  void _commitEdit(String key, {bool allowEmpty = false}) {
    final value = (_drafts[key] ?? '').trim();
    if (!allowEmpty && value.isEmpty) {
      setState(() => _editError = 'Значение не может быть пустым');
      return;
    }
    setState(() {
      _projectValues[key] = value;
      _editingField = null;
      _editError = null;
    });
  }

  void _cancelEdit(String key) {
    setState(() {
      _drafts[key] = _projectValues[key] ?? '';
      _editingField = null;
      _editError = null;
    });
  }

  CarpenterRecordDetail _editableTextDetail({
    required String key,
    required String label,
    bool allowEmpty = false,
    String? placeholder,
  }) {
    final value = _projectValues[key] ?? '';
    final editing = _editingField == key;
    return CarpenterRecordDetail(
      label: label,
      value: CarpenterInlineTextEdit(
        value: value.isEmpty ? 'Не задано' : value,
        draft: _drafts[key] ?? value,
        editing: editing,
        enabled: _editingField == null || editing,
        semanticLabel: label,
        placeholder: placeholder,
        editSemanticLabel: 'Редактировать: $label',
        commitSemanticLabel: 'Сохранить: $label',
        errorText: editing ? _editError : null,
        onDraftChanged: (next) => _changeDraft(key, next),
        onEditRequested: () => _beginEdit(key),
        onCommitRequested: () => _commitEdit(key, allowEmpty: allowEmpty),
        onCancelRequested: () => _cancelEdit(key),
      ),
    );
  }

  Widget _tabContent() => switch (_tab) {
    _ProjectTab.overview => _overview(),
    _ProjectTab.documents => _documents(),
    _ProjectTab.relations => _relations(),
    _ProjectTab.finance => _finance(),
  };

  Widget _overview() {
    return CarpenterPageBody(
      semanticLabel: 'Обзор проекта',
      children: [
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('project.details'),
          title: 'О проекте',
          description:
              'Изменения применяются прямо в строке. Enter сохраняет, Escape отменяет.',
          child: CarpenterCard(
            child: CarpenterRecordDetails(
              labelWidth: 190,
              details: [
                _editableTextDetail(
                  key: 'name',
                  label: 'Название',
                  placeholder: 'Название проекта',
                ),
                _editableTextDetail(
                  key: 'customer',
                  label: 'Заказчик',
                  placeholder: 'Контрагент-заказчик',
                ),
                _editableTextDetail(
                  key: 'designCode',
                  label: 'Стадия П',
                  placeholder: 'Номер документа',
                ),
                _editableTextDetail(
                  key: 'workingCode',
                  label: 'Стадия Р',
                  allowEmpty: true,
                  placeholder: 'Номер документа',
                ),
                _editableTextDetail(
                  key: 'objectType',
                  label: 'Тип объекта',
                  placeholder: 'Тип объекта',
                ),
              ],
            ),
          ),
        ),
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('project.team'),
          title: 'Команда',
          child: const CarpenterCard(
            child: CarpenterRecordDetails(
              labelWidth: 190,
              details: [
                CarpenterRecordDetail(
                  label: 'Проектировщики',
                  value: CarpenterText.body('Не назначены'),
                ),
                CarpenterRecordDetail(
                  label: 'ГИП',
                  value: CarpenterText.body('Не назначен'),
                ),
              ],
            ),
          ),
        ),
        const CarpenterRecordSummary(
          children: [
            CarpenterRecordMetric(
              label: 'Документы',
              value: CarpenterText.title('4 раздела · 5 файлов'),
              description: 'Стадия П',
            ),
            CarpenterRecordMetric(
              label: 'Связи',
              value: CarpenterText.title('0 договоров · 0 задач'),
              description: 'Связанные сущности',
            ),
            CarpenterRecordMetric(
              label: 'Финансы',
              value: CarpenterText.title('50 400 ₽'),
              description: 'Фактические платежи',
            ),
          ],
        ),
      ],
    );
  }

  Widget _documents() {
    return CarpenterRecordSection(
      id: const CarpenterPageSectionId('project.documents'),
      title: 'Документы',
      actions: [
        CarpenterButton.fromAction(
          CarpenterActionDescriptor(
            id: 'documents.add-section',
            label: 'Добавить раздел',
            icon: GravityIcons.folderPlus,
            onInvoke: () {},
          ),
        ),
        CarpenterButton.fromAction(
          CarpenterActionDescriptor(
            id: 'documents.add-file',
            label: 'Добавить файл',
            icon: GravityIcons.filePlus,
            onInvoke: () {},
          ),
        ),
      ],
      child: CarpenterPageBody(
        semanticLabel: 'Документы проекта',
        children: [
          CarpenterTabs<_DocumentStage>(
            value: _stage,
            onChanged: (value) => setState(() => _stage = value),
            tabs: const [
              CarpenterTab<_DocumentStage>(
                value: _DocumentStage.common,
                label: 'Общее',
              ),
              CarpenterTab<_DocumentStage>(
                value: _DocumentStage.design,
                label: 'Тома П',
              ),
              CarpenterTab<_DocumentStage>(
                value: _DocumentStage.working,
                label: 'Тома Р',
              ),
            ],
          ),
          CarpenterFilterBar(
            searchController: _search,
            searchLabel: 'Поиск в текущем разделе',
            searchPlaceholder: 'Название материала',
            onSearchChanged: (_) => setState(() {}),
            activeFilterCount: _search.text.trim().isEmpty ? 0 : 1,
            clearAction: CarpenterActionDescriptor(
              id: 'documents.clear-search',
              label: 'Очистить',
              icon: GravityIcons.xmark,
              onInvoke: () => setState(_search.clear),
            ),
          ),
          CarpenterTreeTable<_DocumentItem>(
            semanticLabel: 'Материалы стадии П',
            nodes: _filteredDocuments,
            treeHeader: 'Наименование',
            treeWidth: const CarpenterTableColumnWidth.flexible(
              flex: 4,
              preferred: Rem(22),
              minimum: Rem(12),
              maximum: Rem(40),
            ),
            columns: [
              CarpenterTreeTableColumn<_DocumentItem>.number(
                id: 'number',
                header: '№',
                value: (node) => node.value.number,
                width: const CarpenterTableColumnWidth.fixed(
                  width: Rem(5),
                  minimum: Rem(4),
                  maximum: Rem(8),
                ),
              ),
              CarpenterTreeTableColumn<_DocumentItem>.text(
                id: 'cipher',
                header: 'Шифр',
                value: (node) => node.value.cipher,
                width: const CarpenterTableColumnWidth.fixed(
                  width: Rem(10),
                  minimum: Rem(7),
                  maximum: Rem(16),
                ),
              ),
              CarpenterTreeTableColumn<_DocumentItem>.text(
                id: 'designer',
                header: 'Проектировщик',
                value: (node) => node.value.designer,
                width: const CarpenterTableColumnWidth.flexible(
                  preferred: Rem(12),
                  minimum: Rem(8),
                  maximum: Rem(20),
                ),
              ),
              CarpenterTreeTableColumn<_DocumentItem>.status(
                id: 'status',
                header: 'Статус',
                label: (node) => node.value.status,
                role: (node) => node.value.role,
                width: const CarpenterTableColumnWidth.fixed(
                  width: Rem(10),
                  minimum: Rem(8),
                  maximum: Rem(16),
                ),
              ),
              CarpenterTreeTableColumn<_DocumentItem>.actions(
                id: 'actions',
                header: '',
                actions: (node) => [
                  CarpenterActionDescriptor(
                    id: 'document.open.${node.id}',
                    label: 'Открыть',
                    icon: GravityIcons.folderOpen,
                    onInvoke: () {},
                  ),
                  CarpenterActionDescriptor(
                    id: 'document.edit.${node.id}',
                    label: 'Редактировать',
                    icon: GravityIcons.pencil,
                    onInvoke: () {},
                  ),
                ],
                secondaryActions: (node) => [
                  CarpenterActionDescriptor(
                    id: 'document.archive.${node.id}',
                    label: 'Архивировать',
                    icon: GravityIcons.archive,
                    onInvoke: () {},
                  ),
                ],
              ),
            ],
            expandedIds: _expanded,
            onExpansionChanged: (id, expanded) {
              setState(() {
                final next = {..._expanded};
                if (expanded) {
                  next.add(id);
                } else {
                  next.remove(id);
                }
                _expanded = next;
              });
            },
            selectionMode: CarpenterTreeSelectionMode.none,
            columnWidths: _documentWidths,
            onColumnWidthChanged: (id, width) =>
                setState(() => _documentWidths[id] = width),
          ),
        ],
      ),
    );
  }

  Widget _relations() {
    return CarpenterPageBody(
      semanticLabel: 'Связи проекта',
      children: [
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('relations.contracts'),
          title: 'Договоры',
          actions: [
            CarpenterButton.fromAction(
              CarpenterActionDescriptor(
                id: 'relations.contracts.add',
                label: 'Связать',
                icon: GravityIcons.plus,
                onInvoke: () {},
              ),
            ),
          ],
          child: const CarpenterNotice(
            title: 'Договоры пока не связаны',
            message: 'Связанные договоры появятся здесь.',
            tone: CarpenterNoticeTone.neutral,
          ),
        ),
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('relations.tasks'),
          title: 'Задачи',
          actions: [
            CarpenterButton.fromAction(
              CarpenterActionDescriptor(
                id: 'relations.tasks.add',
                label: 'Связать',
                icon: GravityIcons.plus,
                onInvoke: () {},
              ),
            ),
          ],
          child: const CarpenterNotice(
            title: 'Связанных задач пока нет',
            message: 'Задачи проекта появятся здесь.',
            tone: CarpenterNoticeTone.neutral,
          ),
        ),
      ],
    );
  }

  Widget _finance() {
    return CarpenterPageBody(
      semanticLabel: 'Финансы проекта',
      children: [
        const CarpenterRecordSummary(
          children: [
            CarpenterRecordMetric(
              label: 'Этапы оплаты',
              value: CarpenterText.title('4'),
              description: '360 дней суммарно',
            ),
            CarpenterRecordMetric(
              label: 'Авансы',
              value: CarpenterText.title('50 000 ₽'),
              description: 'Фактическая сумма',
            ),
            CarpenterRecordMetric(
              label: 'Выполнение',
              value: CarpenterText.title('400 ₽'),
              description: 'Фактическая сумма',
            ),
          ],
        ),
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('finance.stages'),
          title: 'Этапы оплаты',
          child: CarpenterTable<_PaymentStage, String>(
            semanticLabel: 'Этапы оплаты',
            snapshot: _readySnapshot(_paymentStages),
            rowKey: (row) => row.id,
            rowSemanticLabel: (row) => row.name,
            selection: CollectionSelection<String>.none(),
            showSelectionColumn: false,
            columns: [
              CarpenterTableColumn<_PaymentStage>.text(
                id: 'name',
                header: 'Название этапа',
                value: (row) => row.name,
                width: const CarpenterTableColumnWidth.flexible(flex: 2),
              ),
              CarpenterTableColumn<_PaymentStage>.number(
                id: 'amount',
                header: 'Сумма в руб.',
                value: (row) => row.amount,
                formatter: _money,
              ),
              CarpenterTableColumn<_PaymentStage>.number(
                id: 'term',
                header: 'Срок',
                value: (row) => row.term,
              ),
              CarpenterTableColumn<_PaymentStage>.number(
                id: 'ppd',
                header: 'Срок ПРД',
                value: (row) => row.ppdTerm,
              ),
              CarpenterTableColumn<_PaymentStage>.status(
                id: 'customer-act',
                header: 'Акт у заказчика',
                label: (row) => row.customerAct ? 'Да' : 'Нет',
                role: (row) => row.customerAct
                    ? FeedbackColorRole.success
                    : FeedbackColorRole.neutral,
              ),
              CarpenterTableColumn<_PaymentStage>.status(
                id: 'original-returned',
                header: 'Оригинал возвращён',
                label: (row) => row.originalReturned ? 'Да' : 'Нет',
                role: (row) => row.originalReturned
                    ? FeedbackColorRole.success
                    : FeedbackColorRole.neutral,
              ),
            ],
          ),
        ),
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('finance.advances'),
          title: 'Авансы',
          child: CarpenterTable<_Advance, String>(
            semanticLabel: 'Авансы',
            snapshot: _readySnapshot(_advances),
            rowKey: (row) => row.id,
            rowSemanticLabel: (row) => row.name,
            selection: CollectionSelection<String>.none(),
            showSelectionColumn: false,
            columns: [
              CarpenterTableColumn<_Advance>.text(
                id: 'name',
                header: 'Аванс',
                value: (row) => row.name,
                width: const CarpenterTableColumnWidth.flexible(flex: 2),
              ),
              CarpenterTableColumn<_Advance>.number(
                id: 'act-amount',
                header: 'Сумма акта',
                value: (row) => row.actAmount,
                formatter: _money,
              ),
              CarpenterTableColumn<_Advance>.text(
                id: 'act-date',
                header: 'Дата акта',
                value: (row) => row.actDate,
              ),
              CarpenterTableColumn<_Advance>.number(
                id: 'actual-amount',
                header: 'Факт. сумма',
                value: (row) => row.actualAmount,
                formatter: _money,
              ),
              CarpenterTableColumn<_Advance>.text(
                id: 'actual-date',
                header: 'Факт. дата',
                value: (row) => row.actualDate,
              ),
            ],
          ),
        ),
        CarpenterRecordSection(
          id: const CarpenterPageSectionId('finance.execution'),
          title: 'Выполнение',
          child: CarpenterTable<_Execution, String>(
            semanticLabel: 'Выполнение',
            snapshot: _readySnapshot(_execution),
            rowKey: (row) => row.id,
            rowSemanticLabel: (row) => row.name,
            selection: CollectionSelection<String>.none(),
            showSelectionColumn: false,
            columns: [
              CarpenterTableColumn<_Execution>.text(
                id: 'name',
                header: 'Выполнение',
                value: (row) => row.name,
                width: const CarpenterTableColumnWidth.flexible(flex: 2),
              ),
              CarpenterTableColumn<_Execution>.number(
                id: 'act-amount',
                header: 'Сумма акта',
                value: (row) => row.actAmount,
                formatter: _money,
              ),
              CarpenterTableColumn<_Execution>.text(
                id: 'act-date',
                header: 'Дата акта',
                value: (row) => row.actDate,
              ),
              CarpenterTableColumn<_Execution>.number(
                id: 'advance-offset',
                header: 'Зачёт аванса',
                value: (row) => row.advanceOffset,
                formatter: _money,
              ),
              CarpenterTableColumn<_Execution>.number(
                id: 'actual-amount',
                header: 'Факт. сумма',
                value: (row) => row.actualAmount,
                formatter: _money,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<CarpenterTreeNode<_DocumentItem>> get _filteredDocuments {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _documentNodes;

    CarpenterTreeNode<_DocumentItem>? filterNode(
      CarpenterTreeNode<_DocumentItem> node,
    ) {
      final children = node.children
          .map(filterNode)
          .whereType<CarpenterTreeNode<_DocumentItem>>()
          .toList(growable: false);
      final matches =
          node.label.toLowerCase().contains(query) ||
          node.value.cipher.toLowerCase().contains(query) ||
          node.value.designer.toLowerCase().contains(query);
      if (!matches && children.isEmpty) return null;
      return CarpenterTreeNode<_DocumentItem>(
        id: node.id,
        value: node.value,
        label: node.label,
        children: children,
      );
    }

    return _documentNodes
        .map(filterNode)
        .whereType<CarpenterTreeNode<_DocumentItem>>()
        .toList(growable: false);
  }
}

String _money(num value) => '${value.toInt()} ₽';

CollectionSnapshot<T> _readySnapshot<T>(List<T> items) {
  return CollectionSnapshot<T>(
    items: items,
    loadPhase: CollectionLoadPhase.ready,
    contentState: CollectionContentState.content,
    pageInfo: CollectionOffsetPageInfo(
      offset: 0,
      limit: items.length,
      itemCount: items.length,
      totalItems: items.length,
    ),
  );
}

final class _DocumentItem {
  const _DocumentItem({
    this.number,
    this.cipher = '',
    this.designer = '',
    this.status = 'Черновик',
    this.role = FeedbackColorRole.neutral,
  });

  final int? number;
  final String cipher;
  final String designer;
  final String status;
  final FeedbackColorRole role;
}

const _documentNodes = <CarpenterTreeNode<_DocumentItem>>[
  CarpenterTreeNode<_DocumentItem>(
    id: 'electrical',
    value: _DocumentItem(
      number: 1,
      cipher: 'ЭОМ',
      designer: 'А. Иванов',
      status: 'В работе',
      role: FeedbackColorRole.info,
    ),
    label: 'Электрика',
    children: [
      CarpenterTreeNode<_DocumentItem>(
        id: 'electrical-file-1',
        value: _DocumentItem(
          cipher: 'ЭОМ-01',
          designer: 'А. Иванов',
          status: 'Готов',
          role: FeedbackColorRole.success,
        ),
        label: 'Предварительный план.pdf',
      ),
      CarpenterTreeNode<_DocumentItem>(
        id: 'electrical-file-2',
        value: _DocumentItem(cipher: 'ЭОМ-02', designer: 'А. Иванов'),
        label: 'Электронный макет.dwg',
      ),
    ],
  ),
  CarpenterTreeNode<_DocumentItem>(
    id: 'heating',
    value: _DocumentItem(
      number: 2,
      cipher: 'ОВ',
      designer: 'М. Орлова',
      status: 'На проверке',
      role: FeedbackColorRole.warning,
    ),
    label: 'Отопление',
  ),
  CarpenterTreeNode<_DocumentItem>(
    id: 'test-section',
    value: _DocumentItem(number: 3, cipher: 'ТСТ'),
    label: 'Тестовый раздел',
  ),
  CarpenterTreeNode<_DocumentItem>(
    id: 'structures',
    value: _DocumentItem(
      number: 4,
      cipher: 'КР',
      designer: 'И. Петров',
      status: 'В работе',
      role: FeedbackColorRole.info,
    ),
    label: 'Конструкции',
    children: [
      CarpenterTreeNode<_DocumentItem>(
        id: 'structures-file-1',
        value: _DocumentItem(
          cipher: 'КР-01',
          designer: 'И. Петров',
          status: 'Готов',
          role: FeedbackColorRole.success,
        ),
        label: 'demo-1.jpg',
      ),
      CarpenterTreeNode<_DocumentItem>(
        id: 'structures-file-2',
        value: _DocumentItem(
          cipher: 'КР-02',
          designer: 'И. Петров',
          status: 'Готов',
          role: FeedbackColorRole.success,
        ),
        label: 'demo.jpg',
      ),
      CarpenterTreeNode<_DocumentItem>(
        id: 'structures-file-3',
        value: _DocumentItem(
          cipher: 'КР-03',
          designer: 'И. Петров',
          status: 'На проверке',
          role: FeedbackColorRole.warning,
        ),
        label: 'Предварительный расчёт.xlsx',
      ),
    ],
  ),
];

final class _PaymentStage {
  const _PaymentStage({
    required this.id,
    required this.name,
    required this.amount,
    required this.term,
    required this.ppdTerm,
    required this.customerAct,
    required this.originalReturned,
  });

  final String id;
  final String name;
  final int amount;
  final int term;
  final int ppdTerm;
  final bool customerAct;
  final bool originalReturned;
}

const _paymentStages = <_PaymentStage>[
  _PaymentStage(
    id: 'advance',
    name: 'Аванс',
    amount: 0,
    term: 90,
    ppdTerm: 0,
    customerAct: false,
    originalReturned: false,
  ),
  _PaymentStage(
    id: 'stage-1',
    name: 'Этап оплаты 1',
    amount: 0,
    term: 90,
    ppdTerm: 0,
    customerAct: true,
    originalReturned: false,
  ),
  _PaymentStage(
    id: 'stage-2',
    name: 'Этап оплаты 2',
    amount: 0,
    term: 90,
    ppdTerm: 0,
    customerAct: false,
    originalReturned: false,
  ),
  _PaymentStage(
    id: 'stage-3',
    name: 'Этап оплаты 3',
    amount: 0,
    term: 90,
    ppdTerm: 0,
    customerAct: false,
    originalReturned: false,
  ),
];

final class _Advance {
  const _Advance({
    required this.id,
    required this.name,
    required this.actAmount,
    required this.actDate,
    required this.actualAmount,
    required this.actualDate,
  });

  final String id;
  final String name;
  final int actAmount;
  final String actDate;
  final int actualAmount;
  final String actualDate;
}

const _advances = <_Advance>[
  _Advance(
    id: 'advance-1',
    name: 'Демо-аванс',
    actAmount: 0,
    actDate: '20.08.2026',
    actualAmount: 50000,
    actualDate: '26.05.2026',
  ),
];

final class _Execution {
  const _Execution({
    required this.id,
    required this.name,
    required this.actAmount,
    required this.actDate,
    required this.advanceOffset,
    required this.actualAmount,
  });

  final String id;
  final String name;
  final int actAmount;
  final String actDate;
  final int advanceOffset;
  final int actualAmount;
}

const _execution = <_Execution>[
  _Execution(
    id: 'execution-1',
    name: 'Этап выполнения 1',
    actAmount: 0,
    actDate: '20.08.2026',
    advanceOffset: 0,
    actualAmount: 400,
  ),
];
