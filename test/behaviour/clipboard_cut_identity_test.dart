import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cut keys are presentation state until paste succeeds', () {
    final clipboard = CarpenterClipboardController<String>();
    clipboard.cut(const ['a', 'b']);
    expect(clipboard.cutKeys((value) => value), {'a', 'b'});
    expect(clipboard.value!.isCut, isTrue);
  });
}
