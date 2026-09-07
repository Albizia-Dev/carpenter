import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standard clipboard command set exposes copy cut paste', () {
    final clipboard = CarpenterClipboardController<String>();
    final commands = CarpenterClipboardCommandSet<String>(
      clipboard: clipboard,
      selectedItems: () => const ['a'],
      onPaste: (_) => const CarpenterCommandResult(),
    );
    expect(commands.commands.map((command) => command.id), [
      'clipboard.copy',
      'clipboard.cut',
      'clipboard.paste',
    ]);
    commands.dispose();
  });
}
