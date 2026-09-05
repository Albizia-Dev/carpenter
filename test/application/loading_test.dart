import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loading notifier aggregates operations and start finish are idempotent',
    () async {
      final controller = LoadingNotifier();
      addTearDown(controller.close);

      controller.start('save');
      controller.start('save');
      expect(controller.state.activeCount, 1);
      expect(controller.state.isActive('save'), isTrue);

      controller.start('refresh');
      expect(controller.state.activeCount, 2);

      controller.finish('save');
      controller.finish('save');
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.activeOperations, contains('refresh'));

      controller.finish('refresh');
      expect(controller.state.isLoading, isFalse);
    },
  );

  test(
    'track keeps loading until every concurrent operation finishes',
    () async {
      final controller = LoadingNotifier();
      addTearDown(controller.close);
      final first = Completer<int>();
      final second = Completer<int>();

      final firstResult = controller.track(() => first.future, id: 'first');
      final secondResult = controller.track(() => second.future, id: 'second');
      expect(controller.state.activeCount, 2);

      first.complete(1);
      expect(await firstResult, 1);
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.activeOperations, contains('second'));

      second.complete(2);
      expect(await secondResult, 2);
      expect(controller.state.isLoading, isFalse);
    },
  );

  test('repeated tracked ids keep independent leases', () async {
    final controller = LoadingNotifier();
    addTearDown(controller.close);
    final first = Completer<void>();
    final second = Completer<void>();

    final firstResult = controller.track(() => first.future, id: 'save');
    final secondResult = controller.track(() => second.future, id: 'save');
    expect(controller.state.activeOperations, <Object>{'save'});
    expect(controller.state.activeCount, 2);
    expect(controller.state.countFor('save'), 2);

    first.complete();
    await firstResult;
    expect(controller.state.isActive('save'), isTrue);
    expect(controller.state.activeCount, 1);

    second.complete();
    await secondResult;
    expect(controller.state.isLoading, isFalse);
  });

  test('track clears loading and rethrows operation errors', () async {
    final controller = LoadingNotifier();
    addTearDown(controller.close);

    await expectLater(
      controller.track<int>(() => throw StateError('failed'), id: 'failure'),
      throwsStateError,
    );
    expect(controller.state.isLoading, isFalse);
  });

  test('tracked work may finish after the notifier is closed', () async {
    final controller = LoadingNotifier();
    final operation = Completer<int>();
    final result = controller.track(() => operation.future, id: 'detached');

    await controller.close();
    operation.complete(7);

    expect(await result, 7);
  });

  test(
    'compatibility loading cubit keeps stream and close affordances',
    () async {
      final cubit = LoadingCubit();
      final next = cubit.stream.first;

      cubit.start('legacy');

      expect((await next).isActive('legacy'), isTrue);
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    },
  );

  testWidgets('nearest loading boundary intercepts descendant operations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: LoadingBoundary(
          builder: _outerBuilder,
          child: LoadingBoundary(
            builder: _innerBuilder,
            child: _InnerControls(),
          ),
        ),
      ),
    );

    expect(find.text('outer:0'), findsOneWidget);
    expect(find.text('inner:0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inner-start')));
    await tester.pump();
    expect(find.text('outer:0'), findsOneWidget);
    expect(find.text('inner:1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inner-finish')));
    await tester.pump();
    expect(find.text('outer:0'), findsOneWidget);
    expect(find.text('inner:0'), findsOneWidget);
  });

  testWidgets('missing loading scope degrades to no-op without blocking work', (
    tester,
  ) async {
    const key = Key('no-scope');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(key: key),
      ),
    );

    final context = tester.element(find.byKey(key));
    expect(context.loading.state.isLoading, isFalse);
    expect(
      await context.loading.track(() => Future<int>.value(42), id: 'ignored'),
      42,
    );
    expect(context.loading.state.isLoading, isFalse);
  });
}

Widget _outerBuilder(BuildContext context, LoadingState state, Widget child) =>
    Column(children: [Text('outer:${state.activeCount}'), child]);

Widget _innerBuilder(BuildContext context, LoadingState state, Widget child) =>
    Column(children: [Text('inner:${state.activeCount}'), child]);

final class _InnerControls extends StatelessWidget {
  const _InnerControls();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GestureDetector(
        key: const Key('inner-start'),
        behavior: HitTestBehavior.opaque,
        onTap: () => context.loading.start('inner-operation'),
        child: const SizedBox(width: 60, height: 40),
      ),
      GestureDetector(
        key: const Key('inner-finish'),
        behavior: HitTestBehavior.opaque,
        onTap: () => context.loading.finish('inner-operation'),
        child: const SizedBox(width: 60, height: 40),
      ),
    ],
  );
}
