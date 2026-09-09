import 'dart:async';

import 'package:carpenter/carpenter_older.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as widgets show Text;
import 'package:flutter_test/flutter_test.dart';

Finder _findText(String value) => find.byWidgetPredicate(
  (widget) =>
      (widget is widgets.Text &&
          widget is! CarpenterText &&
          widget.data == value) ||
      (widget is EditableText && widget.controller.text == value),
);

const _collectionDescriptor = CarpenterPageDescriptor(
  id: CarpenterPageId('test.collection'),
  title: 'Records',
  kind: CarpenterPageKind.collection,
);

Widget _host(Widget child, {double width = 900}) => CarpenterScope.fromConfig(
  config: const CarpenterConfig(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox(width: width, height: 640, child: child),
    ),
  ),
);

void main() {
  testWidgets('CarpenterHost задаёт semantic color обычному Text', (
    tester,
  ) async {
    Color? inheritedColor;
    await tester.pumpWidget(
      CarpenterHost(
        config: const CarpenterConfig(brightness: Brightness.dark),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              inheritedColor = DefaultTextStyle.of(context).style.color;
              return const CarpenterText('semantic text');
            },
          ),
        ),
      ),
    );

    final runtime = Carpenter.fromConfig(
      const CarpenterConfig(brightness: Brightness.dark),
    );
    expect(inheritedColor, runtime.face.color('text.primary'));
    expect(inheritedColor, isNot(const Color(0xFF000000)));
  });

  testWidgets('CarpenterRecordMetric сохраняет semantic colors в dark theme', (
    tester,
  ) async {
    Color? valueColor;
    Color? descriptionColor;
    const config = CarpenterConfig(brightness: Brightness.dark);
    final runtime = Carpenter.fromConfig(config);

    await tester.pumpWidget(
      CarpenterHost(
        carpenter: runtime,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterRecordMetric(
            label: 'Balance',
            value: Builder(
              builder: (context) {
                valueColor = DefaultTextStyle.of(context).style.color;
                return const CarpenterText('42');
              },
            ),
            description: Builder(
              builder: (context) {
                descriptionColor = DefaultTextStyle.of(context).style.color;
                return const CarpenterText('Today');
              },
            ),
          ),
        ),
      ),
    );

    expect(valueColor, runtime.face.color('text.primary'));
    expect(descriptionColor, runtime.face.color('text.secondary'));
  });

  group('CarpenterPage host', () {
    testWidgets('initial loading replaces the body', (tester) async {
      await tester.pumpWidget(
        _host(
          const CarpenterPage(
            descriptor: _collectionDescriptor,
            state: CarpenterPageInitialLoading(),
            body: CarpenterText('body'),
          ),
        ),
      );

      expect(find.byType(CarpenterLoader), findsOneWidget);
      expect(_findText('body'), findsNothing);
    });

    testWidgets('refreshing preserves body and shows progress', (tester) async {
      await tester.pumpWidget(
        _host(
          const CarpenterPage(
            descriptor: _collectionDescriptor,
            state: CarpenterPageRefreshing(),
            body: CarpenterText('body'),
          ),
        ),
      );

      expect(_findText('body'), findsOneWidget);
      expect(find.byType(CarpenterPageLoadingBar), findsOneWidget);
    });

    testWidgets('failure executes retry command', (tester) async {
      var retries = 0;
      final retry = CarpenterCommandController<void>(
        id: 'retry',
        title: 'Retry',
        execute: (_) {
          retries += 1;
          return const CarpenterCommandResult();
        },
      );
      await tester.pumpWidget(
        _host(
          CarpenterPage(
            descriptor: _collectionDescriptor,
            state: CarpenterPageFailure(
              error: StateError('offline'),
              retryCommand: retry,
            ),
            body: const CarpenterText('body'),
          ),
        ),
      );

      expect(find.textContaining('offline'), findsOneWidget);
      await tester.tap(_findText('Повторить'));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('descriptor permission renders forbidden', (tester) async {
      await tester.pumpWidget(
        _host(
          const CarpenterPage(
            descriptor: CarpenterPageDescriptor(
              id: CarpenterPageId('forbidden'),
              title: 'Secret',
              kind: CarpenterPageKind.record,
              permission: CarpenterPermissionRequirement(
                granted: false,
                reason: 'Missing treasury.read',
              ),
            ),
            body: CarpenterText('secret'),
          ),
        ),
      );

      expect(_findText('Нет доступа'), findsOneWidget);
      expect(_findText('Missing treasury.read'), findsOneWidget);
      expect(_findText('secret'), findsNothing);
    });

    testWidgets('empty and blocking states are standardized', (tester) async {
      await tester.pumpWidget(
        _host(
          const CarpenterPage(
            descriptor: _collectionDescriptor,
            state: CarpenterPageEmpty(
              CarpenterEmptyStateDescriptor(title: 'Nothing here'),
            ),
            body: CarpenterText('body'),
          ),
        ),
      );
      expect(_findText('Nothing here'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const CarpenterPage(
            descriptor: _collectionDescriptor,
            state: CarpenterPageBlocking(message: 'Saving'),
            body: CarpenterText('body'),
          ),
        ),
      );
      expect(_findText('body'), findsOneWidget);
      expect(_findText('Saving'), findsOneWidget);
      expect(find.byType(CarpenterLoader), findsOneWidget);
    });

    testWidgets('scope exposes identity, commands and capabilities', (
      tester,
    ) async {
      final refresh = CarpenterRefreshCapability(refresh: () async {});
      final command = CarpenterCommandController<void>(
        id: 'create',
        title: 'Create',
        execute: (_) => const CarpenterCommandResult(),
      );
      await tester.pumpWidget(
        _host(
          CarpenterPage(
            descriptor: _collectionDescriptor,
            commands: [command],
            capabilities: [refresh],
            body: Builder(
              builder: (context) {
                final page = context.page;
                final found = page.capability<CarpenterRefreshCapability>();
                return CarpenterText(
                  '${page.descriptor.id.value}:'
                  '${page.commands.single.id}:'
                  '${identical(found, refresh)}',
                );
              },
            ),
          ),
        ),
      );

      expect(_findText('test.collection:create:true'), findsOneWidget);
    });
  });

  group('unified commands', () {
    testWidgets('one command works through button and shortcut', (
      tester,
    ) async {
      var calls = 0;
      final command = CarpenterCommandController<void>(
        id: 'save',
        title: 'Save',
        shortcuts: const [SingleActivator(LogicalKeyboardKey.keyS)],
        execute: (_) async {
          calls += 1;
          return const CarpenterCommandResult();
        },
      );
      final binding = CarpenterCommandBinding<void>(
        command: command,
        input: null,
      );
      await tester.pumpWidget(
        _host(
          CarpenterPage(
            descriptor: const CarpenterPageDescriptor(
              id: CarpenterPageId('editor'),
              title: 'Editor',
              kind: CarpenterPageKind.editor,
            ),
            commandBindings: [binding],
            body: Center(
              child: CarpenterCommandButton<void>(
                command: command,
                input: null,
              ),
            ),
          ),
        ),
      );

      await tester.tap(_findText('Save'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('executing command cannot be launched twice', (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      final command = CarpenterCommandController<void>(
        id: 'blocking',
        title: 'Run',
        execute: (_) async {
          calls += 1;
          await pending.future;
          return const CarpenterCommandResult();
        },
      );
      await tester.pumpWidget(
        _host(
          Center(
            child: CarpenterCommandButton<void>(command: command, input: null),
          ),
        ),
      );

      await tester.tap(_findText('Run'));
      await tester.pump();
      expect(command.value.execution, CarpenterCommandExecution.executing);
      expect(calls, 1);
      pending.complete();
      await tester.pump();
    });
  });

  group('collection pattern', () {
    CarpenterDataCollectionControllerBase<String, String, String> controller(
      CarpenterCollectionState<String> state, {
      CarpenterSelectionController<String>? selection,
      Future<CarpenterCollectionState<String>> Function(
        CarpenterCollectionQuery<String, String>,
        CarpenterCollectionState<String>,
      )?
      loadNext,
    }) => CarpenterDataCollectionControllerBase(
      query: const CarpenterCollectionQuery(
        search: '',
        filter: 'all',
        sort: 'name',
      ),
      initialState: state,
      selection: selection,
      loadRequest: (_, _) async => state,
      loadNext: loadNext,
    );

    Widget collection(
      CarpenterDataCollectionController<String, String, String> controller, {
      List<CarpenterDataGroup<String>> Function(List<String>)? groupBy,
    }) => CarpenterCollectionPage<String, String, String>(
      descriptor: _collectionDescriptor,
      collection: CarpenterDataCollection<String, String, String>(
        controller: controller,
        itemIdentity: (item) => item,
        itemBuilder: (_, item, selected) =>
            CarpenterText(selected ? '$item selected' : item),
        groupBy: groupBy,
      ),
      selectionBar: controller.selection == null
          ? null
          : CarpenterSelectionBar(controller: controller.selection!),
    );

    testWidgets('renders loading, empty, filtered empty and items', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          collection(controller(const CarpenterCollectionInitialLoading())),
        ),
      );
      expect(find.byType(CarpenterLoader), findsOneWidget);

      await tester.pumpWidget(
        _host(collection(controller(const CarpenterCollectionEmpty()))),
      );
      expect(_findText('Записей пока нет'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          collection(
            controller(const CarpenterCollectionEmpty(filtered: true)),
          ),
        ),
      );
      expect(
        _findText('По текущим условиям ничего не найдено'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _host(
          collection(
            controller(const CarpenterCollectionReady(items: ['one', 'two'])),
          ),
        ),
      );
      expect(_findText('one'), findsOneWidget);
      expect(_findText('two'), findsOneWidget);
    });

    testWidgets('keeps query and filters pinned while collection scrolls', (
      tester,
    ) async {
      final source = controller(
        CarpenterCollectionReady(
          items: List.generate(60, (index) => 'item $index'),
        ),
      );
      await tester.pumpWidget(
        _host(
          CarpenterCollectionPage<String, String, String>(
            descriptor: _collectionDescriptor,
            dataController: source,
            queryBar: const CarpenterText('Pinned query'),
            filterBar: const CarpenterText('Pinned filters'),
            itemIdentity: (item) => item,
            itemBuilder: (_, item, _) => CarpenterText(item),
          ),
        ),
      );

      final toolbar = find.byType(CarpenterCollectionToolbar);
      final before = tester.getTopLeft(toolbar);
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(toolbar), before);
      expect(_findText('Pinned query'), findsOneWidget);
      expect(_findText('Pinned filters'), findsOneWidget);
    });

    testWidgets('supports grouped rendering and selection bar', (tester) async {
      final selection = CarpenterSelectionController<String>(
        identity: (item) => item,
      );
      final source = controller(
        const CarpenterCollectionReady(items: ['one', 'two']),
        selection: selection,
      );
      await tester.pumpWidget(
        _host(
          collection(
            source,
            groupBy: (items) => [
              CarpenterDataGroup(
                id: 'all',
                header: const CarpenterText('All records'),
                items: items,
              ),
            ],
          ),
        ),
      );

      expect(_findText('All records'), findsOneWidget);
      expect(find.byType(CarpenterExpander), findsOneWidget);
      await tester.longPress(_findText('one'));
      await tester.pump();
      expect(_findText('one selected'), findsOneWidget);
      expect(_findText('Выбрано: 1'), findsOneWidget);

      await tester.tap(_findText('All records'));
      await tester.pumpAndSettle();
      expect(_findText('one selected'), findsNothing);
      expect(_findText('two'), findsNothing);
    });

    testWidgets('loads next page without discarding visible items', (
      tester,
    ) async {
      final source = controller(
        const CarpenterCollectionReady(items: ['one'], hasNextPage: true),
        loadNext: (_, _) async =>
            const CarpenterCollectionReady(items: ['one', 'two']),
      );
      await tester.pumpWidget(_host(collection(source)));

      await tester.tap(_findText('Загрузить ещё'));
      await tester.pumpAndSettle();
      expect(_findText('one'), findsOneWidget);
      expect(_findText('two'), findsOneWidget);
    });

    test('owns cancellation, debounced query and pagination', () async {
      final requests = <CarpenterCollectionLoadRequest>[];
      final completions = <Completer<CarpenterCollectionState<String>>>[];
      final source = CarpenterDataCollectionControllerBase<String, int, String>(
        query: const CarpenterCollectionQuery(
          search: '',
          filter: 1,
          sort: 'name',
        ),
        searchDebounce: Duration.zero,
        loadRequest: (query, request) {
          requests.add(request);
          final completion = Completer<CarpenterCollectionState<String>>();
          completions.add(completion);
          return completion.future;
        },
        queryForSearch: (query, search) => CarpenterCollectionQuery(
          search: search,
          filter: 1,
          sort: query.sort,
        ),
        queryForPage: (query, page) => CarpenterCollectionQuery(
          search: query.search,
          filter: page,
          sort: query.sort,
        ),
      );

      final initial = source.initialize();
      source.updateSearch('bank');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(requests, hasLength(2));
      expect(requests.first.cancellation.isCancelled, isTrue);

      completions[1].complete(
        const CarpenterCollectionReady(items: ['search result']),
      );
      await Future<void>.delayed(Duration.zero);
      completions[0].complete(
        const CarpenterCollectionReady(items: ['stale result']),
      );
      await initial;
      expect(source.value.visibleItems, ['search result']);
      expect(source.query.search, 'bank');

      final paging = source.goToPage(3);
      expect(source.query.filter, 3);
      completions[2].complete(
        const CarpenterCollectionReady(
          items: ['page three'],
          page: 3,
          totalPages: 4,
        ),
      );
      await paging;
      expect(source.value.visibleItems, ['page three']);
      source.dispose();
    });
  });

  test('restoration is namespaced by page identity', () async {
    final store = CarpenterMemoryRestorationStore();
    final first = CarpenterPageRestorationController(
      pageId: const CarpenterPageId('accounts'),
      store: store,
    );
    final second = CarpenterPageRestorationController(
      pageId: const CarpenterPageId('payments'),
      store: store,
    );

    await first.write('query', 'bank');
    await second.write('query', 'invoice');

    expect(await first.read<String>('query'), 'bank');
    expect(await second.read<String>('query'), 'invoice');
  });

  group('record pattern', () {
    testWidgets('composes header, summary, sections and attention', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarpenterRecordPage<String>(
            descriptor: const CarpenterPageDescriptor(
              id: CarpenterPageId('record'),
              title: 'Account',
              kind: CarpenterPageKind.record,
            ),
            header: const CarpenterEntityHeader(
              title: CarpenterText('Main account'),
              statuses: [CarpenterText('Active')],
            ),
            summary: const CarpenterRecordSummary(
              children: [CarpenterText('100 RUB'), CarpenterText('Available')],
            ),
            attention: const CarpenterAttentionBlock(
              title: 'Requires attention',
            ),
            sections: const [
              CarpenterRecordSection(
                id: CarpenterPageSectionId('details'),
                title: 'Details',
                child: CarpenterText('Account number'),
              ),
            ],
          ),
        ),
      );

      expect(_findText('Main account'), findsOneWidget);
      expect(_findText('100 RUB'), findsOneWidget);
      expect(_findText('Requires attention'), findsOneWidget);
      expect(_findText('Details'), findsOneWidget);
      expect(_findText('Account number'), findsOneWidget);
    });

    testWidgets('renders related collection and timeline blocks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarpenterRecordPage<String>(
            descriptor: const CarpenterPageDescriptor(
              id: CarpenterPageId('record.related'),
              title: 'Account',
              kind: CarpenterPageKind.record,
            ),
            related: const [
              CarpenterRelatedCollection(
                title: 'Payments',
                child: CarpenterText('Payment one'),
              ),
            ],
            timeline: CarpenterTimeline(
              items: [
                CarpenterTimelineItem(
                  id: 'created',
                  title: const CarpenterText('Created'),
                  timestamp: DateTime(2026),
                ),
              ],
            ),
          ),
        ),
      );

      expect(_findText('Payments'), findsOneWidget);
      expect(_findText('Payment one'), findsOneWidget);
      expect(_findText('Created'), findsOneWidget);
    });
  });

  group('resource controller', () {
    test('cancels superseded loads and ignores stale results', () async {
      final first = Completer<int>();
      final second = Completer<int>();
      final requests = <CarpenterResourceLoadRequest>[];
      final controller = CarpenterResourceController<int>(
        load: (request) {
          requests.add(request);
          return requests.length == 1 ? first.future : second.future;
        },
      );

      final initial = controller.initialize();
      final refresh = controller.refresh();
      expect(requests.first.cancellation.isCancelled, isTrue);

      first.complete(1);
      await initial;
      expect(controller.data, isNull);

      second.complete(2);
      await refresh;
      expect(controller.data, 2);
      expect(controller.value, isA<CarpenterPageReady>());
      controller.dispose();
    });

    test('exposes a working retry command after failure', () async {
      var attempts = 0;
      final controller = CarpenterResourceController<int>(
        load: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary');
          return 7;
        },
      );

      await controller.initialize();
      final failure = controller.value as CarpenterPageFailure;
      expect(failure.retryCommand, isNotNull);

      await failure.retryCommand!.execute(null);
      expect(controller.data, 7);
      expect(controller.value, isA<CarpenterPageReady>());
      controller.dispose();
    });
  });

  group('editor core', () {
    test('tracks dirty state, validates asynchronously and saves', () async {
      final name = CarpenterFieldBinding<Object?>(
        descriptor: CarpenterFieldDescriptor<Object?>(
          id: const CarpenterFieldId('name'),
          label: 'Name',
          validator: (value) async => value == ''
              ? const CarpenterValidationResult.invalid('Required')
              : const CarpenterValidationResult.valid(),
        ),
        value: '',
      );
      final controller = CarpenterEditorControllerBase<String>(
        mode: CarpenterEditorMode.create,
        fields: [name],
        onSave: (values) async =>
            values[const CarpenterFieldId('name')]! as String,
      );

      expect(await controller.validate(), isFalse);
      expect(controller.value, isA<CarpenterEditorValidationFailure>());

      name.value = 'Current';
      expect(controller.value, isA<CarpenterEditorReady>());
      expect((controller.value as CarpenterEditorReady).dirty, isTrue);
      expect(await controller.save(), 'Current');
      expect(controller.value, isA<CarpenterEditorSaved>());
      controller.dispose();
      name.dispose();
    });

    testWidgets('editor page maps saving to blocking page state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarpenterEditorPage<String>(
            descriptor: CarpenterPageDescriptor(
              id: CarpenterPageId('editor'),
              title: 'Edit',
              kind: CarpenterPageKind.editor,
            ),
            editorState: CarpenterEditorSaving(),
            body: CarpenterText('form'),
          ),
        ),
      );
      expect(_findText('form'), findsOneWidget);
      expect(_findText('Сохранение…'), findsOneWidget);
    });
  });

  testWidgets('workflow executes available transition and completes', (
    tester,
  ) async {
    final transition = CarpenterWorkflowTransition<int, List<String>>(
      id: const CarpenterWorkflowTransitionId('next'),
      title: 'Next',
      canExecute: (state, _) => state == 0,
      execute: (events) async => events.add('executed'),
    );
    final events = <String>[];
    final controller = CarpenterWorkflowControllerBase<int, List<String>>(
      initialState: 0,
      context: events,
      transitions: (state, _) => state == 0 ? [transition] : const [],
      reduce: (_, _) => 1,
    );
    await tester.pumpWidget(
      _host(
        CarpenterWorkflowPage<int, List<String>>(
          descriptor: const CarpenterPageDescriptor(
            id: CarpenterPageId('workflow'),
            title: 'Import',
            kind: CarpenterPageKind.workflow,
          ),
          controller: controller,
          stages: [
            CarpenterDomainWorkflowStage(
              id: 'state',
              title: 'State',
              when: (state, context) => true,
              block: (_, state, _) => CarpenterText('State $state'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(_findText('Next'));
    await tester.pumpAndSettle();
    expect(events, ['executed']);
    expect(_findText('State 1'), findsOneWidget);
    expect(controller.completed, isTrue);
    controller.dispose();
  });

  test(
    'delegate workflow exposes domain state, retry and cancellation',
    () async {
      var state = 0;
      var attempts = 0;
      var cancelled = false;
      late final CarpenterWorkflowTransition<int, Object?> transition;
      transition = CarpenterWorkflowTransition(
        id: const CarpenterWorkflowTransitionId('commit'),
        title: 'Commit',
        canExecute: (state, context) => state == 0,
        execute: (context) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary');
          state = 1;
        },
      );
      final controller = CarpenterWorkflowDelegateController<int, Object?>(
        readState: () => state,
        context: null,
        transitions: (state, context) => state == 0 ? [transition] : const [],
        isCompleted: (state, context) => state == 1,
        onCancel: () async => cancelled = true,
      );

      await controller.transition(transition);
      expect(controller.error, isA<StateError>());
      expect(state, 0);

      await controller.retry();
      expect(controller.error, isNull);
      expect(controller.completed, isTrue);
      expect(state, 1);

      await controller.cancel();
      expect(cancelled, isTrue);
      controller.dispose();
    },
  );

  group('layouts', () {
    testWidgets('tabs lazily render selected content', (tester) async {
      var selected = 'one';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => CarpenterTabsLayout<String>(
              value: selected,
              orientation: CarpenterTabsOrientation.horizontal,
              tabs: const [
                CarpenterLayoutTab(
                  value: 'one',
                  label: 'One',
                  builder: _firstTab,
                ),
                CarpenterLayoutTab(
                  value: 'two',
                  label: 'Two',
                  builder: _secondTab,
                ),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );

      expect(_findText('First content'), findsOneWidget);
      expect(_findText('Second content'), findsNothing);
      await tester.tap(_findText('Two'));
      await tester.pump();
      expect(_findText('Second content'), findsOneWidget);
    });

    testWidgets('adaptive split selects one region on narrow screens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarpenterAdaptiveSplitLayout(
            primary: CarpenterText('Primary'),
            secondary: CarpenterText('Secondary'),
            narrowRegion: CarpenterSplitNarrowRegion.secondary,
          ),
          width: 500,
        ),
      );
      expect(_findText('Primary'), findsNothing);
      expect(_findText('Secondary'), findsOneWidget);
    });
  });
}

Widget _firstTab(BuildContext context) => const CarpenterText('First content');

Widget _secondTab(BuildContext context) =>
    const CarpenterText('Second content');
