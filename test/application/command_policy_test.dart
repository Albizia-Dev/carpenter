import 'package:carpenter/application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback controller maps command success and failure without raw copy', () async {
    final feedback = CarpenterCommandFeedbackController(
      failureMessage: (event) => 'Не удалось выполнить действие',
    );
    addTearDown(feedback.dispose);
    final successful = CarpenterCommandController<void>(
      id: 'payment.archive',
      title: 'Archive payment',
      execute: (_) => const CarpenterCommandResult(message: 'Payment archived'),
    );
    final failing = CarpenterCommandController<void>(
      id: 'payment.restore',
      title: 'Restore payment',
      execute: (_) => throw StateError('wire details'),
    );
    addTearDown(successful.dispose);
    addTearDown(failing.dispose);
    final executor = CarpenterCommandExecutor(listeners: [feedback.handle]);

    await executor.execute(successful, null);

    expect(feedback.value?.kind, CarpenterCommandFeedbackKind.success);
    expect(feedback.value?.role, FeedbackColorRole.success);
    expect(feedback.value?.message, 'Payment archived');
    expect(feedback.value?.error, isNull);

    await expectLater(executor.execute(failing, null), throwsStateError);

    expect(feedback.value?.kind, CarpenterCommandFeedbackKind.failure);
    expect(feedback.value?.role, FeedbackColorRole.danger);
    expect(feedback.value?.message, 'Не удалось выполнить действие');
    expect(feedback.value?.error, isA<StateError>());
    expect(feedback.value?.message, isNot(contains('wire details')));
  });

  test('feedback clears when a new command starts and keeps undo on success', () async {
    final feedback = CarpenterCommandFeedbackController();
    addTearDown(feedback.dispose);
    var undone = false;
    final command = CarpenterCommandController<void>(
      id: 'payment.delete',
      title: 'Delete payment',
      execute: (_) => CarpenterCommandResult(
        message: 'Payment deleted',
        undo: () => undone = true,
      ),
    );
    addTearDown(command.dispose);
    final executor = CarpenterCommandExecutor(listeners: [feedback.handle]);

    await executor.execute(command, null);
    expect(feedback.value?.message, 'Payment deleted');

    final undo = feedback.value?.undo;
    expect(undo, isNotNull);
    await undo!();
    expect(undone, isTrue);

    final noMessage = CarpenterCommandController<void>(
      id: 'refresh',
      title: 'Refresh',
    );
    addTearDown(noMessage.dispose);
    await executor.execute(noMessage, null);
    expect(feedback.value, isNull);
  });

  test('invalidation registry runs each matching target once', () async {
    final registry = CarpenterInvalidationRegistry();
    final firstTarget = Object();
    final secondTarget = Object();
    final firstCalls = <Set<String>>[];
    final secondCalls = <Set<String>>[];

    registry.register(
      target: firstTarget,
      scopes: const {'payments', 'balances'},
      handler: firstCalls.add,
    );
    final unregisterSecond = registry.register(
      target: secondTarget,
      scopes: const {'payments'},
      handler: secondCalls.add,
    );

    await registry.invalidate(const {'payments', 'balances'});

    expect(firstCalls, [const {'payments', 'balances'}]);
    expect(secondCalls, [const {'payments'}]);

    unregisterSecond();
    await registry.invalidate(const {'payments'});
    expect(firstCalls, [const {'payments', 'balances'}, const {'payments'}]);
    expect(secondCalls, [const {'payments'}]);
    expect(registry.targetCount, 1);
  });

  test('command success drives feedback and refresh policy together', () async {
    final feedback = CarpenterCommandFeedbackController();
    addTearDown(feedback.dispose);
    final registry = CarpenterInvalidationRegistry();
    final refreshed = <Set<String>>[];
    registry.register(
      target: 'payment-list',
      scopes: const {'payments'},
      handler: refreshed.add,
    );
    final command = CarpenterCommandController<void>(
      id: 'payment.archive',
      title: 'Archive payment',
      effects: const [CarpenterRefreshCommandEffect({'payments'})],
      execute: (_) => const CarpenterCommandResult(
        message: 'Payment archived',
        refreshScopes: {'balances'},
      ),
    );
    addTearDown(command.dispose);
    final executor = CarpenterCommandExecutor(
      listeners: [feedback.handle, registry.handle],
    );

    await executor.execute(command, null);
    await pumpEventQueue();

    expect(feedback.value?.message, 'Payment archived');
    expect(refreshed, [const {'payments'}]);
  });

  test('invalidation failures are isolated and reported per target', () async {
    final failures = <Object>[];
    final completed = <String>[];
    final registry = CarpenterInvalidationRegistry(
      onError: (target, scopes, error, stackTrace) => failures.add(target),
    );
    registry.register(
      target: 'broken',
      scopes: const {'payments'},
      handler: (_) => throw StateError('offline'),
    );
    registry.register(
      target: 'healthy',
      scopes: const {'payments'},
      handler: (_) => completed.add('healthy'),
    );

    await registry.invalidate(const {'payments'});

    expect(failures, ['broken']);
    expect(completed, ['healthy']);
  });
}
