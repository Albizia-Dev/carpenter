import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typed clipboard preserves copy/cut meaning and stable cut keys', () {
    final clipboard = CarpenterClipboardController<_Item>();
    addTearDown(clipboard.dispose);
    const first = _Item('a');
    const refreshedFirst = _Item('a');
    const second = _Item('b');

    clipboard.copy(const [first, second], sourceId: 'general');
    expect(clipboard.value?.isCopy, isTrue);
    expect(clipboard.value?.sourceId, 'general');
    expect(clipboard.isCutItem(refreshedFirst, (item) => item.id), isFalse);

    clipboard.cut(const [first, second], sourceId: 'stage-p');
    expect(clipboard.value?.isCut, isTrue);
    expect(clipboard.isCutItem(refreshedFirst, (item) => item.id), isTrue);
    expect(clipboard.cutKeys((item) => item.id), {'a', 'b'});

    clipboard.clear();
    expect(clipboard.hasContent, isFalse);
  });

  test(
    'cut paste clears only after success while failed paste stays retryable',
    () async {
      final clipboard = CarpenterClipboardController<String>();
      addTearDown(clipboard.dispose);
      var selection = <String>['a'];
      var failPaste = true;
      CarpenterClipboardContent<String>? pasted;
      final commands = CarpenterClipboardCommandSet<String>(
        clipboard: clipboard,
        selectedItems: () => selection,
        sourceId: () => 'source-folder',
        onPaste: (content) {
          pasted = content;
          if (failPaste) throw StateError('offline');
          return const CarpenterCommandResult();
        },
      );
      addTearDown(commands.dispose);

      await commands.cut.execute(null);
      expect(clipboard.value?.isCut, isTrue);
      expect(commands.paste.value.enabled, isTrue);

      await expectLater(commands.paste.execute(null), throwsStateError);
      expect(clipboard.value?.isCut, isTrue);
      expect(pasted?.sourceId, 'source-folder');

      failPaste = false;
      await commands.paste.execute(null);
      expect(clipboard.value, isNull);
      expect(commands.paste.value.enabled, isFalse);

      selection = [];
      commands.refreshAvailability();
      expect(commands.copy.value.enabled, isFalse);
      expect(commands.cut.value.enabled, isFalse);
    },
  );

  test('copy paste remains reusable', () async {
    final clipboard = CarpenterClipboardController<String>();
    addTearDown(clipboard.dispose);
    var pasteCount = 0;
    final commands = CarpenterClipboardCommandSet<String>(
      clipboard: clipboard,
      selectedItems: () => const ['a'],
      onPaste: (_) {
        pasteCount += 1;
        return const CarpenterCommandResult();
      },
    );
    addTearDown(commands.dispose);

    await commands.copy.execute(null);
    await commands.paste.execute(null);
    await commands.paste.execute(null);

    expect(pasteCount, 2);
    expect(clipboard.value?.isCopy, isTrue);
  });

  test('undo and redo move reversible operations between histories', () async {
    final controller = CarpenterUndoController();
    addTearDown(controller.dispose);
    var value = 1;
    controller.register(
      CarpenterUndoableOperation(
        label: 'Change value',
        undo: () => value = 0,
        redo: () => value = 1,
      ),
    );

    expect(controller.canUndo, isTrue);
    expect(controller.value.nextUndo?.label, 'Change value');
    expect(await controller.undo(), isTrue);
    expect(value, 0);
    expect(controller.canRedo, isTrue);

    expect(await controller.redo(), isTrue);
    expect(value, 1);
    expect(controller.canUndo, isTrue);
  });

  test('failed undo keeps history intact', () async {
    final controller = CarpenterUndoController();
    addTearDown(controller.dispose);
    controller.register(
      CarpenterUndoableOperation(
        label: 'Fragile change',
        undo: () => throw StateError('conflict'),
        redo: () {},
      ),
    );

    await expectLater(controller.undo(), throwsStateError);
    expect(controller.value.undoStack.single.label, 'Fragile change');
    expect(controller.value.redoStack, isEmpty);
    expect(controller.value.error, isA<StateError>());
    expect(controller.canUndo, isTrue);
  });
}

final class _Item {
  const _Item(this.id);
  final String id;
}
