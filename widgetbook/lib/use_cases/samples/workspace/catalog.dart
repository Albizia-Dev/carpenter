import 'package:carpenter/carpenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../helpers/layout_viewport.dart';
import 'scenarios.dart';

final workspaceShellComponent = WidgetbookComponent(
  name: 'Contextual workspace',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: WorkspaceShellPreview(
          scenario: context.knobs.object.dropdown(
            label: 'Состояние',
            options: workspaceScenarioLabels.keys.toList(),
            initialOption: 'ready',
            labelBuilder: (s) => workspaceScenarioLabels[s]!,
          ),
          applicationLabel: context.knobs.string(
            label: 'Приложение',
            initialValue: 'Okibi · Fermat',
          ),
          workspaceLabel: context.knobs.string(
            label: 'Рабочий раздел',
            initialValue: 'Казначейство',
          ),
          caption: context.knobs.string(
            label: 'Подпись переключателя',
            initialValue: 'Все разделы',
          ),
          expanded: context.knobs.boolean(
            label: 'Навигация раскрыта',
            initialValue: true,
          ),
          visible: context.knobs.boolean(
            label: 'Навигация видна',
            initialValue: true,
          ),
          searchVisible: context.knobs.boolean(
            label: 'Поиск доступен',
            initialValue: true,
          ),
          actionsVisible: context.knobs.boolean(
            label: 'Глобальные действия',
            initialValue: true,
          ),
          footerVisible: context.knobs.boolean(
            label: 'Нижняя строка',
            initialValue: true,
          ),
          switcherEnabled: context.knobs.boolean(
            label: 'Выбор раздела доступен',
            initialValue: true,
          ),
          showBreadcrumbs: context.knobs.boolean(
            label: 'Путь страницы',
            initialValue: true,
          ),
          showNativeBar: context.knobs.boolean(
            label: 'Зона нативного хоста',
            initialValue: false,
          ),
          adjustForText: context.knobs.boolean(
            label: 'Учитывать масштаб текста',
            initialValue: true,
          ),
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'States · Mobile navigation',
      builder: (context) => layoutViewportFrame(
        context,
        preset: LayoutViewportPreset.mobilePortrait,
        child: const WorkspaceShellPreview(scenario: 'mobile_open'),
      ),
    ),
    WidgetbookUseCase(
      name: 'States · Tablet overlay',
      builder: (context) => layoutViewportFrame(
        context,
        preset: LayoutViewportPreset.tabletPortrait,
        child: const WorkspaceShellPreview(scenario: 'tablet_open'),
      ),
    ),
    WidgetbookUseCase(
      name: 'Edge cases · Three project contours',
      builder: (_) => const WorkspaceShellPreview(scenario: 'projects'),
    ),
    WidgetbookUseCase(
      name: 'Edge cases · Long labels',
      builder: (_) => const WorkspaceShellPreview(scenario: 'long'),
    ),
    WidgetbookUseCase(
      name: 'Accessibility',
      builder: (_) => const WorkspaceShellPreview(scenario: 'search'),
    ),
  ],
);

/// Backend-free composition of real shell states, using only public Carpenter.
class WorkspaceShellPreview extends StatefulWidget {
  const WorkspaceShellPreview({
    super.key,
    this.scenario = 'ready',
    this.applicationLabel = 'Okibi · Fermat',
    this.workspaceLabel = 'Казначейство',
    this.caption = 'Все разделы',
    this.expanded = true,
    this.visible = true,
    this.searchVisible = true,
    this.actionsVisible = true,
    this.footerVisible = true,
    this.switcherEnabled = true,
    this.showBreadcrumbs = true,
    this.showNativeBar = false,
    this.adjustForText = true,
  });
  final String scenario, applicationLabel, workspaceLabel, caption;
  final bool expanded, visible, searchVisible, actionsVisible, footerVisible;
  final bool switcherEnabled, showBreadcrumbs, showNativeBar, adjustForText;
  @override
  State<WorkspaceShellPreview> createState() => _WorkspaceShellPreviewState();
}

class _WorkspaceShellPreviewState extends State<WorkspaceShellPreview> {
  final _query = TextEditingController();
  final _draft = TextEditingController(text: 'Оплата по договору № 18/26');
  late String _scene;
  late bool _open, _expanded, _visible;
  String _selected = 'payments';
  String? _dialog;
  String? _pending;
  bool _dirty = false;
  bool _pinned = true;
  double get _gap => context.units(CarpenterTheme.of(context).spacing.medium);

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(WorkspaceShellPreview old) {
    super.didUpdateWidget(old);
    if (old.scenario != widget.scenario ||
        old.expanded != widget.expanded ||
        old.visible != widget.visible) {
      _configure();
    }
  }

  void _configure() {
    _scene = widget.scenario;
    _open = ['mobile_open', 'tablet_open'].contains(_scene);
    _expanded = widget.expanded && !['rail', 'tablet'].contains(_scene);
    _visible = widget.visible && _scene != 'focus';
    _dirty = ['draft', 'leave', 'saving', 'save_error'].contains(_scene);
    _pinned = _scene != 'pin_empty';
    _selected = _scene == 'projects'
        ? 'projects-plus'
        : _scene == 'courier'
        ? 'today'
        : 'payments';
    _dialog =
        [
              'modules',
              'module_empty',
              'mobile_modules',
              'profile',
              'appearance',
              'about',
              'leave',
              'logout',
              'expired',
              'incoming',
            ].contains(_scene) ||
            _scene.startsWith('search') ||
            _scene.startsWith('inbox')
        ? _scene
        : null;
    _query.text = _scene == 'search_results'
        ? 'плат'
        : ['search_empty', 'module_empty'].contains(_scene)
        ? 'абракадабра'
        : '';
  }

  @override
  void dispose() {
    _query.dispose();
    _draft.dispose();
    super.dispose();
  }

  static const _pages = [
    ('payments', 'Платежи', GravityIcons.creditCard),
    ('accounts', 'Расчётные счета', GravityIcons.creditCard),
    ('imports', 'Импорт выписок', GravityIcons.fileArrowDown),
    ('reconciliation', 'Сверка платежей', GravityIcons.link),
    ('banks', 'Банки', GravityIcons.house),
    ('connections', 'Подключения банков', GravityIcons.plugConnection),
    ('entities', 'Юридические лица', GravityIcons.person),
  ];
  List<(String, String, Object)> get _items => _scene == 'courier'
      ? [
          ('today', 'Сегодня', GravityIcons.calendar),
          ('trips', 'Список поездок', GravityIcons.car),
        ]
      : _scene == 'projects'
      ? [
          ('projects', 'Проекты', GravityIcons.folder),
          ('projects-new', 'Проекты (НОВОЕ)', GravityIcons.folder),
          ('projects-plus', 'Проекты+', GravityIcons.folderOpen),
        ]
      : _scene == 'no_access'
      ? []
      : _pages;
  String get _workspace => _scene == 'courier'
      ? 'Поездки'
      : _scene == 'projects'
      ? 'Проекты'
      : widget.workspaceLabel;
  String get _title =>
      _items.where((i) => i.$1 == _selected).firstOrNull?.$2 ??
      'Рабочая страница';
  void _navigate(String id) {
    if (_dirty) {
      setState(() {
        _pending = id;
        _dialog = 'leave';
      });
      return;
    }
    setState(() {
      _selected = id;
      _open = false;
      _dialog = null;
    });
  }

  void _show(String dialog) => setState(() {
    _query.clear();
    _dialog = dialog;
  });
  void _close() => setState(() => _dialog = null);
  CarpenterActionDescriptor _action(
    String id,
    String label,
    VoidCallback callback, {
    Object? icon,
    ActionColorRole role = ActionColorRole.neutral,
  }) => CarpenterActionDescriptor(
    id: id,
    label: label,
    onInvoke: callback,
    icon: icon,
    colorRole: role,
  );

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final body = CarpenterWorkspaceShell(
      applicationLabel: widget.applicationLabel,
      workspaceLabel: _workspace,
      workspaceCaption: widget.caption,
      onWorkspacePressed: widget.switcherEnabled
          ? () => _show('modules')
          : null,
      sidebarExpanded: _expanded,
      onSidebarExpandedChanged: (v) => setState(() => _expanded = v),
      sidebarVisible: _visible,
      onSidebarVisibleChanged: (v) => setState(() => _visible = v),
      sidebarOpen: _open,
      onSidebarOpenChanged: (v) => setState(() => _open = v),
      viewportPolicy: CarpenterViewportPolicy(
        accountForTextScale: widget.adjustForText,
      ),
      breadcrumbs: widget.showBreadcrumbs
          ? [
              CarpenterBreadcrumb(
                label: _workspace,
                onInvoke: () => _show('modules'),
              ),
              CarpenterBreadcrumb(label: _title),
            ]
          : [],
      searchAction: !widget.searchVisible
          ? null
          : CarpenterActionDescriptor(
              id: 'search',
              label: 'Перейти к…',
              icon: GravityIcons.magnifier,
              onInvoke: () => _show('search'),
              shortcut: SingleActivator(
                LogicalKeyboardKey.keyK,
                meta: defaultTargetPlatform == TargetPlatform.macOS,
                control: defaultTargetPlatform != TargetPlatform.macOS,
              ),
            ),
      actions: !widget.actionsVisible
          ? []
          : [
              CarpenterIconButton(
                icon: GravityIcons.bell,
                semanticLabel: 'Входящие, 3 события',
                onPressed: () => _show('inbox'),
                prominence: ActionProminence.ghost,
              ),
              CarpenterIconButton(
                icon: GravityIcons.person,
                semanticLabel: 'Мой профиль',
                onPressed: () => _show('profile'),
                prominence: ActionProminence.ghost,
              ),
            ],
      navigation: CarpenterSidebarData(
        selectedId: _selected,
        onSelected: _navigate,
        sections: [
          CarpenterSidebarSection(
            label: 'В этом разделе',
            items: [
              for (final i in _items)
                CarpenterSidebarItem(
                  id: i.$1,
                  label: _scene == 'long' && i.$1 == 'imports'
                      ? 'Импорт банковских выписок по всем юридическим лицам'
                      : i.$2,
                  icon: i.$3,
                ),
            ],
          ),
          if (_scene != 'no_access' && _scene != 'courier')
            CarpenterSidebarSection(
              label: 'Закреплено',
              items: [
                if (_pinned)
                  CarpenterSidebarItem(
                    id: 'projects-plus',
                    label: 'Проекты+',
                    icon: GravityIcons.pin,
                  ),
              ],
            ),
        ],
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterButton(
              label: 'Мессенджер',
              icon: GravityIcons.comment,
              onPressed: () => _navigate('messenger'),
              prominence: ActionProminence.ghost,
            ),
            CarpenterButton(
              label: 'Закрепить страницу',
              icon: GravityIcons.pin,
              onPressed: () => setState(() => _pinned = !_pinned),
              prominence: ActionProminence.ghost,
            ),
          ],
        ),
        compactFooter: CarpenterIconButton(
          icon: GravityIcons.comment,
          semanticLabel: 'Мессенджер',
          onPressed: () => _navigate('messenger'),
        ),
      ),
      notice: _notice(),
      activity: ['call', 'muted', 'conference', 'call_offline'].contains(_scene)
          ? CarpenterNotice(
              title: _scene == 'conference'
                  ? 'Конференция · 4 участника'
                  : 'Звонок · Алексей · 04:32',
              message: _scene == 'muted' ? 'Микрофон выключен' : null,
              action: _action(
                'mute',
                _scene == 'muted' ? 'Включить микрофон' : 'Выключить микрофон',
                () => setState(
                  () => _scene = _scene == 'muted' ? 'call' : 'muted',
                ),
                icon: GravityIcons.microphone,
              ),
              onClose: () => setState(() => _scene = 'ready'),
            )
          : null,
      footer: widget.footerVisible
          ? Padding(
              padding: EdgeInsets.all(_gap / 2),
              child: const CarpenterText.caption(
                'Fermat · демонстрационные данные',
                colorRole: ContentColorRole.secondary,
              ),
            )
          : null,
      nativeTitleBar: widget.showNativeBar || _scene == 'native'
          ? ColoredBox(
              color: theme.surface.subtle,
              child: Padding(
                padding: EdgeInsets.all(_gap / 2),
                child: const CarpenterText.caption(
                  'Okibi · зона управления нативным окном',
                ),
              ),
            )
          : null,
      body: _page(),
    );
    return Overlay.wrap(
      child: CarpenterDialog(
        open: _dialog != null,
        onOpenChanged: (v) {
          if (!v) _close();
        },
        title: _dialogTitle,
        presentation: _dialog?.startsWith('inbox') == true
            ? CarpenterDialogPresentation.editor
            : CarpenterDialogPresentation.centered,
        content: _dialogContent(),
        actions: _dialogActions,
        dismissPolicy: _dialog == 'expired'
            ? DialogDismissPolicy.explicitOnly
            : DialogDismissPolicy.escapeOnly,
        child: body,
      ),
    );
  }

  Widget? _notice() {
    if (['offline', 'call_offline', 'reconnect'].contains(_scene)) {
      return CarpenterNotice(
        title: _scene == 'reconnect'
            ? 'Восстанавливаем соединение…'
            : 'Нет соединения',
        message: 'Данные могут быть устаревшими.',
        tone: CarpenterNoticeTone.warning,
        action: _action(
          'retry',
          'Повторить',
          () => setState(() => _scene = 'recovered'),
        ),
      );
    }
    if (['update', 'updating'].contains(_scene)) {
      return CarpenterNotice(
        title: _scene == 'updating'
            ? 'Подготовка обновления…'
            : 'Доступна новая версия',
        action: _action('update', 'Подробнее', () => _show('about')),
      );
    }
    if (_scene == 'recovered') {
      return CarpenterNotice(
        title: 'Соединение восстановлено',
        tone: CarpenterNoticeTone.success,
        onClose: () => setState(() => _scene = 'ready'),
      );
    }
    return null;
  }

  Widget _page() => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(_gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterPageHeader(
            title: _dirty ? 'Новый платёж' : _title,
            primaryActions: [
              CarpenterActionDescriptor(
                id: 'create',
                label: 'Создать платёж',
                onInvoke: _scene == 'saving'
                    ? null
                    : () => setState(() {
                        _dirty = true;
                        _scene = 'draft';
                      }),
                icon: GravityIcons.plus,
              ),
            ],
          ),
          SizedBox(height: _gap),
          if (['boot', 'page_loading', 'saving'].contains(_scene))
            const CarpenterProgress(semanticLabel: 'Загрузка'),
          if (_dirty) ...[
            CarpenterInput(
              controller: _draft,
              label: 'Назначение платежа',
              onChanged: (_) => setState(() => _dirty = true),
            ),
            if (_scene == 'save_error')
              const CarpenterNotice(
                title: 'Не удалось сохранить',
                message: 'Введённые данные сохранены в редакторе.',
                tone: CarpenterNoticeTone.danger,
              ),
            SizedBox(height: _gap),
            Wrap(
              spacing: _gap,
              children: [
                CarpenterButton(
                  label: 'Сохранить',
                  onPressed: _scene == 'saving' ? null : _save,
                ),
                CarpenterButton(
                  label: 'Перейти к счетам',
                  onPressed: () => _navigate('accounts'),
                  prominence: ActionProminence.ghost,
                ),
              ],
            ),
          ] else if (['boot', 'page_loading'].contains(_scene))
            const CarpenterText.caption('Загружаем рабочую страницу…')
          else if ([
            'empty',
            'error',
            'forbidden',
            'not_found',
            'no_access',
          ].contains(_scene))
            CarpenterNotice(
              title: switch (_scene) {
                'empty' => 'Платежей пока нет',
                'forbidden' => 'Нет доступа к странице',
                'not_found' => 'Страница не найдена',
                'no_access' => 'Нет доступных разделов',
                _ => 'Не удалось загрузить данные',
              },
              action: _action('retry', 'К разделам', () => _show('modules')),
            )
          else ...[
            for (final entry in [
              ('ООО «Север»', '+ 245 000,00 ₽'),
              ('Электрокомплект', '− 68 425,50 ₽'),
              ('Проектное бюро «Вектор»', '− 32 000,00 ₽'),
            ])
              CarpenterListTile(
                presentation: CarpenterListTilePresentation.collectionRow,
                title: CarpenterText(entry.$1),
                subtitle: const CarpenterText.caption(
                  '12 сентября · оплата по договору',
                ),
                trailing: CarpenterText.label(entry.$2),
              ),
          ],
        ],
      ),
    ),
  );
  void _save() => setState(() {
    _dirty = false;
    _scene = 'ready';
    _selected = _pending ?? _selected;
    _pending = null;
    _dialog = null;
  });
  String get _dialogTitle => _dialog == null
      ? 'Рабочая область'
      : workspaceScenarioLabels[_dialog!] ?? 'Рабочая область';
  List<CarpenterActionDescriptor> get _dialogActions => _dialog == 'leave'
      ? [
          _action('stay', 'Остаться', _close),
          _action(
            'discard',
            'Не сохранять',
            () => setState(() {
              _dirty = false;
              _selected = _pending ?? _selected;
              _dialog = null;
            }),
            role: ActionColorRole.danger,
          ),
          _action(
            'save',
            'Сохранить и перейти',
            _save,
            role: ActionColorRole.primary,
          ),
        ]
      : _dialog == 'logout'
      ? [
          _action('stay', 'Остаться', _close),
          _action(
            'logout',
            'Выйти',
            () => setState(() => _dialog = 'expired'),
            role: ActionColorRole.danger,
          ),
        ]
      : _dialog == 'expired'
      ? [
          _action(
            'login',
            'Войти снова',
            () => setState(() {
              _dialog = null;
              _scene = 'ready';
            }),
          ),
        ]
      : [_action('close', 'Закрыть', _close)];
  Widget _dialogContent() {
    final dialog = _dialog ?? '';
    if (dialog.startsWith('search') ||
        ['modules', 'module_empty', 'mobile_modules'].contains(dialog)) {
      final catalogue = dialog.contains('module');
      final destinations = catalogue
          ? [
              const CarpenterNavigationDestination(
                id: 'finance',
                label: 'Казначейство',
                description: 'Платежи · счета · выписки',
                icon: GravityIcons.creditCard,
              ),
              const CarpenterNavigationDestination(
                id: 'projects',
                label: 'Проекты',
                description: 'Три отдельных контура',
                icon: GravityIcons.folder,
              ),
              const CarpenterNavigationDestination(
                id: 'tasks',
                label: 'Задачи',
                description: 'РСП · планировщик',
                icon: GravityIcons.listCheck,
              ),
              const CarpenterNavigationDestination(
                id: 'messenger',
                label: 'Коммуникации',
                description: 'Чаты · почта · конференции',
                icon: GravityIcons.comment,
              ),
            ]
          : [
              for (final i in _pages)
                CarpenterNavigationDestination(
                  id: i.$1,
                  label: i.$2,
                  description: 'Казначейство',
                  icon: i.$3,
                ),
              const CarpenterNavigationDestination(
                id: 'projects-plus',
                label: 'Проекты+',
                description: 'Отдельный контур проектов',
                icon: GravityIcons.folderOpen,
              ),
            ];
      final q = _query.text.toLowerCase();
      return SizedBox(
        height: context.units(24.rem),
        child: CarpenterNavigationPalette(
          controller: _query,
          destinations: dialog == 'search_loading'
              ? []
              : destinations
                    .where(
                      (d) => '${d.label} ${d.description}'
                          .toLowerCase()
                          .contains(q),
                    )
                    .toList(),
          selectedId: _selected,
          onQueryChanged: (_) => setState(() {}),
          onSelected: (id) {
            if (catalogue && id == 'projects') {
              setState(() {
                _scene = 'projects';
                _selected = 'projects-plus';
                _dialog = null;
              });
            } else {
              _navigate(id == 'finance' ? 'payments' : id);
            }
          },
          loadPhase: dialog == 'search_loading'
              ? CollectionLoadPhase.initialLoading
              : CollectionLoadPhase.ready,
          errorMessage: dialog == 'search_error'
              ? 'Не удалось загрузить переходы'
              : null,
          onRetry: () => setState(() => _dialog = 'search'),
        ),
      );
    }
    if (dialog.startsWith('inbox')) {
      return dialog == 'inbox_loading'
          ? const CarpenterProgress()
          : dialog == 'inbox_empty'
          ? const CarpenterText('Всё просмотрено')
          : dialog == 'inbox_error'
          ? CarpenterNotice(
              title: 'Не удалось загрузить входящие',
              tone: CarpenterNoticeTone.danger,
              action: _action(
                'retry',
                'Повторить',
                () => setState(() => _dialog = 'inbox'),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CarpenterListTile(
                  title: const CarpenterText('Задача № 241 ожидает проверки'),
                  subtitle: const CarpenterText.caption(
                    'На проверке · 10 минут назад',
                  ),
                  onInvoke: () => _navigate('tasks'),
                ),
                CarpenterListTile(
                  title: const CarpenterText('Вас упомянули в проекте'),
                  subtitle: const CarpenterText.caption(
                    'Упоминание · 25 минут назад',
                  ),
                  onInvoke: () => _navigate('messenger'),
                ),
              ],
            );
    }
    if (dialog == 'profile') {
      return CarpenterMenu(
        items: [
          CarpenterMenuItem(
            action: _action(
              'appearance',
              'Оформление',
              () => _show('appearance'),
              icon: GravityIcons.sun,
            ),
          ),
          CarpenterMenuItem(
            action: _action(
              'settings',
              'Настройки',
              () => _navigate('settings'),
              icon: GravityIcons.gear,
            ),
          ),
          CarpenterMenuItem(
            action: _action(
              'about',
              'О приложении',
              () => _show('about'),
              icon: GravityIcons.circleInfo,
            ),
          ),
          CarpenterMenuItem(
            action: _action(
              'logout',
              'Выйти',
              () => _show('logout'),
              icon: GravityIcons.arrowRightFromSquare,
            ),
          ),
        ],
      );
    }
    if (dialog == 'appearance') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarpenterButton(
            label: 'Режим концентрации',
            onPressed: () => setState(() {
              _visible = false;
              _dialog = null;
            }),
          ),
          const CarpenterText.caption(
            'Тема, масштаб и контраст — в общих настройках Widgetbook.',
          ),
        ],
      );
    }
    if (dialog == 'incoming') {
      return CarpenterButton(
        label: 'Ответить на звонок Алексея',
        icon: GravityIcons.handset,
        onPressed: () => setState(() {
          _scene = 'call';
          _dialog = null;
        }),
      );
    }
    return CarpenterText(switch (dialog) {
      'leave' => 'В платеже есть несохранённые изменения.',
      'logout' => 'Выйти из рабочей области Fermat?',
      'expired' => 'Войдите снова, чтобы продолжить работу.',
      'about' =>
        'Okibi · Fermat. Версия приложения находится здесь, а не в хедере.',
      _ => 'Рабочая область',
    });
  }
}
