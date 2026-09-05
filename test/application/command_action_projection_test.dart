import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command projects into a semantic action and preserves input', () async {
    int? received;
    final command = CarpenterCommandController<int>(
      id: 'save',
      title: 'Save',
      presentation: CarpenterCommandPresentation.primary,
      execute: (input) {
        received = input;
        return const CarpenterCommandResult();
      },
    );
    addTearDown(command.dispose);

    final action = command.toAction(42);
    expect(action.id, 'save');
    expect(action.label, 'Save');
    expect(action.colorRole, ActionColorRole.primary);
    expect(action.isEnabled, isTrue);

    action.onInvoke!.call();
    await pumpEventQueue();
    expect(received, 42);
  });

  test('command projection reflects current availability', () {
    final command = CarpenterCommandController<int>(
      id: 'archive',
      title: 'Archive',
      presentation: CarpenterCommandPresentation.danger,
    );
    addTearDown(command.dispose);

    expect(command.toAction(1).colorRole, ActionColorRole.danger);
    expect(command.toAction(1).isEnabled, isTrue);

    command.setAvailability(enabled: false, disabledReason: 'Not allowed');
    expect(command.toAction(1).isEnabled, isFalse);
  });
}
