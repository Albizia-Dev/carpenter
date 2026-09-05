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
    expect(action.visible, isTrue);
    expect(action.isEnabled, isTrue);

    action.onInvoke!.call();
    await pumpEventQueue();
    expect(received, 42);
  });

  test('command projection reflects current availability and visibility', () {
    final command = CarpenterCommandController<int>(
      id: 'archive',
      title: 'Archive',
      presentation: CarpenterCommandPresentation.danger,
    );
    addTearDown(command.dispose);

    expect(command.toAction(1).colorRole, ActionColorRole.danger);
    expect(command.toAction(1).isEnabled, isTrue);
    expect(command.toAction(1).visible, isTrue);

    command.setAvailability(enabled: false, disabledReason: 'Not allowed');
    final disabled = command.toAction(1);
    expect(disabled.isEnabled, isFalse);
    expect(disabled.visible, isTrue);
    expect(disabled.disabledReason, 'Not allowed');

    command.setAvailability(
      visibility: CarpenterCommandVisibility.hidden,
      enabled: false,
      disabledReason: 'No matching context',
    );
    final hidden = command.toAction(1);
    expect(hidden.visible, isFalse);
    expect(hidden.isEnabled, isFalse);
    expect(hidden.disabledReason, 'No matching context');
  });
}
