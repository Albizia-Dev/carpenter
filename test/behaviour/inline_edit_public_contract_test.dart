import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inline edit public contract remains controlled', () {
    const widget = CarpenterInlineTextEdit(
      value: 'Value',
      draft: 'Draft',
      editing: false,
      onEditingChanged: _ignoreBool,
      onDraftChanged: _ignoreString,
      onCommit: _ignore,
      onCancel: _ignore,
    );
    expect(widget.value, 'Value');
    expect(widget.draft, 'Draft');
    expect(widget.editing, isFalse);
  });
}

void _ignore() {}
void _ignoreBool(bool _) {}
void _ignoreString(String _) {}
