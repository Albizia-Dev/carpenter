import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../helpers/layout_viewport.dart';

final dsktpCollectionsComponent = WidgetbookComponent(
  name: 'Desktop lists and trees',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) =>
          layoutViewportPreview(context, child: const DsktpCollectionsLayout()),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Project folders',
      builder: (context) => layoutViewportPreview(
        context,
        child: const DsktpCollectionsLayout(tree: true),
      ),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Nested audit sections',
      builder: (context) =>
          layoutViewportPreview(context, child: const DsktpAccordionLayout()),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Grouped payments',
      builder: (context) =>
          layoutViewportPreview(context, child: const DsktpGroupedListLayout()),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Legal entities and accounts',
      builder: (context) => layoutViewportPreview(
        context,
        child: const DsktpGroupedListLayout(accounts: true),
      ),
    ),
  ],
);

/// Compositions from dsktp payment/account tiles and project folder usage.
/// All data and controlled state belong to this demo, not the library.
class DsktpCollectionsLayout extends StatefulWidget {
  const DsktpCollectionsLayout({super.key, this.tree = false});
  final bool tree;
  @override
  State<DsktpCollectionsLayout> createState() => _CollectionsState();
}

class _CollectionsState extends State<DsktpCollectionsLayout> {
  Set<Object> _expanded = {'project', 'p', 'engineering'};
  Set<Object> _selected = {'electrical'};
  int _payment = 1;
  static const _nodes = [
    CarpenterTreeNode<String>(
      id: 'project',
      value: '',
      label: 'Северный парк · Реконструкция',
      children: [
        CarpenterTreeNode<String>(
          id: 'p',
          value: '',
          label: 'Проектная документация',
          children: [
            CarpenterTreeNode<String>(
              id: 'note',
              value: '',
              label: 'Пояснительная записка.pdf',
            ),
            CarpenterTreeNode<String>(
              id: 'engineering',
              value: '',
              label: 'Инженерные системы',
              children: [
                CarpenterTreeNode<String>(
                  id: 'electrical',
                  value: '',
                  label: 'Электроснабжение и наружное освещение территории.pdf',
                ),
                CarpenterTreeNode<String>(
                  id: 'water',
                  value: '',
                  label: 'Водоснабжение.pdf',
                ),
              ],
            ),
            CarpenterTreeNode<String>(
              id: 'budget',
              value: '',
              label: 'Сметная документация.xlsx',
            ),
          ],
        ),
        CarpenterTreeNode<String>(
          id: 'r',
          value: '',
          label: 'Рабочая документация',
          hasChildren: true,
        ),
        CarpenterTreeNode<String>(
          id: 'readme',
          value: '',
          label: 'Состав проекта.pdf',
        ),
      ],
    ),
    CarpenterTreeNode<String>(
      id: 'archive',
      value: '',
      label: 'Архив согласований',
      hasChildren: true,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.units(theme.spacing.layoutSection)),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.units(theme.sizes.layoutPageMaxWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarpenterText.title(
                widget.tree ? 'Материалы проекта' : 'Платежи и счета',
                emphasis: TypographyEmphasis.strong,
              ),
              SizedBox(height: gap / 2),
              CarpenterText.body(
                widget.tree
                    ? 'Северный парк / Документация'
                    : 'ООО «Северный квартал» · Сентябрь 2026',
                colorRole: ContentColorRole.secondary,
              ),
              SizedBox(height: gap * 2),
              if (widget.tree)
                CarpenterCard(
                  padded: false,
                  child: CarpenterTreeView<String>(
                    nodes: _nodes,
                    expandedIds: _expanded,
                    selectedIds: _selected,
                    onExpansionChanged: (id, expanded) => setState(() {
                      _expanded = {..._expanded};
                      expanded ? _expanded.add(id) : _expanded.remove(id);
                    }),
                    onSelectionChanged: (ids) =>
                        setState(() => _selected = ids),
                    iconBuilder: (node) => node.canExpand
                        ? GravityIcons.folder
                        : GravityIcons.file,
                  ),
                )
              else ...[
                const CarpenterText.label(
                  'Последние платежи',
                  emphasis: TypographyEmphasis.strong,
                ),
                SizedBox(height: gap),
                CarpenterCard(
                  padded: false,
                  child: Column(
                    children: [
                      for (final (index, item) in _payments.indexed) ...[
                        if (index > 0)
                          Container(height: 1, color: theme.overlay.border),
                        CarpenterListTile(
                          selected: _payment == index,
                          onInvoke: () => setState(() => _payment = index),
                          leading: CarpenterIcon(
                            item.incoming
                                ? GravityIcons.arrowDownLeft
                                : GravityIcons.arrowUpRight,
                          ),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.purpose,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: gap / 2),
                              CarpenterText.caption(
                                '10 сентября · № ${1042 + index}',
                                colorRole: ContentColorRole.secondary,
                              ),
                            ],
                          ),
                          trailing: CarpenterText.label(
                            item.amount,
                            emphasis: TypographyEmphasis.strong,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: gap * 2),
                const CarpenterText.label(
                  'Банковские счета',
                  emphasis: TypographyEmphasis.strong,
                ),
                SizedBox(height: gap),
                CarpenterCard(
                  padded: false,
                  child: Column(
                    children: [
                      for (final (index, bank) in [
                        'Альфа-Банк',
                        'Сбербанк',
                      ].indexed) ...[
                        if (index > 0)
                          Container(height: 1, color: theme.overlay.border),
                        CarpenterListTile(
                          leading: const CarpenterIcon(GravityIcons.briefcase),
                          title: Text(bank),
                          subtitle: Text(
                            index == 0
                                ? 'Основной расчётный · •• 4821\nRUB · Обновлён сегодня, 09:42'
                                : 'Резервный · •• 9130\nRUB · Обновлён вчера',
                          ),
                          trailing: CarpenterText.label(
                            index == 0 ? '12 480 350,00 ₽' : '840 000,00 ₽',
                            emphasis: TypographyEmphasis.strong,
                            textAlign: TextAlign.end,
                          ),
                          onInvoke: () {},
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _payments = [
  (
    name: 'АО «Городские инженерные сети»',
    purpose:
        'Оплата выполненных работ по договору № 18/26. Реконструкция инженерных сетей жилого квартала.',
    amount: '+ 2 450 000,00 ₽',
    incoming: true,
  ),
  (
    name: 'ООО «Электрокомплект»',
    purpose:
        'Кабельная продукция и оборудование наружного освещения. Счёт № 482 от 08.09.2026.',
    amount: '− 684 250,50 ₽',
    incoming: false,
  ),
  (
    name: 'ООО «Проектное бюро Север»',
    purpose: 'Аванс за разработку рабочей документации',
    amount: '− 320 000,00 ₽',
    incoming: false,
  ),
  (
    name: 'Возврат от поставщика',
    purpose: 'Возврат излишне перечисленных средств',
    amount: '+ 18 750,00 ₽',
    incoming: true,
  ),
];

/// Nested audit scopes and linked import entities, following dsktp treasury.
class DsktpAccordionLayout extends StatelessWidget {
  const DsktpAccordionLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    Widget header(String title, String count, {bool warning = false}) => Wrap(
      spacing: gap,
      runSpacing: gap / 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title),
        CarpenterTag(
          label: count,
          tone: warning ? CarpenterTagTone.warning : CarpenterTagTone.neutral,
        ),
      ],
    );
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.units(theme.spacing.layoutSection)),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.units(theme.sizes.layoutPageMaxWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CarpenterText.title(
                'Проверка казначейства',
                emphasis: TypographyEmphasis.strong,
              ),
              SizedBox(height: gap / 2),
              const CarpenterText.body(
                'Северный квартал · Выписка за сентябрь',
                colorRole: ContentColorRole.secondary,
              ),
              SizedBox(height: gap * 2),
              CarpenterExpander(
                initiallyExpanded: true,
                header: header('Платежи', '3 замечания', warning: true),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CarpenterExpander.listGroup(
                      initiallyExpanded: true,
                      header: header(
                        'Не удалось определить контрагента',
                        '2 платежа',
                        warning: true,
                      ),
                      content: Column(
                        children: [
                          CarpenterListTile(
                            title: const Text('ООО «Электрокомплект»'),
                            subtitle: const Text(
                              'Назначение: поставка кабельной продукции. Проверьте реквизиты получателя.',
                            ),
                            trailing: const CarpenterText.label('684 250,50 ₽'),
                            onInvoke: () {},
                          ),
                          CarpenterListTile(
                            title: const Text('Проектное бюро Север'),
                            subtitle: const Text('Аванс по договору № 18/26'),
                            trailing: const CarpenterText.label('320 000,00 ₽'),
                            onInvoke: () {},
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    CarpenterExpander(
                      header: header('Возможные дубликаты', '1 группа'),
                      content: const CarpenterText.body(
                        'Два платежа с совпадающими датой, суммой и получателем.',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              CarpenterExpander.listGroup(
                initiallyExpanded: true,
                header: header('Связанные расчётные счета', '2 счёта'),
                content: const Column(
                  children: [
                    CarpenterListTile(
                      title: Text('Альфа-Банк · Основной расчётный'),
                      subtitle: Text('•• 4821 · 01–10 сентября 2026'),
                    ),
                    CarpenterListTile(
                      title: Text('Сбербанк · Резервный'),
                      subtitle: Text('•• 9130 · 01–10 сентября 2026'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              CarpenterExpander(
                header: header(
                  'История загрузки и технические сведения',
                  '4 события',
                ),
                content: const CarpenterText.body(
                  'Выписка загружена 10 сентября в 09:42. Обработано 24 операции.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Homogeneous payments grouped in one surface; rows own all content insets.
class DsktpGroupedListLayout extends StatefulWidget {
  const DsktpGroupedListLayout({super.key, this.accounts = false});
  final bool accounts;
  @override
  State<DsktpGroupedListLayout> createState() => _GroupedListState();
}

class _GroupedListState extends State<DsktpGroupedListLayout> {
  int? _selected = 1;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final items = widget.accounts ? _accounts : _payments;
    Widget group(String title, List<int> indices) =>
        CarpenterExpander.listGroup(
          initiallyExpanded: true,
          header: Wrap(
            spacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title),
              CarpenterText.caption(
                '${indices.length} ${widget.accounts ? 'счёта' : 'платежа'}',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (position, index) in indices.indexed) ...[
                if (position > 0)
                  Container(height: 1, color: theme.overlay.border),
                CarpenterListTile(
                  selected: _selected == index,
                  onInvoke: () => setState(() => _selected = index),
                  leading: CarpenterIcon(
                    widget.accounts
                        ? GravityIcons.briefcase
                        : items[index].incoming
                        ? GravityIcons.arrowDownLeft
                        : GravityIcons.arrowUpRight,
                  ),
                  title: Text(items[index].name),
                  subtitle: Text(
                    items[index].purpose,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: CarpenterText.label(
                    items[index].amount,
                    emphasis: TypographyEmphasis.strong,
                  ),
                ),
              ],
            ],
          ),
        );
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.units(theme.spacing.layoutSection)),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.units(theme.sizes.layoutPageMaxWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarpenterText.title(
                widget.accounts ? 'Счета юридических лиц' : 'Платежи по дням',
                emphasis: TypographyEmphasis.strong,
              ),
              SizedBox(height: gap / 2),
              CarpenterText.body(
                widget.accounts
                    ? 'Расчётные счета · Остатки в RUB'
                    : 'Северный квартал · Сентябрь 2026',
                colorRole: ContentColorRole.secondary,
              ),
              SizedBox(height: gap * 2),
              CarpenterCard(
                padded: false,
                child: Column(
                  children: [
                    group(
                      widget.accounts
                          ? 'ООО «Северный квартал»'
                          : '10 сентября',
                      [0, 1],
                    ),
                    group(
                      widget.accounts
                          ? 'ООО «Проектное бюро Север»'
                          : '9 сентября',
                      [2, 3],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _accounts = [
  (
    name: 'Альфа-Банк · Основной расчётный',
    purpose: '•• 4821 · RUB · Обновлён сегодня, 09:42',
    amount: '12 480 350,00 ₽',
    incoming: false,
  ),
  (
    name: 'Сбербанк · Резервный',
    purpose: '•• 9130 · RUB · Обновлён сегодня, 09:38',
    amount: '840 000,00 ₽',
    incoming: false,
  ),
  (
    name: 'Т-Банк · Операционный',
    purpose: '•• 2075 · RUB · Обновлён сегодня, 09:40',
    amount: '2 150 700,00 ₽',
    incoming: false,
  ),
  (
    name: 'Газпромбанк · Проектный',
    purpose: '•• 6612 · RUB · Обновлён вчера, 18:15',
    amount: '320 000,00 ₽',
    incoming: false,
  ),
];
