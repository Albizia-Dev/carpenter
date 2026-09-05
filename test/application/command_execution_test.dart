import 'package:carpenter/carpenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('executor emits semantic lifecycle and combines refresh scopes', () async {
    final events = <CarpenterCommandExecutionEvent>[];
    final command = CarpenterCommandController<int>(
      id: 'payment.archive',
      title: 'Archive payment',
      group: 'Payments',
      effects: const [
        CarpenterRefreshCommandEffect({'payments'}),
        CarpenterBlockingCommandEffect(),
      ],
      execute: (input) => CarpenterCommandResult(
        message: 'Archived $input',
        refreshScopes: const {'balances'},
      ),
    );
    addTearDown(command.dispose);
    final executor = CarpenterCommandExecutor(listeners: [events.add]);

    final result = await executor.execute(command, 42);

    expect(result.message, 'Archived 42');
    expect(events, hasLength(2));
    expect(events.first, isA<CarpenterCommandStarted>());
    expect(events.first.isBlocking, isTrue);

    final succeeded = events.last as CarpenterCommandSucceeded;
    expect(succeeded.message, 'Archived 42');
    expect(succeeded.refreshScopes, {'payments', 'balances'});
    expect(succeeded.isBlocking, isTrue);
  });

  test('executor emits failure and preserves command failure state', () async {
    final events = <CarpenterCommandExecutionEvent>[];
    final command = CarpenterCommandController<void>(
      id: 'payment.restore',
      title: 'Restore payment',
      execute: (_) => throw StateError('network'),
    );
    addTearDown(command.dispose);
    final executor = CarpenterCommandExecutor(listeners: [events.add]);

    await expectLater(executor.execute(command, null), throwsStateError);

    expect(events, hasLength(2));
    final failed = events.last as CarpenterCommandFailed;
    expect(failed.error, isA<StateError>());
    expect(command.state.value.execution, CarpenterCommandExecution.failed);
    expect(command.state.value.error, isA<StateError>());
  });

  test('listener failure never changes a successful command outcome', () async {
    final reported = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    final received = <CarpenterCommandExecutionEvent>[];
    final command = CarpenterCommandController<void>(
      id: 'save',
      title: 'Save',
      execute: (_) => const CarpenterCommandResult(message: 'Saved'),
    );
    addTearDown(command.dispose);
    final executor = CarpenterCommandExecutor(
      listeners: [
        (_) => throw StateError('broken listener'),
        received.add,
      ],
    );

    final result = await executor.execute(command, null);

    expect(result.message, 'Saved');
    expect(command.state.value.execution, CarpenterCommandExecution.idle);
    expect(received, hasLength(2));
    expect(reported, hasLength(2));
    expect(reported.first.exception, isA<StateError>());
  });

  testWidgets('command button uses the nearest execution scope', (tester) async {
    final events = <CarpenterCommandExecutionEvent>[];
    final command = CarpenterCommandController<void>(
      id: 'save',
      title: 'Save',
      execute: (_) => const CarpenterCommandResult(message: 'Saved'),
    );
    addTearDown(command.dispose);

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterCommandExecutionScope(
          executor: CarpenterCommandExecutor(listeners: [events.add]),
          child: CarpenterCommandButton(command: command, input: null),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(events.whereType<CarpenterCommandStarted>(), hasLength(1));
    expect(events.whereType<CarpenterCommandSucceeded>(), hasLength(1));
  });
}
