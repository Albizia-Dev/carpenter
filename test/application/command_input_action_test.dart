import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final outcome in ['accept', 'cancel', 'unmount', 'disable', 'fail']) {
    testWidgets('input action: $outcome', (tester) async {
      final input = Completer<int?>();
      final received = <int>[];
      final events = <CarpenterCommandExecutionEvent>[];
      final command = CarpenterCommandController<int>(
        id: 'save',
        title: 'Save',
        execute: (value) {
          received.add(value);
          if (outcome == 'fail') throw StateError('offline');
          return const CarpenterCommandResult();
        },
      );
      addTearDown(command.dispose);
      late CarpenterActionDescriptor action;
      var collections = 0;
      await tester.pumpWidget(
        CarpenterCommandExecutionScope(
          executor: CarpenterCommandExecutor(listeners: [events.add]),
          child: Builder(
            builder: (context) {
              action = command.toInputAction(
                context,
                inputBuilder: (_) {
                  collections++;
                  return input.future;
                },
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      action.onInvoke!();
      action.onInvoke!();
      expect(collections, 1);
      if (outcome == 'unmount')
        await tester.pumpWidget(const SizedBox.shrink());
      if (outcome == 'disable') command.setAvailability(enabled: false);
      input.complete(outcome == 'cancel' ? null : 42);
      await tester.pump();
      expect(
        received,
        outcome == 'accept' || outcome == 'fail' ? [42] : isEmpty,
      );
      expect(
        events.whereType<CarpenterCommandSucceeded>().length,
        outcome == 'accept' ? 1 : 0,
      );
      expect(
        events.whereType<CarpenterCommandFailed>().length,
        outcome == 'fail' ? 1 : 0,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
