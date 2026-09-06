import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resource controller cancels and ignores stale requests', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    CarpenterResourceCancellation? firstCancellation;
    var invocation = 0;
    final controller = CarpenterResourceController<int>(
      load: (request) {
        invocation += 1;
        if (invocation == 1) {
          firstCancellation = request.cancellation;
          return first.future;
        }
        return second.future;
      },
    );
    addTearDown(controller.dispose);

    final initial = controller.initialize();
    final refresh = controller.refresh();

    expect(firstCancellation?.isCancelled, isTrue);

    second.complete(2);
    await refresh;
    first.complete(1);
    await initial;

    expect(controller.data, 2);
    expect(controller.value, isA<CarpenterPageReady>());
  });

  test('resource data replacement preserves state and notifies once', () async {
    final controller = CarpenterResourceController<int>(load: (_) async => 1);
    addTearDown(controller.dispose);
    await controller.initialize();

    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.replaceData(2);

    expect(controller.data, 2);
    expect(controller.hasData, isTrue);
    expect(controller.value, isA<CarpenterPageReady>());
    expect(notifications, 1);
  });

  test(
    'resource data update uses latest value and requires loaded data',
    () async {
      final controller = CarpenterResourceController<int>(load: (_) async => 4);
      addTearDown(controller.dispose);

      expect(
        () => controller.updateData((current) => current + 1),
        throwsStateError,
      );

      await controller.initialize();
      controller.updateData((current) => current + 3);

      expect(controller.data, 7);
      expect(controller.value, isA<CarpenterPageReady>());
    },
  );

  test(
    'resource controller supports application-specific subclasses',
    () async {
      final controller = _TestResourceController();
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.data, 11);
      expect(controller.value, isA<CarpenterPageReady>());
    },
  );

  test(
    'refresh failure preserves loaded resource and exposes failure',
    () async {
      var invocation = 0;
      final controller = CarpenterResourceController<int>(
        load: (_) async {
          invocation += 1;
          if (invocation == 1) return 5;
          throw StateError('offline');
        },
        errorMessage: (_) => 'Retry later',
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refresh();

      expect(controller.data, 5);
      expect(controller.value, isA<CarpenterPageReady>());
      expect(controller.hasRefreshFailure, isTrue);
      expect(controller.refreshFailure?.error, isA<StateError>());
      expect(controller.refreshFailure?.message, 'Retry later');
    },
  );

  test(
    'refresh command reports failure while preserving loaded resource',
    () async {
      var invocation = 0;
      final controller = CarpenterResourceController<int>(
        load: (_) async {
          invocation += 1;
          if (invocation == 1) return 8;
          throw StateError('offline');
        },
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      await expectLater(
        controller.refreshCommand.execute(null),
        throwsA(isA<StateError>()),
      );

      expect(controller.data, 8);
      expect(controller.value, isA<CarpenterPageReady>());
      expect(controller.hasRefreshFailure, isTrue);
      expect(
        controller.refreshCommand.value.execution,
        CarpenterCommandExecution.failed,
      );
    },
  );

  test('successful refresh clears an earlier refresh failure', () async {
    var invocation = 0;
    final controller = CarpenterResourceController<int>(
      load: (_) async {
        invocation += 1;
        if (invocation == 1) return 1;
        if (invocation == 2) throw StateError('offline');
        return 3;
      },
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.refresh();
    expect(controller.hasRefreshFailure, isTrue);

    await controller.refresh();

    expect(controller.data, 3);
    expect(controller.refreshFailure, isNull);
    expect(controller.value, isA<CarpenterPageReady>());
  });

  test('initial resource failure remains blocking', () async {
    final controller = CarpenterResourceController<int>(
      load: (_) async => throw StateError('offline'),
      errorMessage: (_) => 'Cannot load resource',
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.data, isNull);
    expect(controller.refreshFailure, isNull);
    expect(controller.value, isA<CarpenterPageFailure>());
    expect(
      (controller.value as CarpenterPageFailure).message,
      'Cannot load resource',
    );
  });

  test('retry command reports blocking initial-load failure', () async {
    final controller = CarpenterResourceController<int>(
      load: (_) async => throw StateError('offline'),
      errorMessage: (_) => 'Cannot load resource',
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    await expectLater(
      controller.retryCommand.execute(null),
      throwsA(isA<StateError>()),
    );

    expect(controller.data, isNull);
    expect(controller.value, isA<CarpenterPageFailure>());
    expect(
      controller.retryCommand.value.execution,
      CarpenterCommandExecution.failed,
    );
  });

  test('data change hook observes request and local data changes', () async {
    var next = 1;
    final controller = _ObservedResourceController(() async => next);
    addTearDown(controller.dispose);

    await controller.initialize();
    controller.replaceData(2);
    controller.updateData((current) => current + 1);
    next = 4;
    await controller.refresh();

    expect(controller.changes, ['null->1', '1->2', '2->3', '3->4']);
  });
}

final class _TestResourceController extends CarpenterResourceController<int> {
  _TestResourceController() : super(load: (_) async => 11);
}

final class _ObservedResourceController
    extends CarpenterResourceController<int> {
  _ObservedResourceController(Future<int> Function() load)
    : super(load: (_) => load());

  final List<String> changes = [];

  @override
  void didChangeData(int? previous, int next) {
    changes.add('$previous->$next');
  }
}
