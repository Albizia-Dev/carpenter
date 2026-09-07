import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('undoable operation may expose an explicit redo', () {
    var value = 1;
    final operation = CarpenterUndoableOperation(
      label: 'Change',
      undo: () => value = 0,
      redo: () => value = 1,
    );
    expect(operation.redo, isNotNull);
    operation.undo();
    expect(value, 0);
    operation.redo!();
    expect(value, 1);
  });
}
