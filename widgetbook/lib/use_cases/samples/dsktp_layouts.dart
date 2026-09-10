import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/layout_viewport.dart';

final dsktpLayoutsComponent = WidgetbookComponent(
  name: 'Desktop project layouts',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: DsktpProjectLayout(
          longContent: context.knobs.boolean(
            label: 'Длинные значения',
            initialValue: true,
          ),
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Materials workspace',
      builder: (context) => layoutViewportPreview(
        context,
        child: DsktpMaterialsLayout(
          loading: context.knobs.boolean(label: 'Загрузка таблицы'),
        ),
      ),
    ),
  ],
);

/// Mirrors dsktp project_change_page.dart and project_change_summary.dart.
/// Data and editing live here; the library receives only widgets and actions.
class DsktpProjectLayout extends StatefulWidget {
  const DsktpProjectLayout({super.key, this.longContent = true});
  final bool longContent;

  @override
  State<DsktpProjectLayout> createState() => _ProjectState();
}

class _ProjectState extends State<DsktpProjectLayout> {
  final _draft = TextEditingController();
  String? _editing;
  final _saved = <String, String>{};
  bool _suspended = true;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        'name',
        'Ник',
        widget.longContent
            ? 'Реконструкция инженерных сетей жилого квартала «Северный парк»'
            : 'Северный парк',
      ),
      (
        'customer',
        'Контрагент-заказчик',
        widget.longContent
            ? 'ООО «Специализированный застройщик Северный квартал»'
            : 'ООО «Заказчик»',
      ),
      ('p', '№ документа стадии П', '2026-09/П-104'),
      ('r', '№ документа стадии Р', '2026-09/Р-104'),
    ];
    return CarpenterPage(
      descriptor: const CarpenterPageDescriptor(
        id: CarpenterPageId('sample.project'),
        title: 'Проект',
        kind: CarpenterPageKind.record,
      ),
      header: CarpenterPageHeader(
        title: '№104. ${_saved['name'] ?? values.first.$3}',
        status: const CarpenterPageStatus(
          label: 'На согласовании',
          role: FeedbackColorRole.info,
        ),
        actions: CarpenterHeaderActions(
          primary: [
            CarpenterActionDescriptor(
              id: 'edit',
              label: 'Редактировать',
              icon: GravityIcons.pencil,
              onInvoke: () => _edit(values.first),
            ),
          ],
          secondary: [
            CarpenterActionDescriptor(
              id: 'refresh',
              label: 'Обновить',
              icon: GravityIcons.arrowRotateRight,
              onInvoke: () => setState(_saved.clear),
            ),
          ],
          overflowLabel: 'Ещё',
        ),
      ),
      body: CarpenterPageBody(
        children: [
          CarpenterDefinitionList<(String, String, String)>(
            items: values,
            term: (item) => item.$2,
            valueBuilder: (context, item) => _editing == item.$1
                ? CarpenterInput(
                    controller: _draft,
                    semanticLabel: item.$2,
                    onSubmitted: (_) => _save(),
                  )
                : CarpenterBlockGroup(
                    children: [
                      if (item.$1 == 'customer')
                        CarpenterLink(
                          label: _saved[item.$1] ?? item.$3,
                          onInvoke: () => _edit(item),
                        )
                      else
                        CarpenterText.body(_saved[item.$1] ?? item.$3),
                      if (item.$1 == 'name' && _suspended)
                        const CarpenterStatusIndicator(
                          label: 'Приостановлен',
                          role: FeedbackColorRole.warning,
                        ),
                    ],
                  ),
            actions: (item) => [
              CarpenterActionDescriptor(
                id: '${item.$1}.edit',
                label: _editing == item.$1 ? 'Сохранить' : 'Изменить',
                icon: _editing == item.$1
                    ? GravityIcons.check
                    : GravityIcons.pencil,
                onInvoke: () => _editing == item.$1 ? _save() : _edit(item),
              ),
              if (_editing == item.$1)
                CarpenterActionDescriptor(
                  id: '${item.$1}.cancel',
                  label: 'Отмена',
                  icon: GravityIcons.xmark,
                  onInvoke: () => setState(() => _editing = null),
                ),
            ],
            secondaryActions: (item) => item.$1 == 'name'
                ? [
                    CarpenterActionDescriptor(
                      id: 'suspend',
                      label: _suspended ? 'Возобновить' : 'Приостановить',
                      onInvoke: () => setState(() => _suspended = !_suspended),
                    ),
                  ]
                : [],
            semanticLabel: 'Основные данные проекта',
            actionsOverflowLabel: 'Ещё действия',
          ),
          const CarpenterRecordSection(
            id: CarpenterPageSectionId('sample.materials'),
            title: 'Материалы проекта',
            child: SizedBox(height: 640, child: DsktpMaterialsLayout()),
          ),
        ],
      ),
    );
  }

  void _edit((String, String, String) item) => setState(() {
    _editing = item.$1;
    _draft.text = _saved[item.$1] ?? item.$3;
  });
  void _save() => setState(() {
    _saved[_editing!] = _draft.text;
    _editing = null;
  });
}

/// Mirrors the bounded embedded workspace in project_materials_page_base.dart.
class DsktpMaterialsLayout extends StatefulWidget {
  const DsktpMaterialsLayout({super.key, this.loading = false});
  final bool loading;
  @override
  State<DsktpMaterialsLayout> createState() => _MaterialsState();
}

class _MaterialsState extends State<DsktpMaterialsLayout> {
  final _search = TextEditingController();
  String _location = 'folder';
  final _files = [
    'Пояснительная записка.pdf',
    'Схема электроснабжения жилого квартала.dwg',
    'Расчёт электрических нагрузок.xlsx',
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(
      context.units(CarpenterTheme.of(context).spacing.layoutSection),
    ),
    child: CarpenterSectionLayout(
      title: '',
      header: CarpenterHeaderActions(
        primary: [
          CarpenterActionDescriptor(
            id: 'folder',
            label: 'Добавить том',
            icon: GravityIcons.folderPlus,
            onInvoke: () =>
                setState(() => _files.add('Новый том ${_files.length + 1}')),
          ),
          CarpenterActionDescriptor(
            id: 'file',
            label: 'Добавить файл',
            icon: GravityIcons.filePlus,
            onInvoke: () => setState(
              () => _files.add('Новый файл ${_files.length + 1}.pdf'),
            ),
          ),
        ],
        secondary: [
          CarpenterActionDescriptor(
            id: 'refresh',
            label: 'Обновить',
            icon: GravityIcons.arrowRotateRight,
            onInvoke: () => setState(_search.clear),
          ),
        ],
        overflowLabel: 'Ещё',
      ),
      navigation: CarpenterBlockGroup(
        children: [
          CarpenterExplorerLocationStrip<String>(
            current: _location,
            primaryDestinations: const [
              CarpenterExplorerDestination(
                location: 'common',
                label: 'Общее',
                icon: GravityIcons.folder,
              ),
              CarpenterExplorerDestination(
                location: 'p',
                label: 'Тома П',
                icon: GravityIcons.folder,
              ),
              CarpenterExplorerDestination(
                location: 'r',
                label: 'Тома Р',
                icon: GravityIcons.folder,
              ),
            ],
            rememberedDestination: const CarpenterExplorerDestination(
              location: 'folder',
              label: 'Система электроснабжения',
              icon: GravityIcons.folderOpen,
            ),
            onChanged: (value) => setState(() => _location = value),
          ),
          CarpenterBreadcrumbs(
            items: [
              CarpenterBreadcrumb(
                label: 'Материалы',
                onInvoke: () => setState(() => _location = 'common'),
              ),
              CarpenterBreadcrumb(
                label: 'Тома П',
                onInvoke: () => setState(() => _location = 'p'),
              ),
              CarpenterBreadcrumb(
                label: _location == 'folder'
                    ? 'Система электроснабжения'
                    : _location == 'r'
                    ? 'Тома Р'
                    : _location == 'p'
                    ? 'Тома П'
                    : 'Общее',
              ),
            ],
          ),
          CarpenterInput(
            controller: _search,
            label: 'Поиск в текущем разделе',
            placeholder: 'Название материала',
            leadingIcon: GravityIcons.magnifier,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      child: widget.loading
          ? const CarpenterText.body('Загрузка материалов')
          : SingleChildScrollView(
              child: CarpenterTreeTable<String>(
                semanticLabel: 'Материалы проекта',
                nodes: [
                  for (final file in _files.where(
                    (file) =>
                        file.toLowerCase().contains(_search.text.toLowerCase()),
                  ))
                    CarpenterTreeNode(id: file, value: file, label: file),
                ],
                treeHeader: 'Наименование',
                columns: [
                  CarpenterTreeTableColumn<String>.text(
                    id: 'cipher',
                    header: 'Шифр',
                    value: (node) => 'ЭОМ-${_files.indexOf(node.value) + 1}',
                  ),
                  CarpenterTreeTableColumn<String>.text(
                    id: 'author',
                    header: 'Проектировщик',
                    value: (_) => 'Анна Иванова',
                  ),
                ],
              ),
            ),
    ),
  );
}
